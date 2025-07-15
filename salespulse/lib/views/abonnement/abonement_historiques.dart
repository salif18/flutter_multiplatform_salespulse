// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/abonnement_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/abonnement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
import 'package:salespulse/views/abonnement/historique_paiement_abonnement.dart';

class AbonnementHistoriquePage extends StatefulWidget {
  const AbonnementHistoriquePage({super.key});

  @override
  State<AbonnementHistoriquePage> createState() =>
      _AbonnementHistoriquePageState();
}

class _AbonnementHistoriquePageState extends State<AbonnementHistoriquePage> {
  List<HistoriqueAbonnement> historiques = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    chargerHistorique();
  }

  Future<void> chargerHistorique() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final api = AbonnementApi();
      final res = await api.getHistoriqueAbonnement(context, token);
      setState(() {
        historiques = res;
        loading = false;
      });
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

  String formatDate(DateTime date) {
    return DateFormat.yMMMMd('fr_FR').format(date);
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
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    
    return   WillPopScope(
      onWillPop: () async {
        // Cette partie garantit un retour propre
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
            size: 20, 
            color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Historique des abonnements",
          style: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        HistoriquePaiementPage(token: token))),
            child: Text(
              'Mes paiement',
              style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
          const SizedBox(
            width: 20,
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : historiques.isEmpty
              ? const Center(child: Text("Aucun abonnement trouvé."))
              : ListView.builder(
                  itemCount: historiques.length,
                  itemBuilder: (context, index) {
                    final item = historiques[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          item.type == "premium"
                              ? Icons.star
                              : Icons.lock_clock,
                          color: item.type == "premium"
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        title: Text("Abonnement ${item.type.toUpperCase()}"),
                        subtitle: Text(
                          "Du ${formatDate(item.debut)} au ${formatDate(item.fin)}\nStatut : ${item.statut}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AbonnementScreen())),
        tooltip: "Réabonner",
        icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white),
        label: Text(
          "Réabonnement",
          style: GoogleFonts.roboto(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    )
    );
  }
}
