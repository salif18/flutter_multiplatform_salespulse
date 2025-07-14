// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/paiement_historique_api.dart';
// 🔁 importe ton service API

class HistoriquePaiementPage extends StatefulWidget {
  final String token;

  const HistoriquePaiementPage({super.key, required this.token});

  @override
  State<HistoriquePaiementPage> createState() => _HistoriquePaiementPageState();
}

class _HistoriquePaiementPageState extends State<HistoriquePaiementPage> {
  late Future<List<Map<String, dynamic>>> paiementsFuture;

  @override
  void initState() {
    super.initState();
    paiementsFuture = PaiementService().getPaiements(widget.token);
  }

  String formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(date);
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
      appBar: AppBar(
        title: Text(
          "Historique des paiements",
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: paiementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
                child: Text("Erreur ou aucun paiement trouvé."));
          }

          final paiements = snapshot.data!;
          return ListView.builder(
            itemCount: paiements.length,
            itemBuilder: (context, index) {
              final p = paiements[index];
              final montant = p['montant'] ?? 0;
              final type = p['type'] ?? '-';
              final moyen = p['moyen_paiement'] ?? 'inconnu';
              final statut = p['statut'] ?? '-';
              final date = formatDate(p['createdAt']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    type == 'premium'
                        ? Icons.workspace_premium
                        : Icons.access_time,
                    color: type == 'premium'
                        ? Colors.amber[800]
                        : Colors.grey[600],
                    size: 32,
                  ),
                  title: Text(
                    "${type.toUpperCase()} - ${montant.toStringAsFixed(0)} FCFA",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Moyen : $moyen"),
                      Text("Date : $date"),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      statut,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor:
                        statut == 'réussi' ? Colors.green : Colors.redAccent,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
