// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class ProduitTendance {
  final String productId;
  final String nom;
  final String image;
  final int quantiteTotale;

  ProduitTendance({
    required this.productId,
    required this.nom,
    required this.image,
    required this.quantiteTotale,
  });
}

class VenteProduit {
  final String productId;
  final String nom;
  final String image;
  final int quantite;

  VenteProduit({
    required this.productId,
    required this.nom,
    required this.image,
    required this.quantite,
  });

  factory VenteProduit.fromJson(Map<String, dynamic> json) {
    return VenteProduit(
      productId: json['productId'],
      nom: json['nom'],
      image: json['image'] ?? '',
      quantite: json['quantite'],
    );
  }
}

class VenteModel {
  final String id;
  final List<VenteProduit> produits;
  final DateTime date;

  VenteModel({
    required this.id,
    required this.produits,
    required this.date,
  });

  factory VenteModel.fromJson(Map<String, dynamic> json) {
    var produitsJson = json['produits'] as List<dynamic>;
    List<VenteProduit> produits =
        produitsJson.map((p) => VenteProduit.fromJson(p)).toList();

    return VenteModel(
      id: json['_id'],
      produits: produits,
      date: DateTime.parse(json['date']),
    );
  }
}

class StatistiquesProduitsPage extends StatefulWidget {
  const StatistiquesProduitsPage({super.key});

  @override
  State<StatistiquesProduitsPage> createState() =>
      _StatistiquesProduitsPageState();
}

class _StatistiquesProduitsPageState extends State<StatistiquesProduitsPage> {
  List<ProduitTendance> produitsTendance = [];
  bool isLoading = true;
  String errorMessage = '';

  ServicesVentes api = ServicesVentes();

  @override
  void initState() {
    super.initState();
    fetchVentes();
  }

  Future<void> fetchVentes() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await api.getAllVentes(token);

      if (response.statusCode == 200) {
        List ventesJson = response.data["ventes"];
        List<VenteModel> ventes =
            ventesJson.map((json) => VenteModel.fromJson(json)).toList();

        Map<String, ProduitTendance> mapProduits = {};
        for (var vente in ventes) {
          for (var produit in vente.produits) {
            if (mapProduits.containsKey(produit.productId)) {
              final ancien = mapProduits[produit.productId]!;
              mapProduits[produit.productId] = ProduitTendance(
                productId: produit.productId,
                nom: produit.nom,
                image: produit.image,
                quantiteTotale: ancien.quantiteTotale + produit.quantite,
              );
            } else {
              mapProduits[produit.productId] = ProduitTendance(
                productId: produit.productId,
                nom: produit.nom,
                image: produit.image,
                quantiteTotale: produit.quantite,
              );
            }
          }
        }

        List<ProduitTendance> produitsTrie = mapProduits.values.toList();
        produitsTrie.sort((a, b) => b.quantiteTotale.compareTo(a.quantiteTotale));

        setState(() {
          produitsTendance = produitsTrie;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Erreur lors du chargement des ventes";
          isLoading = false;
        });
      }
    } on DioException catch (e) {
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

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutButton();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  bool get isMobile => MediaQuery.of(context).size.width < 600;
  bool get isTablet => MediaQuery.of(context).size.width >= 600 && 
                     MediaQuery.of(context).size.width < 1024;
  bool get isDesktop => MediaQuery.of(context).size.width >= 1024;

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
        automaticallyImplyLeading: false,
        title: Text(
          "Statistiques produits en tendance",
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: _buildAdaptiveBody(),
    );
  }

  Widget _buildAdaptiveBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (produitsTendance.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
      child: isMobile ? _buildMobileList() : _buildDesktopTable(),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: produitsTendance.length,
      itemBuilder: (context, index) {
        final produit = produitsTendance[index];
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 2),
          elevation: 0.5,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: produit.image.isNotEmpty
                      ? Image.network(
                          produit.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported,
                            size: 60,
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 60),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produit.nom,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            "Vendus: ${produit.quantiteTotale}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Container(
                width: isDesktop ? 1024 : 600,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: 24,
                  headingRowHeight: 50,
                  dataRowHeight: 60,
                  headingRowColor: MaterialStateProperty.all(Colors.blueGrey),
                  headingTextStyle: GoogleFonts.roboto(
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  columns: [
                    DataColumn(
                      label: Text("Image".toUpperCase()),
                      numeric: false,
                    ),
                    DataColumn(
                      label: Text("Nom du produit".toUpperCase()),
                      numeric: false,
                    ),
                    DataColumn(
                      label: Text("Quantité vendue".toUpperCase()),
                      numeric: true,
                    ),
                    if (isDesktop) DataColumn(
                      label: Text("Détails".toUpperCase()),
                      numeric: false,
                    ),
                  ],
                  rows: produitsTendance.map((produit) {
                    return DataRow(
                      cells: [
                        DataCell(
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: produit.image.isNotEmpty
                                ? Image.network(
                                    produit.image,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported,
                                      size: 40,
                                    ),
                                  )
                                : const Icon(Icons.image_not_supported, size: 40),
                          ),
                        ),
                        DataCell(
                          Text(
                            produit.nom,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            produit.quantiteTotale.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 14 : 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        if (isDesktop) DataCell(
                          IconButton(
                            icon: const Icon(Icons.monetization_on, color: Colors.blue),
                            onPressed: () {
                              // Action pour voir les détails
                            },
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}