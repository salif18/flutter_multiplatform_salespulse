// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/commande_model.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/commande_api.dart';


class DetailsCommandePage extends StatefulWidget {
  final CommandeModel commande; // ton modèle Commande

  const DetailsCommandePage({super.key, required this.commande});

  @override
  State<DetailsCommandePage> createState() => _DetailsCommandePageState();
}

class _DetailsCommandePageState extends State<DetailsCommandePage> {
   bool _isLoading = false;
   ServicesCommande api = ServicesCommande();

  Future<void> _validerCommande() async {
     final token = Provider.of<AuthProvider>(context, listen: false).token;
    setState(() => _isLoading = true);

    try {
  final response = await api.putCommande(widget.commande.id, token);

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande validée avec succès !')),
    );
    setState(() {
      widget.commande.statut = "reçue";
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.data["message"] ?? "Erreur inconnue.")),
    );
    throw Exception("Erreur: ${response.statusCode}");
  }
} catch (e) {
  String errorMessage = 'Erreur de validation inconnue';

  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('message')) {
      errorMessage = data['message'];
    } else if (data is String) {
      errorMessage = data;
    } else {
      errorMessage = e.message ?? 'Erreur Dio inconnue';
    }
  } else {
    errorMessage = e.toString();
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
} finally {
  setState(() => _isLoading = false);
}

  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.parse(widget.commande.date));
    final produits = widget.commande.produits as List;
    final double total = produits.fold<double>(
        0.0, (sum, item) => sum + (item.prixAchat * item.quantite));


    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(onPressed: ()=> Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18,color: Colors.white,)),
        title: Text("Détail Bon de Commande", style: GoogleFonts.poppins(fontSize: 16,fontWeight: FontWeight.w500)),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
         
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerBuild(context),
              _sectionTitle("Informations Fournisseur"),
              _infoRow("Nom", widget.commande.fournisseurName),
              _infoRow("Contact", widget.commande.fournisseurContact ?? "Non renseigné"),
              _infoRow("Adresse", widget.commande.fournisseurAddress ?? "Non renseignée"),
          
              const SizedBox(height: 20),
              _sectionTitle("Détails Commande"),
              _infoRow("Date", date),
              _infoRow("Statut", widget.commande.statut),
              const SizedBox(height: 10),
          
              _sectionTitle("Produits Commandés"),
              const SizedBox(height: 8),
              _buildProduitsTable(produits),
          
              const SizedBox(height: 20),
              _sectionTitle("Résumé"),
              _infoRow("Nombre d'articles", "${produits.length}"),
              _infoRow("Total", "${total.toStringAsFixed(0)} FCFA"),
          
              if ((widget.commande.notes ?? "").toString().trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionTitle("Notes"),
                Text(widget.commande.notes ?? "Aucune note", style: const TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerBuild(context){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
      child: Wrap(
        children: [
           if (widget.commande.statut != "reçue")
              ElevatedButton.icon(
                icon: _isLoading
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.check),
                label: const Text("Valider la commande"),
                onPressed: _isLoading ? null : _validerCommande,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                ),
              )
            else
              const Text("Commande déjà validée ✅", style: TextStyle(color: Colors.green)),
              const SizedBox(width: 20),
           ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              maximumSize: const Size(400, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(5)
              )
            ),
      icon: const Icon(Icons.print, color: Colors.white),
      label: Text("Imprimer",style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.white)),
      onPressed: () => _imprimerCommande(context),
        )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text("$label:".toUpperCase(), style: GoogleFonts.poppins(fontSize: 12,fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: GoogleFonts.poppins(fontSize: 14,color: Colors.black87,fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildProduitsTable(List produits) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(2),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.indigo.shade100),
            children: [
              Padding(padding: const EdgeInsets.all(8), child: Text("Image".toUpperCase(), style: GoogleFonts.roboto(fontSize: 12,color: Colors.grey[800],fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(8), child: Text("Nom".toUpperCase(), style: GoogleFonts.roboto(fontSize: 12,color: Colors.grey[800],fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(8), child: Text("Quantité".toUpperCase(), style: GoogleFonts.roboto(fontSize: 12,color: Colors.grey[800],fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(8), child: Text("Prix".toUpperCase(), style: GoogleFonts.roboto(fontSize: 12,color: Colors.grey[800],fontWeight: FontWeight.bold))),
              Padding(padding: const EdgeInsets.all(8), child: Text("Total".toUpperCase(), style: GoogleFonts.roboto(fontSize: 12,color: Colors.grey[800],fontWeight: FontWeight.bold))),
            ],
          ),
          ...produits.map((p) {
            final nomProduit = p.nom ?? 'Produit';
            final quantite = p.quantite;
            final prix = p.prixAchat;
            final total = prix * quantite;
            return TableRow(
              children: [
                            (p.image ?? "").isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "assets/images/defaultImg.png",
                                      width: 50,
                                      height: 50,
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.network(
                                      p.image!,
                                      width: 50,
                                      height: 50,
                                    ),
                                  ),
                          
              Padding(padding: const EdgeInsets.all(8), child: Text(nomProduit, style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.w500))),
              Padding(padding: const EdgeInsets.all(8), child: Text("$quantite", style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.w500))),
              Padding(padding: const EdgeInsets.all(8), child: Text("$prix", style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.w500))),
              Padding(padding: const EdgeInsets.all(8), child: Text("$total", style: GoogleFonts.poppins(fontSize: 14,fontWeight: FontWeight.w500))),
            ]);
          })
        ],
      ),
    );
  }

  void _imprimerCommande(BuildContext context) async {
  final pdf = pw.Document();
  final date = DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.parse(widget.commande.date));

  pdf.addPage(
    pw.Page(
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("BON DE COMMANDE", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text("Fournisseur: ${widget.commande.fournisseurName}"),
            pw.Text("Contact: ${widget.commande.fournisseurContact ?? 'N/A'}"),
            pw.Text("Adresse: ${widget.commande.fournisseurAddress ?? 'N/A'}"),
            pw.SizedBox(height: 10),
            pw.Text("Date: $date"),
            pw.Text("Statut: ${widget.commande.statut}"),
            if ((widget.commande.notes ?? "").isNotEmpty)
              pw.Text("Notes: ${widget.commande.notes}"),
            pw.SizedBox(height: 20),

            pw.Text("Produits commandés", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            // ignore: deprecated_member_use
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: ['Nom', 'Quantité', 'Prix', 'Total'],
              data: widget.commande.produits.map((p) {
                final total = p.quantite * p.prixAchat;
                return [
                  p.nom ?? '',
                  p.quantite.toString(),
                  "${p.prixAchat.toStringAsFixed(0)} FCFA",
                  "${total.toStringAsFixed(0)} FCFA"
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                "Total : ${widget.commande.total} FCFA",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
}
