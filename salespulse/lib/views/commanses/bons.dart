// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/commande_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/commande_api.dart';
import 'package:salespulse/views/commanses/create_bon.dart';
import 'package:salespulse/views/commanses/details_bon.dart';

class CommandeListPage extends StatefulWidget {
  const CommandeListPage({super.key});

  @override
  State<CommandeListPage> createState() => _CommandeListPageState();
}

class _CommandeListPageState extends State<CommandeListPage> {
  List<CommandeModel> commandes = [];
  List<CommandeModel> commandesFiltrees = [];
  String? selectedStatut;
  bool isLoading = true;

  final List<String> statuts = ["Tous", "En attente", "Reçue", "Annulée"];

  @override
  void initState() {
    super.initState();
    fetchCommandes();
  }

  Future<void> fetchCommandes() async {
    setState(() => isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      var response = await ServicesCommande().getCommande(token);
      if (response.statusCode == 200) {
        setState(() {
          commandes = (response.data['commandes'] as List)
              .map((e) => CommandeModel.fromJson(e))
              .toList();
          commandesFiltrees = commandes;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement: $e");
    }

    setState(() => isLoading = false);
  }

  void filtrerCommandes(String? statut) {
    setState(() {
      selectedStatut = statut;
      if (statut == null || statut == "Tous") {
        commandesFiltrees = commandes;
      } else {
        commandesFiltrees = commandes.where((c) => c.statut == statut).toList();
      }
    });
  }

  Color getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'reçue':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  double calculerTotal(CommandeModel c) {
    double total = 0;
    for (var item in c.produits) {
      total += (item.prixAchat * item.quantite);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blueGrey,
        title: Text(
          "Commandes fournisseurs",
          style: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8.0),
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Wrap(
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButton<String>(
                    hint: const Text("Filtrer"),
                    value: selectedStatut,
                    onChanged: filtrerCommandes,
                    items: statuts.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 50),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(400, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusGeometry.circular(5))),
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateOrderScreen(),
                        ),
                      );

                      if (result == true) {
                        fetchCommandes(); // Recharge les commandes si la création a réussi
                      }
                    },
                    icon: const Icon(Icons.add, size: 28, color: Colors.white),
                    label: Text(
                      "Créer un bon",
                      style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: isLoading
                  ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.orange, size: 50))
                  : commandesFiltrees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/images/not_data.png",
                                  width: 200, height: 200, fit: BoxFit.cover),
                              const SizedBox(height: 20),
                              Text("Aucun bon de commande pour le momment.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                  )),
                            ],
                          ),
                        )
                      : LayoutBuilder(builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.grey[50],
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowHeight: 35,
                                  headingTextStyle: const TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold),
                                  headingRowColor: MaterialStateProperty.all(
                                      Colors.grey.shade300),
                                  columns: [
                                    DataColumn(
                                        label: Text(
                                      'N° Commande'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Fournisseur'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Date'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Produits'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Total (FCFA)'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Statut'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                    DataColumn(
                                        label: Text(
                                      'Détails'.toUpperCase(),
                                      style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    )),
                                  ],
                                  rows: commandesFiltrees.map((c) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(c.id,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                        DataCell(Text(c.fournisseurName,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                        DataCell(Text(c.date.split("T").first,
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                        DataCell(Text('${c.produits.length}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                        DataCell(Text('${calculerTotal(c)}',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500))),
                                        DataCell(
                                          Text(
                                            c.statut,
                                            style: TextStyle(
                                              color: getStatutColor(c.statut),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_red_eye,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            onPressed: () {
                                              // Naviguer vers détails commande
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailsCommandePage(
                                                              commande: c)));
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }))
        ],
      ),
    );
  }
}
