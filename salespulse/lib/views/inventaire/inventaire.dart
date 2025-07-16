// ignore_for_file: deprecated_member_use, depend_on_referenced_packages

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/models/vente_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class InventaireProPage extends StatefulWidget {
  const InventaireProPage({super.key});

  @override
  State<InventaireProPage> createState() => _InventaireProPageState();
}

class _InventaireProPageState extends State<InventaireProPage> {
  ServicesStocks api = ServicesStocks();
  ServicesCategories apiCatego = ServicesCategories();
  List<ProductModel> produits = [];
  List<CategoriesModel> _listCategories = [];
  List<VenteModel> ventesRecentes = [];
  bool loading =true;

  String filtreCategorie = "Tout";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadVentes();
    _getCategories();
  }

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await api.getAllProducts(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          produits = (body["produits"] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
              loading = false;
        });
      }
    } on DioException catch (e) {
      _handleApiError(e);
    } on TimeoutException {
      _showTimeoutError();
    } catch (e) {
      _showGenericError(e);
    }
  }

  Future<void> _getCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await apiCatego.getCategories(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          _listCategories = (body["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      }
    } on DioException catch (e) {
      _handleApiError(e);
    } on TimeoutException {
      _showTimeoutError();
    } catch (e) {
      _showGenericError(e);
    }
  }

  Future<void> _loadVentes() async {
    final ServicesVentes api = ServicesVentes();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await api.getAllVentes(token);
      if (res.statusCode == 200) {
        final data = res.data;
        setState(() {
          ventesRecentes = (data["ventes"] as List)
              .map((e) => VenteModel.fromJson(e))
              .toList();
              loading = false;
        });
      }
    } on DioException catch (e) {
      _handleApiError(e);
    } on TimeoutException {
      _showTimeoutError();
    } catch (e) {
      _showGenericError(e);
    }
  }

  void _handleApiError(DioException e) {
    if (e.response != null && e.response?.statusCode == 403) {
      final errorMessage = e.response?.data['error'] ?? '';
      if (errorMessage.toString().contains("abonnement")) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Abonnement expiré"),
            content: const Text("Votre abonnement a expiré. Veuillez le renouveler."),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Problème de connexion : Vérifiez votre Internet.",
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  void _showTimeoutError() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
  }

  void _showGenericError(dynamic e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    debugPrint(e.toString());
  }

  Future<void> updateStockOnServer(String productId, String userId, int saisie,
      String type, String description) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    try {
      Map<String, dynamic> data = {
        "userId": userId,
        "adminId": adminId,
        "type": type,
        "description": description,
      };

      if (type == "modification") {
        data["stocks"] = saisie;
      } else {
        data["stocks"] = saisie;
      }

      final response = await api.updateStockProduct(data, token, productId);

      if (response.statusCode == 200) {
        _loadProducts();
        debugPrint("✅ Stock mis à jour avec succès");
      } else {
        debugPrint("❌ Erreur de mise à jour : ${response.data}");
      }
    } on DioException {
      _showTimeoutError();
    } on TimeoutException {
      _showTimeoutError();
    } catch (e) {
      _showGenericError(e);
    }
  }

  void _modifierStock(ProductModel produit) {
    final quantiteController = TextEditingController(text: produit.stocks.toString());
    final descriptionController = TextEditingController();
    String selectedType = 'modification';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Modifier stock - ${produit.nom}',
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: quantiteController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: 'Quantité en stock',
                        labelStyle: GoogleFonts.poppins(fontSize: 14)),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: InputDecoration(
                        labelText: 'Type de mouvement',
                        labelStyle: GoogleFonts.poppins(fontSize: 14)),
                    items: [
                      DropdownMenuItem(
                          value: 'ajout',
                          child: Text('Ajout', style: GoogleFonts.roboto(fontSize: 14))),
                      DropdownMenuItem(
                          value: 'vente',
                          child: Text('Vente', style: GoogleFonts.roboto(fontSize: 14))),
                      DropdownMenuItem(
                          value: 'retrait',
                          child: Text('Retrait', style: GoogleFonts.roboto(fontSize: 14))),
                      DropdownMenuItem(
                          value: 'perte',
                          child: Text('Perte', style: GoogleFonts.roboto(fontSize: 14))),
                      DropdownMenuItem(
                          value: 'modification',
                          child: Text('Modification', style: GoogleFonts.roboto(fontSize: 14))),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                        labelText: 'Description (optionnel)',
                        labelStyle: GoogleFonts.poppins(fontSize: 14)),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Annuler',
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.blueGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  final userId = Provider.of<AuthProvider>(context, listen: false).userId;
                  final nouvelleQte = int.tryParse(quantiteController.text);
                  if (nouvelleQte == null || nouvelleQte < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quantité invalide')),
                    );
                    return;
                  }

                  await updateStockOnServer(
                    produit.id,
                    userId,
                    nouvelleQte,
                    selectedType,
                    descriptionController.text.trim(),
                  );

                  setState(() {
                    produit.stocks = nouvelleQte;
                  });
                  Navigator.of(ctx).pop();
                },
                child: Text('Enregistrer',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> exportInventairePdf() async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'Fcfa');

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Inventaire des Produits",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: [
                "Produit",
                "Catégorie",
                "Stock",
                "Prix Achat",
                "Prix Vente",
                "Seuil alerte"
              ],
              data: produits.map((p) {
                return [
                  p.nom,
                  p.categories,
                  "${p.stocks} ${p.unite}",
                  formatter.format(p.prixAchat),
                  formatter.format(p.prixVente),
                  p.seuilAlerte.toString(),
                ];
              }).toList(),
            )
          ],
        ),
      ),
    );
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
    final role = Provider.of<AuthProvider>(context, listen: false).role;
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

    final filteredProduits = produits.where((p) {
      final matchCategorie = filtreCategorie == "Tout" || p.categories == filtreCategorie;
      final matchSearch = _searchController.text.isEmpty ||
          p.nom.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchCategorie && matchSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
         automaticallyImplyLeading: false,
        title: Text('Inventaire Pro',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.blueGrey,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1024) {
            return _buildDesktopLayout(role, filteredProduits);
          } else if (constraints.maxWidth > 600) {
            return _buildTabletLayout(role, filteredProduits);
          } else {
            return _buildMobileLayout(role, filteredProduits);
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout(String role, List<ProductModel> filteredProduits) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 380,
            child: _buildRecentSalesCard(),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildProductListSection(role, filteredProduits),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(String role, List<ProductModel> filteredProduits) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: _buildRecentSalesCard(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildProductListSection(role, filteredProduits),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String role, List<ProductModel> filteredProduits) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory)), 
              Tab(icon: Icon(Icons.receipt_long)),
            ],
          ),
        
        body: TabBarView(
          children: [
            _buildProductListSection(role, filteredProduits),
            _buildRecentSalesCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSalesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ventes récentes",
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const Divider(),
          Expanded(
            child: 
            loading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
            :
             ventesRecentes.isEmpty
                ? Center(
                    child: Text("Aucune vente",
                        style: GoogleFonts.poppins()))
                : ListView.builder(
                    itemCount: ventesRecentes.length,
                    itemBuilder: (context, index) {
                      final v = ventesRecentes[index];
                      return ListTile(
                        leading: const Icon(Icons.receipt_long,
                            color: Colors.orange),
                        title: Text(v.clientNom ?? "Occasionnel",
                            style: GoogleFonts.poppins()),
                        subtitle: Text(
                            DateFormat('dd MMM yyyy').format(v.date),
                            style: GoogleFonts.poppins()),
                        trailing: Text(
                          NumberFormat.currency(
                                  locale: 'fr_FR', symbol: 'Fcfa')
                              .format(v.total),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildProductListSection(String role, List<ProductModel> filteredProduits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         const SizedBox(height: 16),
        _buildFilterSection(),
        const SizedBox(height: 16),
        Expanded(
          child:
          loading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
            : 
            filteredProduits.isEmpty
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
                  ),
                )
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      childAspectRatio:2.4 ,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: filteredProduits.length,
                    itemBuilder: (context, index) {
                      final p = filteredProduits[index];
                      final isLowStock = p.stocks <= p.seuilAlerte;
                      return Card(
                        elevation: 0.01,
                        color: Colors.grey[50],
                        shadowColor: Colors.grey[200],
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(p.image ?? ""),
                            radius: 28,
                          ),
                          title: Text(p.nom,
                          overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Catégorie : ${p.categories}",
                                  style: GoogleFonts.poppins(fontSize: 12)),
                              Text("Stock : ${p.stocks} ${p.unite}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                      color: isLowStock
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                  "Prix vente : ${NumberFormat.currency(locale: 'fr_FR', symbol: 'Fcfa').format(p.prixVente)}",
                                  style: GoogleFonts.poppins()),
                            ],
                          ),
                          trailing: role == "admin" ? IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange),
                            onPressed: () => _modifierStock(p),
                          ):null,
                        ),
                      );
                    },
                  ),
              ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
   return Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: DropdownButtonFormField<String>(
          value: filtreCategorie,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.deepPurple.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            const DropdownMenuItem(value: "Tout", child: Text("Tout")),
            ..._listCategories.map((c) => DropdownMenuItem(
                  value: c.name,
                  child: Text(c.name),
                ))
          ],
          onChanged: (value) {
            setState(() {
              filtreCategorie = value!;
            });
          },
        ),
      ),
    ),
    SizedBox(
      width: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.deepPurple.shade50,
            prefixIcon: const Icon(Icons.search),
            hintText: "Rechercher un produit",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    ),
    IconButton(
      tooltip: "Exporter en PDF",
      onPressed: () => _exportInventairePdf(),
      icon: const Icon(Icons.print, size: 28, color: Colors.deepOrange),
    )
  ],
);

  }

  Future<void> _exportInventairePdf() async {
    final pdf = pw.Document();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: 'Fcfa');

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Inventaire des Produits",
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: [
                "Produit",
                "Catégorie",
                "Stock",
                "Prix Achat",
                "Prix Vente",
                "Seuil alerte"
              ],
              data: produits.map((p) {
                return [
                  p.nom,
                  p.categories,
                  "${p.stocks} ${p.unite}",
                  formatter.format(p.prixAchat),
                  formatter.format(p.prixVente),
                  p.seuilAlerte.toString(),
                ];
              }).toList(),
            )
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}