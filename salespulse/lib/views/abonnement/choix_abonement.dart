// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/paiement_mensuel_abonnement.dart';
import 'package:salespulse/views/abonnement/paiement_pro_abonement.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  bool _isLoading = false;
  final AbonnementApi _abonnementApi = AbonnementApi();

  Future<void> _souscrireAbonnement(String type) async {
    setState(() => _isLoading = true);

    // Afficher l'indicateur de chargement
    ScaffoldMessenger.of(context).showSnackBar(
      _buildLoadingSnackBar(),
    );

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await _abonnementApi.acheterAbonnement(
        context: context,
        type: type,
        montant: type == "essai" ? 0 : (type == "mensuel" ? 10000 : 25000),
        mode: "",
        token: token,
      );

      // Fermer le loader
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 201) {
        _showSuccessMessage(response.data['message']);
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      _handleSubscriptionError(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  SnackBar _buildLoadingSnackBar() {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      backgroundColor: Colors.blue[800],
      content: Row(
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(width: 15),
          Text(
            "Traitement en cours...",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ],
      ),
      duration: const Duration(minutes: 1),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.green,
        content: Text(
          "✅ $message",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleSubscriptionError(DioException e) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final errorMessage =
        e.response?.data['error'] ?? 'Échec de la souscription';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        content: Text(
          "Erreur : $errorMessage",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        duration: const Duration(seconds: 4),
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
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        "Nos offres d'abonnement",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHeaderText(),
          const SizedBox(height: 30),
          _buildFreeTrialCard(),
          const SizedBox(height: 25),
          _buildMonthlyCard(),
          const SizedBox(height: 25),
          _buildProCard(),
          const SizedBox(height: 20),
          _buildLegalNotice(),
          if (_isLoading) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Text(
      "Choisissez la formule qui correspond à vos besoins",
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildFreeTrialCard() {
    return _buildPlanCard(
      title: "Essai Gratuit",
      price: "0 FCFA",
      duration: "7 jours",
      color: const Color(0xFF4CAF50),
      features: const [
        "Accès à toutes les fonctionnalités",
        "Jusqu'à 50 produits",
        "1 utilisateur",
        "Support de base",
      ],
      isPopular: false,
      onPressed: () => _souscrireAbonnement("essai"),
    );
  }

  Widget _buildMonthlyCard() {
    return _buildPlanCard(
      title: "Mensuel",
      price: "10 000 FCFA",
      duration: "1 mois",
      color: const Color(0xFF2196F3),
      features: const [
        "Toutes les fonctionnalités Premium",
        "Produits illimités",
        "Jusqu'à 3 utilisateurs",
        "Support prioritaire",
        "Sauvegarde automatique",
      ],
      isPopular: false,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentAbonnementMensuelScreen(),
        ),
      ),

      //  () => _souscrireAbonnement("mensuel"),
    );
  }

  Widget _buildProCard() {
    return _buildPlanCard(
      title: "Professionnel",
      price: "25 000 FCFA",
      duration: "3 mois",
      color: const Color(0xFFFF9800),
      features: const [
        "Toutes les fonctionnalités Premium",
        "Produits illimités",
        "Jusqu'à 5 utilisateurs",
        "Support prioritaire",
        "Sauvegarde automatique",
        "Statistiques avancées",
      ],
      isPopular: true,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentAbonnementProScreen(),
        ),
      ),
    );
  }

  Widget _buildLegalNotice() {
    return Text(
      "Résiliation possible à tout moment. Aucun remboursement après paiement.",
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.only(top: 30),
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required Color color,
    required List<String> features,
    required bool isPopular,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isPopular) _buildPopularBadge(color),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: _buildCardBorderRadius(isPopular),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardHeader(title, duration, color),
                _buildPriceSection(price, title, color),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                ..._buildFeatureList(features, color),
                const SizedBox(height: 25),
                _buildSubscriptionButton(title, color, onPressed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularBadge(Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Text(
        "LE PLUS POPULAIRE",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  BorderRadius _buildCardBorderRadius(bool isPopular) {
    return BorderRadius.only(
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
      topLeft: Radius.circular(isPopular ? 0 : 16),
      topRight: Radius.circular(isPopular ? 0 : 16),
    );
  }

  Widget _buildCardHeader(String title, String duration, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            duration,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection(String price, String title, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          price,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title == "Essai Gratuit"
              ? "Sans engagement"
              : title == "Mensuel"
                  ? "Renouvellement mensuel"
                  : "Soit 8 333 FCFA/mois",
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureList(List<String> features, Color color) {
    return features
        .map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }

  Widget _buildSubscriptionButton(
      String title, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title == "Essai Gratuit"
              ? "Commencer l'essai"
              : "Choisir cette offre",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
