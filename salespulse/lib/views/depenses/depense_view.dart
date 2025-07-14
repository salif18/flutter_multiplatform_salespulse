import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/depenses_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/depense_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class DepenseScreen extends StatefulWidget {
  const DepenseScreen({super.key});

  @override
  State<DepenseScreen> createState() => _DepenseScreenState();
}

class _DepenseScreenState extends State<DepenseScreen> {
  List<DepensesModel> _depenses = [];
  List<DepensesModel> _filtered = [];

  final TextEditingController _motifController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  String _selectedType = "transport";

  final List<Map<String, dynamic>> _typeOptions = [
    {"label": "Transport", "value": "transport", "icon": Icons.directions_car},
    {"label": "Salaire", "value": "salaire", "icon": Icons.person},
    {"label": "Paiement", "value": "paiement", "icon": Icons.sell},
    {"label": "Achat", "value": "achat", "icon": Icons.shopping_cart},
    {"label": "Autre", "value": "autre", "icon": Icons.receipt},
  ];

  String _filterType = "all";
  String _filterMotif = "";
  DateTimeRange? _filterDate;

  @override
  void initState() {
    super.initState();
    _fetchDepenses();
  }

  Future<void> _fetchDepenses() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await ServicesDepense().getAllDepenses(token);
      if (res.statusCode == 200) {
        final List data = res.data["depenses"];
        setState(() {
          _depenses = data.map((e) => DepensesModel.fromJson(e)).toList();
          _applyFilters();
        });
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          // 👉 Afficher message spécifique abonnement expiré
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
                      MaterialPageRoute(
                          builder: (_) => const AbonnementScreen()),
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

      // 🚫 Autres DioException (ex: réseau)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
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
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _depenses.where((d) {
        final typeOk = _filterType == "all" || d.type == _filterType;
        final motifOk =
            d.motifs.toLowerCase().contains(_filterMotif.toLowerCase());
        final dateOk = _filterDate == null ||
            (d.date.isAfter(
                    _filterDate!.start.subtract(const Duration(days: 1))) &&
                d.date.isBefore(_filterDate!.end.add(const Duration(days: 1))));
        return typeOk && motifOk && dateOk;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return SizedBox(
          height: 400,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Filtres",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (val) {
                    _filterMotif = val;
                    _applyFilters();
                  },
                  decoration:
                      const InputDecoration(labelText: "Rechercher un motif"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _filterType,
                  items: [
                    const DropdownMenuItem(
                        value: "all", child: Text("Tous les types")),
                    ..._typeOptions.map((t) => DropdownMenuItem(
                        value: t["value"], child: Text(t["label"]))),
                  ],
                  onChanged: (val) {
                    _filterType = val!;
                    _applyFilters();
                  },
                  decoration: const InputDecoration(labelText: "Type"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (range != null) {
                      _filterDate = range;
                      _applyFilters();
                    }
                  },
                  icon: const Icon(
                    Icons.date_range,
                    color: Colors.white,
                  ),
                  label: Text("Choisir une période",
                      style: GoogleFonts.roboto(
                          fontSize: 14, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    setState(() {
                      _filterDate = null;
                      _filterMotif = "";
                      _filterType = "all";
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Réinitialiser les filtres",
                    style:
                        GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddDepenseBottomSheet() {
    showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text("Nouvelle dépense",
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextField(
                  controller: _motifController,
                  decoration: const InputDecoration(
                      labelText: "Motif", prefixIcon: Icon(Icons.description)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _montantController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: "Montant", prefixIcon: Icon(Icons.money)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                      labelText: "Type de dépense",
                      prefixIcon: Icon(Icons.category)),
                  items: _typeOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option["value"],
                      child: Row(
                        children: [
                          Icon(option["icon"], size: 20),
                          const SizedBox(width: 10),
                          Text(option["label"]),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value!),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () async {
                    final token =
                        Provider.of<AuthProvider>(context, listen: false).token;
                    final userId =
                        Provider.of<AuthProvider>(context, listen: false)
                            .userId;
                    final adminId =
                        Provider.of<AuthProvider>(context, listen: false)
                            .adminId;

                    final data = {
                      "userId": userId,
                      "adminId": adminId,
                      "motifs": _motifController.text,
                      "montants": int.tryParse(_montantController.text) ?? 0,
                      "type": _selectedType,
                      "date": DateTime.now().toIso8601String(),
                    };

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final res =
                          await ServicesDepense().postNewDepenses(data, token);
                      Navigator.pop(context);
                      if (res.statusCode == 201) {
                        _motifController.clear();
                        _montantController.clear();
                        setState(() => _selectedType = "transport");
                        Navigator.pop(context);
                        _fetchDepenses();
                      }
                    } catch (e) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  label: Text(
                    "Enregistrer",
                    style:
                        GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'transport':
        return Icons.directions_car;
      case 'salaire':
        return Icons.person;
      case 'achat':
        return Icons.shopping_cart;
      default:
        return Icons.receipt;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'transport':
        return Colors.orange;
      case 'salaire':
        return Colors.blue;
      case 'achat':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  double _getTotalFiltered() {
    return _filtered.fold(0.0, (sum, e) => sum + e.montants);
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
         automaticallyImplyLeading: false,
          title: Text("Dépenses",
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey //const Color(0xff001c30),
          ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _filtered.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/not_data.png", width: 200),
                    const SizedBox(height: 20),
                    Text("Aucune dépense trouvée",
                        style: GoogleFonts.poppins(fontSize: 16)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'Fcfa').format(_getTotalFiltered())}",
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: _showFilterSheet,
                        icon: const Icon(
                          Icons.filter_alt_outlined,
                          color: Colors.black,
                        ),
                        tooltip: "Filtrer",
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final d = _filtered[index];
                        return Card(
                          elevation: 2,
                          color: Colors.white,
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForType(d.type),
                              child: Icon(_getIconForType(d.type),
                                  color: Colors.white),
                            ),
                            title: Text(d.motifs,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                DateFormat('dd MMM yyyy – HH:mm')
                                    .format(d.date),
                                style: GoogleFonts.poppins(fontSize: 13)),
                            trailing: Text(
                              NumberFormat.currency(
                                      locale: 'fr_FR', symbol: 'Fcfa')
                                  .format(d.montants),
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        onPressed: _showAddDepenseBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
