// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class PaymentAbonnementMensuelScreen extends StatelessWidget {
  const PaymentAbonnementMensuelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Vérification automatique de l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await authProvider.checkAuth()) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Abonnement Mensuel",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec badge Mensuel
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[400],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "MENSUEL",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "1 mois",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Titre principal
              Text(
                "Solution flexible pour votre business",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Accédez aux fonctionnalités essentielles",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 25),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 25),

              // Liste des avantages
              _buildFeatureItem("📊 Statistiques de base",
                  "Suivez vos performances commerciales principales"),
              _buildFeatureItem(
                  "🛒 Stock étendu", "Gérez jusqu'à 500 produits"),
              _buildFeatureItem(
                  "📁 Backup cloud", "Sauvegarde automatique quotidienne"),
              _buildFeatureItem(
                  "👥 Travail d'équipe", "Jusqu'à 3 utilisateurs simultanés"),
              _buildFeatureItem(
                  "🔐 Sécurité standard", "Protection des données de base"),

              const SizedBox(height: 30),

              // Carte de prix
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue[400]!,
                      Colors.blue[300]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      "INVESTISSEMENT",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "10 000 FCFA",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "renouvellement mensuel",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bouton d'action principal
              _buildMainActionButton(context),

              const SizedBox(height: 15),

              // Bouton d'essai gratuit
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AbonnementScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "Essai gratuit de 7 jours",
                    style: GoogleFonts.poppins(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: GoogleFonts.poppins(fontSize: 18)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  icon.substring(3),
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[400],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: () => _showPaymentConfirmation(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              "SOUSCRIRE À L'ABONNEMENT",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_outlined,
                color: Colors.blue,
                size: 50,
              ),
              const SizedBox(height: 15),
              Text(
                "Confirmer l'abonnement",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                "Vous êtes sur le point de souscrire à l'abonnement Mensuel pour 10 000 FCFA.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Annuler",
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[400],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showPaymentMethodBottomSheet(context);
                      },
                      child: Text(
                        "Confirmer",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodBottomSheet(BuildContext context) {
    final paymentOptions = [
      {
        'id': 'orange',
        'name': 'Orange Money',
        'image': "assets/images/orange.jpg",
        'color': Colors.orange,
      },
      {
        'id': 'mobicash',
        'name': 'MobiCash',
        'image': "assets/images/moov.webp",
        'color': Colors.blue,
      },
    ];

    // Variable pour suivre la sélection
    String? selectedMethod;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choisissez votre méthode de paiement',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Liste des méthodes
                  ...paymentOptions.map((method) {
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          selectedMethod = method['id'] as String;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: selectedMethod == method['id']
                              ? Colors.blue[50]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedMethod == method['id']
                                ? Colors.blue[400]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: ListTile(
                          leading: Image.asset(method['image'] as String,
                              width: 50, height: 50),
                          title: Text(
                            method['name'] as String,
                            style: GoogleFonts.poppins(),
                          ),
                          trailing: Radio<String>(
                            value: method['id'] as String,
                            groupValue: selectedMethod,
                            activeColor: Colors.blue[400],
                            onChanged: (value) {
                              setModalState(() {
                                selectedMethod = value;
                              });
                            },
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Bouton de paiement
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedMethod != null
                            ? Colors.blue[400]
                            : Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: selectedMethod != null
                          ? () => _processPaymentSelection(
                                context,
                                selectedMethod!,
                                setModalState,
                              )
                          : null,
                      child: Text(
                        'Payer 10 000 FCFA',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processPaymentSelection(
    BuildContext context,
    String method,
    Function setModalState,
  ) async {
    setModalState(() {}); // Force le refresh UI

    final api = AbonnementApi();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      // 1. Afficher le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.blue[400],
          content: Row(
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(width: 15),
              Text(
                "Initialisation du paiement...",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ],
          ),
        ),
      );

      // // 2. Sélection du service
      // dynamic paymentService;
      // if (method == 'orange') {
      //   paymentService = OrangeMoneyService();
      // } else {
      //   paymentService = MobiCashService();
      // }

      // // 3. Initier le paiement
      // final orderId = 'ABO-${DateTime.now().millisecondsSinceEpoch}';
      // final paymentUrl = await paymentService.initierPaiement(
      //   amount: 10000,
      //   orderId: orderId,
      // );

      // if (paymentUrl == null) throw Exception("Impossible d'initialiser le paiement");

      // // 4. Ouvrir l'application de paiement
      // if (!await launchUrl(
      //   Uri.parse(paymentUrl),
      //   mode: LaunchMode.externalApplication,
      // )) {
      //   throw Exception("Impossible d'ouvrir l'application");
      // }

      // 5. Enregistrer la transaction (simplifié)
      await api.acheterAbonnement(
        context: context,
        type: "mensuel",
        montant: 10000,
        mode: method,
        token: token,
      );

      // 6. Fermer le bottom sheet
      Navigator.pop(context);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 7. Afficher le succès
      _showSuccessDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Paiement réussi!",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Votre abonnement Mensuel a été activé avec succès.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    // Fermer d'abord ce dialogue
                    Navigator.of(_, rootNavigator: true).pop();
                    // Puis fermer éventuellement d'autres écrans si nécessaire
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    "Explorer les fonctionnalités",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
