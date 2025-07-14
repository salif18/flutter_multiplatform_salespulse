// ignore_for_file: use_build_context_synchronously, deprecated_member_use, depend_on_referenced_packages

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/mouvements_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/mouvement_api.dart';

class MouvementsListFiltered extends StatefulWidget {
  final String productId;
  final String token;

  const MouvementsListFiltered(
      {super.key, required this.productId, required this.token});

  @override
  // ignore: library_private_types_in_public_api
  _MouvementsListFilteredState createState() => _MouvementsListFilteredState();
}

class _MouvementsListFilteredState extends State<MouvementsListFiltered> {
  final ServicesMouvements api = ServicesMouvements();

  List<MouvementModel> mouvements = [];
  int page = 1;
  int limit = 5;
  int totalPages = 1;

  String? selectedType;
  DateTime? dateDebut;
  DateTime? dateFin;

  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchMouvements();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLoading &&
          page <= totalPages) {
        fetchMouvements();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchMouvements({bool reset = false}) async {
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    if (reset) {
      page = 1;
      mouvements.clear();
    }

    if (page > totalPages) return; // plus de pages

    setState(() => isLoading = true);

    try {
      final result = await api.getMouvements(
        adminId: adminId,
        token: widget.token,
        productId: widget.productId,
        type: selectedType,
        dateDebut: dateDebut,
        dateFin: dateFin,
        page: page,
        limit: limit,
      );

      final List<MouvementModel> mouvementsJson = result["mouvements"] ?? [];
      final pagination = result["pagination"] ?? {};

      setState(() {
        mouvements.addAll(mouvementsJson);
        totalPages = pagination["totalPages"] ?? 1;
        page++;
      });
    } on DioException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Problème de connexion : Vérifiez votre Internet.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showFilterDialog() {
    String? tempType = selectedType;
    DateTime? tempDateDebut = dateDebut;
    DateTime? tempDateFin = dateFin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filtrer les mouvements"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: tempType,
                hint: const Text("Type de mouvement"),
                items: [
                  DropdownMenuItem(
                      value: null,
                      child: Text(
                        "Tous",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.black),
                      )),
                  DropdownMenuItem(
                      value: 'ajout',
                      child: Text('Ajout',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'vente',
                      child: Text('Vente',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'retrait',
                      child: Text('Retrait',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'perte',
                      child: Text('Perte',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                  DropdownMenuItem(
                      value: 'modification',
                      child: Text('Modification',
                          style: GoogleFonts.poppins(
                              fontSize: 14, color: Colors.black))),
                ],
                onChanged: (value) {
                  tempType = value;
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempDateDebut ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      tempDateDebut = date;
                    });
                  }
                },
                child: Text(
                    tempDateDebut == null
                        ? "Sélectionner date début"
                        : "Début: ${DateFormat('dd/MM/yyyy').format(tempDateDebut!)}",
                    style:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempDateFin ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      tempDateFin = date;
                    });
                  }
                },
                child: Text(
                    tempDateFin == null
                        ? "Sélectionner date fin"
                        : "Fin: ${DateFormat('dd/MM/yyyy').format(tempDateFin!)}",
                    style:
                        GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler",
                style:
                    GoogleFonts.poppins(fontSize: 14, color: Colors.blueGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                selectedType = tempType;
                dateDebut = tempDateDebut;
                dateFin = tempDateFin;
                mouvements.clear();
                page = 1;
              });
              fetchMouvements(reset: true);
              Navigator.pop(context);
            },
            child: Text("Appliquer",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case "ajout":
        return Icons.add_box;
      case "vente":
        return Icons.remove_shopping_cart;
      case "retrait":
        return Icons.indeterminate_check_box;
      case "perte":
        return Icons.error_outline;
      case "modification":
        return Icons.edit;
      default:
        return Icons.device_unknown;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case "ajout":
        return Colors.green.shade700;
      case "vente":
        return Colors.red.shade700;
      case "retrait":
        return Colors.orange.shade700;
      case "perte":
        return Colors.grey.shade700;
      case "modification":
        return Colors.blue.shade700;
      default:
        return Colors.black87;
    }
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

    // Vérification initiale de l'authentification
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
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
              size: 18,
              color: Colors.black,
            )),
        title: Text(
          "Historique des mouvements",
          style: GoogleFonts.roboto(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white, // const Color(0xff001c30),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Colors.orange.shade700,
            ),
            tooltip: "Filtrer",
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: mouvements.isEmpty && !isLoading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/not_data.png",
                    width: 200, height: 200, fit: BoxFit.cover),
                const SizedBox(height: 20),
                Text("Aucun produit trouvé",
                    style: GoogleFonts.poppins(fontSize: 14)),
              ],
            ))
          : Column(
              children: [
                Expanded(
                    child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minWidth: constraints.maxWidth),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          child: DataTable(
                            columnSpacing: 20,
                            headingRowHeight: 35,
                            headingRowColor:
                                WidgetStateProperty.all(Colors.blueGrey),
                            headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            columns: [
                              DataColumn(
                                  label: Text(
                                "Type".toUpperCase(),
                                style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              )),
                              DataColumn(
                                  label: Text("Quantité".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              DataColumn(
                                  label: Text("Date".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              DataColumn(
                                  label: Text("Description".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              DataColumn(
                                  label: Text("Avant".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              DataColumn(
                                  label: Text("Après".toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                            ],
                            rows: mouvements.map((mouv) {
                              final color = _colorForType(mouv.type);
                              return DataRow(cells: [
                                DataCell(Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: color.withOpacity(0.2),
                                      radius: 14,
                                      child: Icon(
                                        _iconForType(mouv.type),
                                        color: color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      mouv.type.toUpperCase(),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: color),
                                    ),
                                  ],
                                )),
                                DataCell(Text(
                                  mouv.quantite.toString(),
                                  style: TextStyle(color: color),
                                )),
                                DataCell(Text(DateFormat('dd/MM/yyyy HH:mm')
                                    .format(mouv.date))),
                                DataCell(
                                  SizedBox(
                                    width: 250,
                                    child: Text(
                                      mouv.description,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(mouv.ancienStock.toString())),
                                DataCell(Text(
                                  mouv.nouveauStock.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  }),
                )),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
