// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:salespulse/models/profil_model.dart';
import 'package:salespulse/models/vente_model_pro.dart';
import 'package:salespulse/models/client_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/client_api.dart';
import 'package:salespulse/services/profil_api.dart';
import 'package:salespulse/services/reglement_api.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class HistoriqueVentesScreen extends StatefulWidget {
  const HistoriqueVentesScreen({super.key});

  @override
  State<HistoriqueVentesScreen> createState() => _HistoriqueVentesScreenState();
}

class _HistoriqueVentesScreenState extends State<HistoriqueVentesScreen> {
  List<VenteModel> ventes = [];
  List<VenteModel> filteredVentes = [];
  List<ClientModel> clients = [];
  bool isLoading = true;
  String errorMessage = '';

  String searchQuery = "";
  DateTime? dateDebut;
  DateTime? dateFin;
  String? selectedClientId;
  String? selectedStatut;

  final ServicesVentes api = ServicesVentes();
  final ServicesClients _clientApi = ServicesClients();

  // Détection du type d'appareil
  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool get isTablet =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;
  bool get isDesktop => MediaQuery.of(context).size.width >= 1024;

  @override
  void initState() {
    super.initState();
    fetchClients();
    fetchVentes();
  }

  Future<void> fetchClients() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await _clientApi.getClients(token);
      if (!context.mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          clients = (res.data["clients"] as List)
              .map((e) => ClientModel.fromJson(e))
              .toList();
        });
      }
    } on DioException catch (e) {
      if (!context.mounted) return;
      handleDioError(e);
    } on TimeoutException {
      if (!context.mounted) return;
      showSnackBar("Le serveur ne répond pas. Veuillez réessayer plus tard.");
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar("Erreur: ${e.toString()}");
      debugPrint(e.toString());
    }
  }

  Future<void> fetchVentes() async {
    setState(() => isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await api.getAllVentes(
        token,
        clientId: selectedClientId,
        dateDebut: dateDebut != null
            ? DateFormat('yyyy-MM-dd').format(dateDebut!)
            : null,
        dateFin:
            dateFin != null ? DateFormat('yyyy-MM-dd').format(dateFin!) : null,
      );

      if (res.statusCode == 200) {
        final data = res.data;
        setState(() {
          ventes = (data["ventes"] as List)
              .map((e) => VenteModel.fromJson(e))
              .toList();
          applyFilters();
          isLoading = false;
        });
      }
    } on DioException catch (e) {
      handleDioError(e);
      setState(() => isLoading = false);
    } on TimeoutException {
      showSnackBar("Le serveur ne répond pas. Veuillez réessayer plus tard.");
      setState(() => isLoading = false);
    } catch (e) {
      showSnackBar("Erreur: ${e.toString()}");
      debugPrint(e.toString());
      setState(() => isLoading = false);
    }
  }

  void handleDioError(DioException e) {
    if (e.response != null && e.response?.statusCode == 403) {
      final errorMessage = e.response?.data['error'] ?? '';
      if (errorMessage.toString().contains("abonnement")) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Abonnement expiré"),
            content: const Text(
                "Votre abonnement a expiré. Veuillez le renouveler."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AbonnementScreen()),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }
    }
    showSnackBar("Problème de connexion : Vérifiez votre Internet.");
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  void applyFilters() {
    setState(() {
      filteredVentes = ventes.where((vente) {
        final matchSearch =
            vente.statut.toLowerCase().contains(searchQuery.toLowerCase()) ||
                (vente.clientNom
                        ?.toLowerCase()
                        .contains(searchQuery.toLowerCase()) ??
                    false);
        final matchStatut =
            selectedStatut == null || vente.statut == selectedStatut;
        return matchSearch && matchStatut;
      }).toList();
    });
  }

  void resetFilters() {
    setState(() {
      dateDebut = null;
      dateFin = null;
      selectedClientId = null;
      searchQuery = "";
      selectedStatut = null;
    });
    fetchVentes();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutButton();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!authProvider.isAuthenticated && mounted) {
        await _handleLogout(context);
      }
    });

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        automaticallyImplyLeading: false,
        title: Text(
          "Historique des ventes",
          style: GoogleFonts.roboto(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              onPressed: _generatePdf,
            ),
          if (!isMobile)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: resetFilters,
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.orange, size: 50))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/erreur.png",
                        width: isMobile ? 200 : 300,
                        height: isMobile ? 200 : 300,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                )
              : ventes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            "assets/images/not_data.png",
                            width: isMobile ? 200 : 300,
                            height: isMobile ? 200 : 300,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Aucune donnée disponible",
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildAdaptiveBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () =>
            _generateRapportPdfPro(filteredVentes, dateDebut, dateFin),
        tooltip: "Générer le rapport PDF",
        child: const Icon(Icons.bar_chart_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildAdaptiveBody() {
    return Column(
      children: [
        // Zone de filtres
        _buildFilterSection(),
        const SizedBox(height: 8),

        // Liste des ventes
        Expanded(
          child: isMobile ? _buildMobileList() : _buildDesktopTable(),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      child: Column(
        children: [
          if (isMobile) _buildMobileSearch(),
          if (!isMobile) _buildDesktopSearch(),
          const SizedBox(height: 8),
          _buildDateFilters(),
          if (isMobile) _buildMobileActions(),
        ],
      ),
    );
  }

  Widget _buildMobileSearch() {
    return TextField(
      style: GoogleFonts.roboto(fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        hintText: "Rechercher...",
        hintStyle: GoogleFonts.roboto(fontSize: 14),
        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.blueGrey),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onChanged: (val) {
        searchQuery = val;
        applyFilters();
      },
    );
  }

  Widget _buildDesktopSearch() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: GoogleFonts.roboto(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[200],
              hintText: "Rechercher par client ou statut...",
              hintStyle: GoogleFonts.roboto(fontSize: 14),
              prefixIcon:
                  const Icon(Icons.search, size: 20, color: Colors.blueGrey),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onChanged: (val) {
              searchQuery = val;
              applyFilters();
            },
          ),
        ),
        const SizedBox(width: 8),
        _buildClientFilter(),
        const SizedBox(width: 8),
        _buildStatutFilter(),
      ],
    );
  }

  Widget _buildDateFilters() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(0, 40),
            ),
            icon:
                const Icon(Icons.calendar_today, size: 16, color: Colors.white),
            label: Text(
              dateDebut != null
                  ? DateFormat('dd/MM/yyyy').format(dateDebut!)
                  : "Date début",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => dateDebut = picked);
                fetchVentes();
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(0, 40),
            ),
            icon:
                const Icon(Icons.calendar_today, size: 16, color: Colors.white),
            label: Text(
              dateFin != null
                  ? DateFormat('dd/MM/yyyy').format(dateFin!)
                  : "Date fin",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
            ),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => dateFin = picked);
                fetchVentes();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildClientFilter() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedClientId,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Tous les clients",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: GoogleFonts.roboto(color: Colors.black, fontSize: 14),
          items: [
            DropdownMenuItem(
              value: null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "Tous les clients",
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
              ),
            ),
            ...clients.map((client) {
              return DropdownMenuItem(
                value: client.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    client.nom,
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                ),
              );
            })
          ],
          onChanged: (val) {
            setState(() => selectedClientId = val);
            fetchVentes();
          },
        ),
      ),
    );
  }

  Widget _buildStatutFilter() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatut,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "Tous les statuts",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black87),
            ),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
          style: GoogleFonts.roboto(color: Colors.black, fontSize: 14),
          items: [
            DropdownMenuItem(
              value: null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  "Tous les statuts",
                  style: GoogleFonts.roboto(fontSize: 14),
                ),
              ),
            ),
            ...["payée", "crédit", "partiel"].map((statut) {
              return DropdownMenuItem(
                value: statut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    statut[0].toUpperCase() + statut.substring(1),
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                ),
              );
            })
          ],
          onChanged: (val) {
            setState(() => selectedStatut = val);
            applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildMobileActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.print, color: Colors.blue),
          onPressed: _generatePdf,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.blueGrey),
          onPressed: resetFilters,
          tooltip: "Réinitialiser les filtres",
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredVentes.length,
      itemBuilder: (context, index) {
        final vente = filteredVentes[index];
        return Card(
          color: Colors.white,
          elevation: 0.01,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: InkWell(
            onTap: () => _showProduitsDialog(vente),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Date + Statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(vente.date),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(vente.statut),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vente.statut,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// Client
                  Text(
                    "Client: ${vente.clientNom}",
                    style: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  /// Total
                  Text(
                    "Total: ${vente.total} Fcfa",
                    style: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 8),

                  /// Paiement + reste
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          "Paiement: ${vente.typePaiement}",
                          style: GoogleFonts.roboto(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vente.reste > 0)
                        Text(
                          "Reste: ${vente.reste} Fcfa",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (vente.monnaie > 0)
                        Text(
                          "Monnaie: ${vente.monnaie} Fcfa",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  /// Boutons impression et règlement
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print,
                              size: 20, color: Colors.blue),
                          onPressed: () => generateFacturePdf(vente),
                        ),
                        if (vente.reste > 0)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 30),
                              backgroundColor: Colors.blueAccent,
                            ),
                            child: Text(
                              'Règlement',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () => _ouvrirDialogReglement(
                              context,
                              vente,
                              "règlement",
                            ),
                          ),
                        if (vente.monnaie > 0)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 30),
                              backgroundColor: Colors.blueAccent,
                            ),
                            child: Text(
                              'Remboursement',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () => _ouvrirDialogReglement(
                              context,
                              vente,
                              "remboursement",
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              padding: const EdgeInsets.all(8.0),
              child: DataTable(
                columnSpacing: 20,
                horizontalMargin: 16,
                headingRowHeight: 50,
                dataRowHeight: 50,
                headingRowColor: MaterialStateProperty.all(Colors.blueGrey),
                headingTextStyle: GoogleFonts.roboto(
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                columns: [
                  DataColumn(
                      label: Text(
                    "Date".toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 12),
                  )),
                  DataColumn(
                      label: Text("Client".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12))),
                  DataColumn(
                      label: Text("Total".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12)),
                      numeric: true),
                  DataColumn(
                      label: Text("Montant payé".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12)),
                      numeric: true),
                  DataColumn(
                      label: Text("Paiement".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12))),
                  DataColumn(
                      label: Text("Statut".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12))),
                  if (isDesktop)
                    DataColumn(
                        label: Text("Reste".toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 12)),
                        numeric: true),
                  if (isDesktop)
                    DataColumn(
                        label: Text("Monnaie".toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 12)),
                        numeric: true),
                  DataColumn(
                      label: Text("Actions".toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 12))),
                ],
                rows: filteredVentes.map((vente) {
                  return DataRow(
                    cells: [
                      DataCell(Text(
                        DateFormat('dd/MM/yyyy').format(vente.date),
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(Text(
                        vente.clientNom ?? "Occasionnel",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(Text(
                        "${vente.total}",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(Text(
                        "${vente.montantRecu}",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(Text(
                        vente.typePaiement,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(vente.statut),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vente.statut,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      if (isDesktop)
                        DataCell(Text(
                          vente.reste > 0 ? "${vente.reste}" : "-",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vente.reste > 0 ? Colors.red : Colors.grey,
                          ),
                        )),
                      if (isDesktop)
                        DataCell(Text(
                          vente.monnaie > 0 ? "${vente.monnaie}" : "-",
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: vente.monnaie > 0 ? Colors.red : Colors.grey,
                          ),
                        )),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.list, size: 20),
                              onPressed: () => _showProduitsDialog(vente),
                            ),
                            IconButton(
                              icon: const Icon(Icons.print,
                                  size: 20, color: Colors.blue),
                              onPressed: () => generateFacturePdf(vente),
                            ),
                            if (vente.reste > 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 30),
                                  backgroundColor: Colors.blueAccent,
                                ),
                                child: Text(
                                  'Règlement',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () => _ouvrirDialogReglement(
                                    context, vente, "règlement"),
                              ),
                            if (vente.monnaie > 0)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(0, 30),
                                  backgroundColor: Colors.blueAccent,
                                ),
                                child: Text(
                                  'Remboursement',
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                                onPressed: () => _ouvrirDialogReglement(
                                    context, vente, "remboursement"),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'payée':
        return Colors.green;
      case 'crédit':
        return Colors.orange;
      case 'partiel':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _showProduitsDialog(VenteModel vente) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(isMobile ? 8 : 24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 600,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    /// Titre + bouton fermeture
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Produits vendus - ${DateFormat('dd/MM/yyyy').format(vente.date)}",
                            style: GoogleFonts.roboto(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    /// Liste des produits
                    Expanded(
                      child: SingleChildScrollView(
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1.5),
                            3: FlexColumnWidth(1.5),
                          },
                          border: TableBorder.all(color: Colors.grey[300]!),
                          children: [
                            /// Header
                            TableRow(
                              decoration:
                                  BoxDecoration(color: Colors.blueGrey[50]),
                              children: [
                                _buildHeaderCell("Produit"),
                                _buildHeaderCell("Qté", center: true),
                                _buildHeaderCell("Prix Unitaire", center: true),
                                _buildHeaderCell("Sous-total", center: true),
                              ],
                            ),

                            /// Produits dynamiques
                            ...vente.produits.map((prod) {
                              return TableRow(
                                decoration:
                                    const BoxDecoration(color: Colors.white),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        prod.image != null &&
                                                prod.image!.isNotEmpty
                                            ? Image.network(
                                                prod.image!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            prod.nom,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _buildCell("${prod.quantite}"),
                                  _buildCell("${prod.prixUnitaire} Fcfa"),
                                  _buildCell("${_calculerSousTotal(prod)} Fcfa",
                                      bold: true),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Total final
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total:",
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${vente.total} Fcfa",
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Widgets helpers
  Widget _buildHeaderCell(String text, {bool center = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        textAlign: center ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget _buildCell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          children: [
            pw.Text("Historique des ventes",
                style: const pw.TextStyle(fontSize: 20)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ["Date", "Client", "Total", "Paiement", "Statut"],
              data: filteredVentes.map((vente) {
                return [
                  DateFormat('dd/MM/yyyy').format(vente.date),
                  vente.clientNom ?? "Occasionnel",
                  "${vente.total} Fcfa",
                  vente.typePaiement,
                  vente.statut
                ];
              }).toList(),
            )
          ],
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  Future<pw.MemoryImage?> tryLoadNetworkImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return pw.MemoryImage(response.bodyBytes);
      }
    } catch (_) {}
    return null;
  }

  Future<void> generateFacturePdf(VenteModel vente) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormat =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

    // Chargement des données du profil
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    ProfilModel? profil;
    try {
      final res = await ServicesProfil().getProfils(token);
      if (res.statusCode == 200) {
        profil = ProfilModel.fromJson(res.data["profils"]);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }

    // Chargement du logo
    final pw.MemoryImage? logoNetwork =
        await tryLoadNetworkImage(profil?.image ?? "");
    final pw.ImageProvider logoLocal = pw.MemoryImage(
      (await rootBundle.load('assets/logos/LOGO CGTECH.JPG'))
          .buffer
          .asUint8List(),
    );

    // Calcul des montants de base avec remise prise en compte
    final double totalHT = vente.produits.fold(0, (sum, p) {
      final prixAvecRemise = (p.remise != null && p.remise! > 0)
          ? (p.remiseType == 'pourcent'
              ? p.prixUnitaire * (1 - p.remise! / 100)
              : p.prixUnitaire - p.remise!)
          : p.prixUnitaire;
      return sum + (prixAvecRemise * p.quantite);
    });

    // Gestion de la TVA avec remise prise en compte
    double totalTVA;
    bool isTvaGlobale = vente.tvaGlobale != null && vente.tvaGlobale! > 0;

    if (isTvaGlobale) {
      totalTVA = (totalHT * vente.tvaGlobale!) / 100;
    } else {
      totalTVA = vente.produits.fold(0, (sum, p) {
        final prixAvecRemise = (p.remise != null && p.remise! > 0)
            ? (p.remiseType == 'pourcent'
                ? p.prixUnitaire * (1 - p.remise! / 100)
                : p.prixUnitaire - p.remise!)
            : p.prixUnitaire;

        final tvaProduit = p.tva ?? 0;
        return sum + ((prixAvecRemise * p.quantite * tvaProduit) / 100);
      });
    }

    // Calcul du TTC de base
    double totalTTC = totalHT + totalTVA;

    // Application des frais supplémentaires
    totalTTC += (vente.livraison ?? 0) + (vente.emballage ?? 0);

    // Application de la remise globale
    if (vente.remiseGlobale != null && vente.remiseGlobale! > 0) {
      if (vente.remiseGlobaleType == 'pourcent') {
        totalTTC -= (totalTTC * vente.remiseGlobale!) / 100;
      } else {
        totalTTC -= vente.remiseGlobale!;
      }
    }

    // Calcul du reste à payer
    final int reste = (vente.total - vente.montantRecu) > 0
        ? (vente.total - vente.montantRecu)
        : 0;

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoNetwork ?? logoLocal, width: 100, height: 100),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("FACTURE",
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text("N°: ${vente.facturNumber}",
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text("Date: ${dateFormatter.format(vente.date)}",
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Informations client
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("CLIENT",
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text("Nom: ${vente.clientNom ?? '-'}"),
                    if (vente.contactClient != null)
                      pw.Text("Contact: ${vente.contactClient}"),
                    if (vente.clientAdresse != null)
                      pw.Text("Adresse: ${vente.clientAdresse}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des produits
              pw.Text("DÉTAIL DES ARTICLES",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Désignation",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Qté",
                            textAlign: pw.TextAlign.center,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("P.U",
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Montant HT",
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...vente.produits.map((p) {
                    final prixAvecRemise = (p.remise != null && p.remise! > 0)
                        ? (p.remiseType == 'pourcent'
                            ? p.prixUnitaire * (1 - p.remise! / 100)
                            : p.prixUnitaire - p.remise!)
                        : p.prixUnitaire;

                    final totalHTProduit = prixAvecRemise * p.quantite;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(p.nom),
                              if ((p.remise ?? 0) > 0)
                                pw.Text(
                                  "Remise: ${p.remise} ${p.remiseType == 'pourcent' ? '%' : 'FCFA'}",
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey600),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(p.quantite.toString(),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(currencyFormat.format(prixAvecRemise),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(currencyFormat.format(totalHTProduit),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  })
                ],
              ),
              pw.SizedBox(height: 20),

              // Section Totaux
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Total HT
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text("Total HT: ",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFormat.format(totalHT)),
                      ],
                    ),

                    // TVA
                    if (isTvaGlobale) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("TVA : ",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(totalTVA)),
                        ],
                      ),
                    ] else if (totalTVA > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Total TVA: ",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(totalTVA)),
                        ],
                      ),
                    ],

                    // Total TTC avant frais et remises
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text("Total TTC: ",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(currencyFormat.format(totalHT + totalTVA),
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),

                    // Frais de livraison
                    if ((vente.livraison ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Livraison: "),
                          pw.Text(currencyFormat.format(vente.livraison)),
                        ],
                      ),
                    ],

                    // Frais d'emballage
                    if ((vente.emballage ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Emballage: "),
                          pw.Text(currencyFormat.format(vente.emballage)),
                        ],
                      ),
                    ],

                    // Remise globale
                    if (vente.remiseGlobale != null &&
                        vente.remiseGlobale! > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("- Remise Globale: "),
                          pw.Text(
                              "${vente.remiseGlobale} ${vente.remiseGlobaleType == 'pourcent' ? '%' : 'FCFA'}",
                              style:
                                  const pw.TextStyle(color: PdfColors.green)),
                        ],
                      ),
                    ],

                    // Total Net à Payer
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue700),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text("NET À PAYER: ",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 16)),
                              pw.Text(currencyFormat.format(vente.total),
                                  style: const pw.TextStyle(
                                      fontSize: 16, color: PdfColors.blue700)),
                            ],
                          ),

                          // Détails de paiement
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text("Montant Reçu: ",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(currencyFormat.format(vente.montantRecu)),
                            ],
                          ),

                          if (vente.monnaie > 0) pw.SizedBox(height: 4),
                          if (vente.monnaie > 0)
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text("Monnaie Rendue: ",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(currencyFormat.format(vente.monnaie)),
                              ],
                            ),

                          if (reste > 0) pw.SizedBox(height: 4),
                          if (reste > 0)
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text("Reste à Payer: ",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red)),
                                pw.Text(currencyFormat.format(reste),
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pied de page
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Mode de Paiement: ${vente.typePaiement}"),
                  pw.Text("Statut: ${vente.statut}"),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                vente.factureFooter ?? "Merci pour votre confiance !",
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: vente.footerAlignement == 'centre'
                    ? pw.TextAlign.center
                    : vente.footerAlignement == 'droite'
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) => pdf.save());
  }

  Future<void> _generateRapportPdfPro(
      List<VenteModel> ventes, DateTime? dateDebut, DateTime? dateFin) async {
    final pdf = pw.Document();
    final format = DateFormat('dd/MM/yyyy');

    ProfilModel? profil;
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await ServicesProfil().getProfils(token);
      if (res.statusCode == 200) {
        profil = ProfilModel.fromJson(res.data["profils"]);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }

    final pw.MemoryImage? logoNetwork =
        await tryLoadNetworkImage(profil?.image ?? "");

    final pw.ImageProvider logoLocal = pw.MemoryImage(
      (await rootBundle.load('assets/logos/salespulse.jpg'))
          .buffer
          .asUint8List(),
    );

    final total = ventes.fold<int>(0, (sum, v) => sum + v.total);
    final moyenne = ventes.isNotEmpty ? (total ~/ ventes.length) : 0;

    // Par client
    final ventesParClient = <String, int>{};
    final ventesParClientCount = <String, int>{};

    // Par jour
    final ventesParJour = <String, int>{};
    final ventesParJourCount = <String, int>{};

    // Par produit
    final ventesParProduit = <String, int>{};

    for (var v in ventes) {
      final nomClient = v.clientNom ?? '—';
      ventesParClient[nomClient] = (ventesParClient[nomClient] ?? 0) + v.total;
      ventesParClientCount[nomClient] =
          (ventesParClientCount[nomClient] ?? 0) + 1;

      final date = format.format(v.date);
      ventesParJour[date] = (ventesParJour[date] ?? 0) + v.total;
      ventesParJourCount[date] = (ventesParJourCount[date] ?? 0) + 1;

      for (var produit in v.produits) {
        final nomProduit = produit.nom;
        final quantite = produit.quantite;
        ventesParProduit[nomProduit] =
            (ventesParProduit[nomProduit] ?? 0) + quantite;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            pw.Image(
              logoNetwork ?? logoLocal,
              width: 100,
              height: 100,
            ),
            pw.SizedBox(height: 10),
            pw.SizedBox(height: 20),
            pw.Text("Rapport de ventes",
                style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),
            pw.Text(
                "Période : ${dateDebut != null ? format.format(dateDebut) : '—'} → ${dateFin != null ? format.format(dateFin) : '—'}"),
            pw.SizedBox(height: 12),

            // Résumé
            pw.Text("Résumé général :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: "Nombre total de ventes : ${ventes.length}"),
            pw.Bullet(text: "Total vendu : $total Fcfa"),
            pw.Bullet(text: "Moyenne par vente : $moyenne Fcfa"),
            pw.SizedBox(height: 12),

            // Par client
            pw.Text("Répartition par client :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParClient.entries.map((e) {
              final count = ventesParClientCount[e.key];
              return pw.Text("- ${e.key} : ${e.value} Fcfa  ($count ventes)");
            }),
            pw.SizedBox(height: 12),

            // Par jour
            pw.Text("Répartition par jour :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParJour.entries.map((e) {
              final count = ventesParJourCount[e.key]!;
              return pw.Text("- ${e.key} : ${e.value} Fcfa  ($count ventes)");
            }),
            pw.SizedBox(height: 12),

            // Répartition par produit
            pw.Text("Répartition par produit :",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...ventesParProduit.entries.map((e) {
              return pw.Text("- ${e.key} : ${e.value} unité(s)");
            }),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  void _ouvrirDialogReglement(
      BuildContext context, VenteModel vente, String type) {
    final montantController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type == "règlement" ? "Règlement" : "Remboursement"),
        content: TextField(
          controller: montantController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: "Montant",
              labelStyle:
                  GoogleFonts.roboto(fontSize: 14, color: Colors.black)),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(dialogContext),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700),
            child: Text(
              "Valider",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
            ),
            onPressed: () async {
              final montant = int.tryParse(montantController.text) ?? 0;
              if (montant <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(
                    content: Text("Montant invalide ou supérieur au dû")));
                return;
              }

              final token =
                  Provider.of<AuthProvider>(context, listen: false).token;
              final userId =
                  Provider.of<AuthProvider>(context, listen: false).userId;
              final userName =
                  Provider.of<AuthProvider>(context, listen: false).userName;
              final adminId =
                  Provider.of<AuthProvider>(context, listen: false).adminId;

              final reglement = {
                "venteId": vente.id,
                "userId": userId,
                "adminId": adminId,
                "clientId": vente.clientId,
                "nom": vente.clientNom,
                "montant": montant,
                "type": type,
                "mode": vente.typePaiement,
                "operateur": userName,
                "date": DateTime.now().toIso8601String(),
              };

              final res =
                  await ServicesReglements().postReglements(reglement, token);

              if (res.statusCode == 201) {
                Navigator.pop(dialogContext);
                fetchVentes();
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text("Erreur lors du règlement")));
              }
            },
          ),
        ],
      ),
    );
  }

  int _calculerSousTotal(ProductItemModel prod) {
    int prixUnitaire = prod.prixUnitaire;
    if (prod.remiseType == 'fcfa') {
      prixUnitaire -= prod.remise!;
    } else if (prod.remiseType == 'pourcent') {
      prixUnitaire -= ((prixUnitaire * prod.remise!) ~/ 100);
    }
    if (prixUnitaire < 0) prixUnitaire = 0;

    int sousTotalBrut = prixUnitaire * prod.quantite;
    double montantTVA =
        (prod.tva! > 0) ? ((sousTotalBrut * prod.tva!) / 100) : 0;
    return (sousTotalBrut +
            montantTVA +
            prod.fraisLivraison! +
            prod.fraisEmballage!)
        .round();
  }
}
