import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/client_model_pro.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/models/vente_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/client_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/services/vente_api.dart';
import 'package:salespulse/utils/format_prix.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
import 'package:salespulse/views/panier/recu_screen.dart';

class AddVenteScreen extends StatefulWidget {
  const AddVenteScreen({super.key});

  @override
  State<AddVenteScreen> createState() => _AddVenteScreenState();
}

class _AddVenteScreenState extends State<AddVenteScreen> {
  bool isActive = false;
  final FormatPrice formatPrice = FormatPrice();
  final ServicesStocks api = ServicesStocks();
  final ServicesClients _clientApi = ServicesClients();
  final ServicesVentes venteApi = ServicesVentes();

  List<ProductModel> allProducts = [];
  List<ClientModel> allClients = [];
  List<ProductItemModel> panier = [];
  List<ProductModel> selectedProducts = [];
  ClientModel? selectedClient;

  // Contrôleurs pour le nouveau client manuel
  TextEditingController nomController = TextEditingController();
  TextEditingController contactController = TextEditingController();
  TextEditingController adresseController = TextEditingController();

  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _montantRecuController = TextEditingController();
  final TextEditingController _remiseGlobaleController =
      TextEditingController();
  String _remiseGlobaleType = 'fcfa';
  final TextEditingController _tvaGlobaleController = TextEditingController();
  final TextEditingController _livraisonController = TextEditingController();
  final TextEditingController _emballageController = TextEditingController();

  int total = 0;
  int monnaie = 0;
  String? selectedClientId;
  String selectedPaiement = 'cash';

  final List<String> modePaiementOptions = [
    'cash',
    'mobile money',
    'transfert bancaire',
    'crédit',
    'partiel'
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadClients();
    _quantiteController.text = '1';
    _remiseGlobaleController.text = '0';
    _tvaGlobaleController.text = '0';
    _livraisonController.text = '0';
    _emballageController.text = '0';
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _montantRecuController.dispose();
    _remiseGlobaleController.dispose();
    _tvaGlobaleController.dispose();
    _livraisonController.dispose();
    _emballageController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await api.getAllProducts(token);

      if (res.statusCode == 200) {
        final body = res.data;
        setState(() {
          allProducts = (body["produits"] as List)
              .map((json) => ProductModel.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar("Échec du chargement des produits");
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  Future<void> _loadClients() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final res = await _clientApi.getClients(token);

      if (res.statusCode == 200) {
        final body = res.data;
        setState(() {
          allClients = (body["clients"] as List)
              .map((json) => ClientModel.fromJson(json))
              .toList();
        });
      } else {
        _showErrorSnackBar("Échec du chargement des clients");
      }
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      _handleGenericError(e);
    }
  }

  void _handleDioError(DioException e) {
    if (e.response != null && e.response?.statusCode == 403) {
      final errorMessage = e.response?.data['error'] ?? '';
      if (errorMessage.toString().contains("abonnement")) {
        _showSubscriptionExpiredDialog();
        return;
      }
    }
    _showErrorSnackBar("Problème de connexion : Vérifiez votre Internet.");
  }

  void _handleGenericError(dynamic e) {
    _showErrorSnackBar("Erreur: ${e.toString()}");
    debugPrint(e.toString());
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Abonnement expiré"),
        content:
            const Text("Votre abonnement a expiré. Veuillez le renouveler."),
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
  }

  void _ajouterAuPanier() async {
    if (selectedProducts.isEmpty) {
      _showErrorSnackBar("Veuillez sélectionner au moins un produit");
      return;
    }

    for (var produit in selectedProducts) {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _FormulaireProduitDialog(produit: produit),
      );

      if (result != null) {
        _addProductToCart(produit, result);
      }
    }
    selectedProducts.clear();
  }

  void _addProductToCart(ProductModel produit, Map<String, dynamic> result) {
    int qte = result["quantite"];
    int remise = result["remise"];
    String remiseType = result["remiseType"];
    int tva = result["tva"];
    int fraisLivraison = result["fraisLivraison"];
    int fraisEmballage = result["fraisEmballage"];
    int prixInitial = produit.isPromo ? produit.prixPromo : produit.prixVente;

    final item = ProductItemModel(
      productId: produit.id,
      nom: produit.nom,
      image: produit.image,
      prixAchat: produit.prixAchat,
      prixUnitaire: prixInitial,
      quantite: qte,
      // sousTotal: sousTotalFinal,
      stocks: produit.stocks,
      remise: remise,
      remiseType: remiseType,
      isPromo: produit.isPromo,
      prixVente: produit.prixVente,
      tva: tva,
      fraisLivraison: fraisLivraison,
      fraisEmballage: fraisEmballage,
    );

    setState(() {
      panier.add(item);
      // total = panier.fold(0, (sum, p) => sum + p.sousTotal);
      total = _estimerTotalPanier(); // visuel seulement
    });
  }

  int _estimerTotalPanier({
    bool useGlobalTVA = false,
    bool useGlobalRemise = false,
    int tvaGlobale = 0,
    int remiseGlobale = 0,
    String remiseType = 'fcfa',
    int livraison = 0,
    int emballage = 0,
  }) {
    double totalProduits = 0;

    for (var p in panier) {
      int prix = p.prixUnitaire;

      if (p.remiseType == 'fcfa') {
        prix -= p.remise!;
      } else if (p.remiseType == 'pourcent') {
        prix -= (prix * p.remise! ~/ 100);
      }
      if (prix < 0) prix = 0;

      int brut = prix * p.quantite;
      double tva = (p.tva! > 0) ? (brut * p.tva! / 100) : 0;

      totalProduits +=
          brut + tva + (p.fraisLivraison ?? 0) + (p.fraisEmballage ?? 0);
    }

    // 1. Ajouter frais globaux AVANT remise globale et TVA
    double totalHT = totalProduits + livraison + emballage;

    // 2. Appliquer remise globale
    if (useGlobalRemise) {
      if (remiseType == 'pourcent') {
        totalHT -= (totalHT * remiseGlobale / 100);
      } else {
        totalHT -= remiseGlobale;
      }
    }

    // 3. Appliquer TVA globale
    if (useGlobalTVA && tvaGlobale > 0) {
      totalHT += (totalHT * tvaGlobale / 100);
    }

    return totalHT.round();
  }

  Future<void> _validerVente(BuildContext context) async {
    if (panier.isEmpty) {
      _showErrorSnackBar("Votre panier est vide");
      return;
    }

    if (!_validateStockAvailability()) return;
    if (!_validateClientForCreditSales()) return;

    final venteMap = _prepareVenteData();
    if (venteMap == null) return; // Ne pas continuer si données invalides
    final response = await venteApi.postOrders(
        venteMap, Provider.of<AuthProvider>(context, listen: false).token);
    if (!context.mounted)
      return; // vérifie que le widget est encore dans l’arbre
    if (response.statusCode == 201) {
      _handleSuccessfulSale(context, response.data['vente']);
    } else {
      if (!context.mounted)
        return; // vérifie que le widget est encore dans l’arbre
      _showErrorSnackBar("Échec de l'enregistrement de la vente");
    }
  }

  bool _validateStockAvailability() {
    for (var item in panier) {
      if (item.stocks! < item.quantite) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Stock insuffisant",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            content: Text("Le stock de ${item.nom} est insuffisant.",
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        );
        return false;
      }
    }
    return true;
  }

  bool _validateClientForCreditSales() {
    int montantRecu = int.tryParse(_montantRecuController.text) ?? 0;
    final totalAmount = total;

    if (montantRecu < totalAmount && selectedClient == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Client requis",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(
              "Pour une vente à crédit ou un paiement partiel, vous devez sélectionner un client.",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return false;
    }
    return true;
  }

  Map<String, dynamic>? _prepareVenteData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    int montantRecu = int.tryParse(_montantRecuController.text) ?? 0;
    int livraison = int.tryParse(_livraisonController.text) ?? 0;
    int emballage = int.tryParse(_emballageController.text) ?? 0;
    int reste =
        total - montantRecu; //(total + livraison + emballage) - montantRecu;
    reste = reste < 0 ? 0 : reste;

    String statut = "payée";
    if (montantRecu > 0 && montantRecu < total //(total + livraison + emballage)
        ) {
      statut = "partiel";
    } else if (montantRecu == 0) {
      statut = "crédit";
    }

    // Validation du mode de paiement
    String paymentMode = selectedPaiement;
    if (paymentMode.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Avertissement",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Veuillez sélectionner un mode de paiement",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return null;
      // throw ArgumentError("Veuillez sélectionner un mode de paiement");
    }

    // Cohérence mode paiement/montant
    if ((paymentMode == "cash" || paymentMode == "mobile_money") &&
        montantRecu < total) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Avertissement",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text(
              "Le paiement $paymentMode nécessite un montant reçu supérieur ou égale au total ",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return null;
      // throw ArgumentError("Le paiement $paymentMode nécessite un montant reçu > 0");
    }

    if (paymentMode == "crédit" && montantRecu > 0) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Avertissement",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                content: Text(
                    "Le mode crédit ne peut pas avoir de montant reçu",
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  )
                ],
              ));
      return null;
      // throw ArgumentError("Le mode crédit ne peut pas avoir de montant reçu");
    }

    if (paymentMode == "partiel" && montantRecu <= 0) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Avertissement",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                content: Text(
                    "Le mode partiel doit avoir au moins quelque montant reçu",
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  )
                ],
              ));
      return null;
      // throw ArgumentError("Le mode crédit ne peut pas avoir de montant reçu");
    }

    // Validation client pour crédit/partiel
    String clientName = selectedClient?.nom ?? nomController.text;
    if ((statut == "crédit" || statut == "partiel") && clientName.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Avertissement",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Nom client requis pour les ventes en crédit/partiel",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return null;
      // throw ArgumentError("Nom client requis pour les ventes en crédit/partiel");
    }

    String clientContact = selectedClient?.contact ?? contactController.text;
    String clientAddress =
        selectedClient?.clientAdresse ?? adresseController.text;

    if ((montantRecu < total) && clientName.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Avertissement",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Nom client requis pour crédit/partiel",
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
      return null;
      // throw Exception("Nom client requis pour crédit/partiel");
    }
    return {
      "userId": authProvider.userId,
      "adminId": authProvider.adminId,
      "clientId": selectedClient?.id,
      "nom": clientName,
      "contactClient": clientContact,
      "client_address": clientAddress,
      "produits": panier.map((e) => e.toJson()).toList(),
      "total": total,
      "montant_recu": montantRecu,
      "remiseGlobale": int.tryParse(_remiseGlobaleController.text) ?? 0,
      "remiseGlobaleType": _remiseGlobaleType,
      "tvaGlobale": int.tryParse(_tvaGlobaleController.text) ?? 0,
      "livraison": livraison,
      "emballage": emballage,
      "monnaie": montantRecu > total ? (montantRecu - total) : 0,
      "reste": reste,
      "type_paiement": paymentMode,
      "statut": statut,
      "operateur": authProvider.userName,
      "date": DateTime.now().toIso8601String(),
    };
  }

  void _handleSuccessfulSale(BuildContext context, dynamic venteData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("✅ Vente enregistrée !"),
        content: const Text("Souhaitez-vous voir/imprimer le reçu ?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RecuVenteScreen(data: venteData),
                ),
              );
            },
            child: const Text("Apperçu du reçu"),
          ),
          TextButton(
            onPressed: () {
              _resetForm();
              Navigator.pop(context);
            },
            child: const Text("Annuler"),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      panier.clear();
      total = 0;
      _montantRecuController.clear();
      selectedClient = null;
      selectedPaiement = 'cash';
      _remiseGlobaleController.text = '0';
      _remiseGlobaleType = 'fcfa';
      _tvaGlobaleController.text = '0';
      _livraisonController.text = '0';
      _emballageController.text = '0';
      selectedProducts.clear();
    });
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
        automaticallyImplyLeading: false,
        title: Text(
          "Point de vente",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.blueGrey,
        elevation: 2,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
            ),
          );
        },
      ),
    );
  }

// AFFICHAGE MOBILE
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Section Produits
          _buildProductSelectionSection(),
          const SizedBox(height: 16),

          // Section Panier
          _buildCartSection(),
          const SizedBox(height: 16),

          // Section Paiement
          _buildPaymentSection(),
        ],
      ),
    );
  }

//AFFICHAGE DESKTOP
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Colonne gauche - Produits et Panier
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildProductSelectionSection(),
              const SizedBox(height: 16),
              Expanded(child: _buildCartSection()),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Colonne droite - Paiement
        Expanded(
          flex: 1,
          child: SingleChildScrollView(child: _buildPaymentSection()),
        ),
      ],
    );
  }

  Widget _buildProductSelectionSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Sélecteur de produits
        GestureDetector(
          onTap: _ouvrirModalSelectionProduit,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 10 : 12,
              vertical: isMobile ? 12 : 16,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  selectedProducts.isNotEmpty
                      ? Icons.check_circle
                      : Icons.add_shopping_cart,
                  color: selectedProducts.isNotEmpty
                      ? Colors.green
                      : Colors.blue.shade700,
                  size: isMobile ? 24 : 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selectedProducts.isNotEmpty
                        ? "${selectedProducts.length} produit(s) sélectionné(s)"
                        : "Choisir un ou plusieurs produits",
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        /// Bouton Ajouter au panier
        isMobile
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _ajouterAuPanier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.shopify_outlined,
                      size: 22, color: Colors.white),
                  label: Text(
                    "Ajouter au panier",
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : ElevatedButton.icon(
                onPressed: _ajouterAuPanier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                icon: const Icon(Icons.shopify_outlined,
                    size: 26, color: Colors.white),
                label: Text(
                  "Ajouter au panier",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildCartSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: panier.isEmpty
          ? Center(
              child: Text(
              "Panier vide",
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.normal),
            ))
          : ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: panier.length,
              itemBuilder: (context, index) {
                final item = panier[index];
                return _buildCartItem(item, index);
              },
            ),
    );
  }

  Widget _buildCartItem(ProductItemModel item, int index) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0.01,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 5),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Image + Infos
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        item.image ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nom,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (item.isPromo) ...[
                                  Text(
                                    "${item.prixVente} Fcfa",
                                    style: GoogleFonts.poppins(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${item.prixUnitaire} Fcfa",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    "${item.prixVente} Fcfa",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  /// Boutons +/- centrés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _updateCartItemQuantity(item, index, -1),
                      ),
                      Text('${item.quantite}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green),
                        onPressed: () =>
                            _updateCartItemQuantity(item, index, 1),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    item.image ?? '',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.nom,
                            style: GoogleFonts.poppins(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (item.isPromo) ...[
                              Text(
                                "${item.prixVente} Fcfa",
                                style: GoogleFonts.poppins(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${item.prixUnitaire} Fcfa",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ] else ...[
                              Text(
                                "${item.prixVente} Fcfa",
                                style: GoogleFonts.poppins(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.red),
                        onPressed: () =>
                            _updateCartItemQuantity(item, index, -1),
                      ),
                      Text('${item.quantite}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline,
                            color: Colors.green),
                        onPressed: () =>
                            _updateCartItemQuantity(item, index, 1),
                      ),
                    ],
                  )
                ],
              ),
      ),
    );
  }

  void _updateCartItemQuantity(ProductItemModel item, int index, int change) {
    if (change < 0 && item.quantite == 1) {
      setState(() {
        panier.removeAt(index);
        total = _estimerTotalPanier();
      });
      return;
    }

    if (change > 0 && item.quantite >= item.stocks!) {
      _showErrorSnackBar("Stock insuffisant pour ${item.nom}");
      return;
    }

    setState(() {
      item.quantite += change;
      total = _estimerTotalPanier();
    });
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Total: $total Fcfa",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Sélection client
        GestureDetector(
          onTap: _ouvrirModalSelectionClient,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                      selectedClient != null
                          ? selectedClient!.nom
                          : "Choisir un client (optionnel)",
                      style: GoogleFonts.roboto(
                          fontSize: 14, fontWeight: FontWeight.normal)),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blue),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (selectedClient == null)
          Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => isActive = !isActive),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                          isActive
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text("Ajouter un client manuellement",
                            style: GoogleFonts.roboto(fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
              if (isActive)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  // padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        style: GoogleFonts.roboto(
                            fontSize: 14, fontWeight: FontWeight.normal),
                        controller: nomController,
                        decoration: InputDecoration(
                          labelText: "Nom complet",
                          labelStyle: GoogleFonts.roboto(
                              fontSize: 14, fontWeight: FontWeight.normal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: GoogleFonts.roboto(
                            fontSize: 14, fontWeight: FontWeight.normal),
                        controller: contactController,
                        decoration: InputDecoration(
                            labelText: "Téléphone ",
                            labelStyle: GoogleFonts.roboto(
                                fontSize: 14, fontWeight: FontWeight.normal)),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        style: GoogleFonts.roboto(
                            fontSize: 14, fontWeight: FontWeight.normal),
                        controller: adresseController,
                        decoration: InputDecoration(
                            labelText: "Adresse",
                            labelStyle: GoogleFonts.roboto(
                                fontSize: 14, fontWeight: FontWeight.normal)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        // Mode de paiement
        DropdownButtonFormField<String>(
          value: selectedPaiement,
          decoration: InputDecoration(
              labelText: "Mode de paiement",
              labelStyle: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.normal)),
          items: modePaiementOptions
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e,
                      style: GoogleFonts.roboto(
                          fontSize: 16, fontWeight: FontWeight.normal))))
              .toList(),
          onChanged: (val) => setState(() => selectedPaiement = val!),
        ),
        const SizedBox(height: 16),

        // Montant reçu
        TextField(
          style:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal),
          controller: _montantRecuController,
          decoration: InputDecoration(
              labelText: "Montant reçu",
              labelStyle: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.normal)),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Remise globale
        Row(
          children: [
            Expanded(
              child: TextField(
                style: GoogleFonts.roboto(
                    fontSize: 16, fontWeight: FontWeight.normal),
                controller: _remiseGlobaleController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Remise globale",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 16, fontWeight: FontWeight.normal)),
                onChanged: (val) => recalculerTotal(),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _remiseGlobaleType,
              items: ['fcfa', 'pourcent']
                  .map((v) => DropdownMenuItem(
                      value: v,
                      child: Text(v,
                          style: GoogleFonts.roboto(
                              fontSize: 16, fontWeight: FontWeight.normal))))
                  .toList(),
              onChanged: (v) => setState(() {
                _remiseGlobaleType = v!;
                recalculerTotal();
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // TVA globale
        TextField(
          style:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal),
          controller: _tvaGlobaleController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: "TVA globale (%)",
              labelStyle: GoogleFonts.roboto(
                  fontSize: 14, fontWeight: FontWeight.normal)),
          onChanged: (val) => recalculerTotal(),
        ),
        const SizedBox(height: 16),

        // Frais livraison
        TextField(
          style:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal),
          controller: _livraisonController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: "Frais livraison (Fcfa)",
              labelStyle: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.normal)),
          onChanged: (val) => recalculerTotal(),
        ),
        const SizedBox(height: 16),

        // Frais emballage
        TextField(
          style:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal),
          controller: _emballageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: "Frais emballage (Fcfa)",
              labelStyle: GoogleFonts.roboto(
                  fontSize: 16, fontWeight: FontWeight.normal)),
          onChanged: (val) => recalculerTotal(),
        ),
        const SizedBox(height: 24),

        // Bouton Valider
        ElevatedButton.icon(
          onPressed: () => _validerVente(context),
          icon: const Icon(
            Icons.check,
            size: 28,
            color: Colors.white,
          ),
          label: Text(
            "Valider la vente",
            style: GoogleFonts.roboto(
                fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  //recalcule pour affichage temporaire de mis a jours de total dans le front
  void recalculerTotal() {
    int remiseGlobale = int.tryParse(_remiseGlobaleController.text) ?? 0;
    int tvaGlobale = int.tryParse(_tvaGlobaleController.text) ?? 0;
    int livraison = int.tryParse(_livraisonController.text) ?? 0;
    int emballage = int.tryParse(_emballageController.text) ?? 0;

    int nouveauTotal = _estimerTotalPanier(
      useGlobalRemise: remiseGlobale > 0,
      useGlobalTVA: tvaGlobale > 0,
      remiseGlobale: remiseGlobale,
      tvaGlobale: tvaGlobale,
      remiseType: _remiseGlobaleType,
      livraison: livraison,
      emballage: emballage,
    );

    setState(() {
      total = nouveauTotal;
    });
  }

  void _ouvrirModalSelectionProduit() {
    // List<ProductModel> produitsFiltres = List.from(allProducts);
    List<ProductModel> produitsFiltres =
        allProducts.where((p) => p.statut != 'expire' && p.stocks > 0).toList();

    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 400;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Barre de recherche
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.normal,
                        ),
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: "Rechercher un produit...",
                          hintStyle: GoogleFonts.roboto(
                            fontSize: isMobile ? 13 : 14,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            produitsFiltres = allProducts
                                .where((prod) =>
                                    prod.nom
                                        .toLowerCase()
                                        .contains(value.toLowerCase()) &&
                                    prod.statut != "expiré" &&
                                    (prod.stocks > 0))
                                .toList();
                          });
                        },
                      ),
                    ),

                    /// Liste des produits
                    /// Liste des produits
                    Expanded(
                      child: produitsFiltres.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.inventory_2_outlined,
                                      color: Colors.grey, size: 60),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Aucun produit disponible pour le moment.",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.black54),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: produitsFiltres.length,
                              itemBuilder: (context, index) {
                                final product = produitsFiltres[index];
                                final isSelected =
                                    selectedProducts.contains(product);
                                return CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    setModalState(() {
                                      if (value == true) {
                                        selectedProducts.add(product);
                                      } else {
                                        selectedProducts.remove(product);
                                      }
                                    });
                                  },
                                  title: Text(
                                    product.nom,
                                    style: GoogleFonts.roboto(
                                      fontSize: isMobile ? 13 : 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if (product.isPromo) ...[
                                        Text(
                                          formatPrice.formatNombre(
                                              product.prixPromo.toString()),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.redAccent,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          formatPrice.formatNombre(
                                              product.prixVente.toString()),
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey,
                                            fontSize: isMobile ? 12 : 14,
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          formatPrice.formatNombre(
                                              product.prixVente.toString()),
                                          style: GoogleFonts.roboto(
                                            fontSize: isMobile ? 13 : 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  secondary: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      product.image ?? '',
                                      width: isMobile ? 35 : 40,
                                      height: isMobile ? 35 : 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                );
                              },
                            ),
                    ),

                    /// Bouton de validation
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          label: Text(
                            "Valider la sélection",
                            style: GoogleFonts.roboto(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _ouvrirModalSelectionClient() {
    List<ClientModel> clientsFiltres = List.from(allClients);
    TextEditingController searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isMobile = screenWidth < 400;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// Barre de recherche
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: searchController,
                        style: GoogleFonts.roboto(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: "Rechercher un client...",
                          hintStyle: GoogleFonts.roboto(
                            fontSize: isMobile ? 13 : 14,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setModalState(() {
                            clientsFiltres = allClients
                                .where((client) => client.nom
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                    ),

                    /// Liste des clients filtrés
                    Expanded(
                      child: ListView.builder(
                        itemCount: clientsFiltres.length,
                        itemBuilder: (context, index) {
                          final client = clientsFiltres[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.person, size: 20),
                            ),
                            title: Text(
                              client.nom,
                              style: GoogleFonts.roboto(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              client.contact,
                              style: GoogleFonts.roboto(
                                fontSize: isMobile ? 12 : 13,
                                fontWeight: FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              setState(() {
                                selectedClient = client;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FormulaireProduitDialog extends StatefulWidget {
  final ProductModel produit;
  const _FormulaireProduitDialog({required this.produit});

  @override
  State<_FormulaireProduitDialog> createState() =>
      _FormulaireProduitDialogState();
}

class _FormulaireProduitDialogState extends State<_FormulaireProduitDialog> {
  final _qteCtrl = TextEditingController(text: "1");
  final _remiseCtrl = TextEditingController(text: "0");
  final _tvaCtrl = TextEditingController(text: "0");
  final _livraisonCtrl = TextEditingController(text: "0");
  final _emballageCtrl = TextEditingController(text: "0");
  String _remiseType = 'fcfa';

  @override
  void dispose() {
    _qteCtrl.dispose();
    _remiseCtrl.dispose();
    _tvaCtrl.dispose();
    _livraisonCtrl.dispose();
    _emballageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Détails pour ${widget.produit.nom}",
          style:
              GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.normal)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.normal),
                controller: _qteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Quantité",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.normal))),
            TextField(
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.normal),
                controller: _remiseCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Remise",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.normal))),
            DropdownButtonFormField<String>(
              value: _remiseType,
              items: ["fcfa", "pourcent"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _remiseType = val!),
              decoration: InputDecoration(
                  labelText: "Type de remise",
                  labelStyle: GoogleFonts.roboto(
                      fontSize: 14, fontWeight: FontWeight.normal)),
            ),
            TextField(
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.normal),
                controller: _tvaCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "TVA (%)",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.normal))),
            TextField(
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.normal),
                controller: _livraisonCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Frais de livraison",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.normal))),
            TextField(
                style: GoogleFonts.roboto(
                    fontSize: 14, fontWeight: FontWeight.normal),
                controller: _emballageCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: "Frais d'emballage",
                    labelStyle: GoogleFonts.roboto(
                        fontSize: 14, fontWeight: FontWeight.normal))),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Annuler",
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.blueAccent),
            )),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              "quantite": int.tryParse(_qteCtrl.text) ?? 1,
              "remise": int.tryParse(_remiseCtrl.text) ?? 0,
              "remiseType": _remiseType,
              "tva": int.tryParse(_tvaCtrl.text) ?? 0,
              "fraisLivraison": int.tryParse(_livraisonCtrl.text) ?? 0,
              "fraisEmballage": int.tryParse(_emballageCtrl.text) ?? 0,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
          child: Text(
            "Ajouter",
            style: GoogleFonts.roboto(
                fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
          ),
        )
      ],
    );
  }
}
