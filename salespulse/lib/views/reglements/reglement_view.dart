// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/reglement_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/reglement_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class HistoriqueReglementsScreen extends StatefulWidget {
  const HistoriqueReglementsScreen({super.key});

  @override
  State<HistoriqueReglementsScreen> createState() =>
      _HistoriqueReglementsScreenState();
}

class _HistoriqueReglementsScreenState
    extends State<HistoriqueReglementsScreen> {
  List<ReglementModel> reglements = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchReglements();
  }

  Future<void> _fetchReglements() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final response = await ServicesReglements().getReglements(token);
      if (response.statusCode == 200) {
        if(!context.mounted)return ;
        setState(() {
          reglements = (response.data["reglements"] as List)
              .map((json) => ReglementModel.fromJson(json))
              .toList();
          loading = false;
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
            title: Text("Historique des règlements",
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.black)),
            backgroundColor: Colors.white //const Color(0xff001c30),
            ),
        body: loading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
            : reglements.isEmpty
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
                : SingleChildScrollView(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(16),
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: Container(
                              color: Colors.white,
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
                                      label: Expanded(
                                          child: Text("Nom".toUpperCase(),
                                              style: GoogleFonts.roboto(
                                                fontSize: 13,
                                                color: Colors.white,
                                              )))),
                                  DataColumn(
                                      label: Text("Montant".toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ))),
                                  DataColumn(
                                      label: Text("Type".toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ))),
                                  DataColumn(
                                      label: Text("Mode".toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ))),
                                  DataColumn(
                                      label: Text("Date".toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ))),
                                  DataColumn(
                                      label: Text("Opérateur".toUpperCase(),
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: Colors.white,
                                          ))),
                                ],
                                rows: reglements.map((r) {
                                  return DataRow(cells: [
                                    DataCell(Text(r.nom,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black))),
                                    DataCell(Text("${r.montant} Fcfa",
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black))),
                                    DataCell(Text(
                                      r.type,
                                      style: TextStyle(
                                          color: r.type == "règlement"
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataCell(Text(r.mode,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black))),
                                    DataCell(Text(
                                        DateFormat('dd/MM/yyyy').format(r.date),
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black))),
                                    DataCell(Text(r.operateur,
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.black))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ));
  }
}
