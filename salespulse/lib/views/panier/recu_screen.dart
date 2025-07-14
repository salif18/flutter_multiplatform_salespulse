// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';

class RecuVenteScreen extends StatelessWidget {
  final Map data;

  const RecuVenteScreen({super.key, required this.data});

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
    final produits = List<Map<String, dynamic>>.from(data["produits"]);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white, //const Color(0xff001c30),
        title: Text("Reçu de Vente",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.print,
              color: Colors.blue,
            ),
            onPressed: () async {
              // Impression
              await generateInvoicePdf(
                data: data as Map<String, dynamic>, // contient tous les champs
                produits: List<Map<String, dynamic>>.from(data['produits']),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.cancel,
              color: Colors.deepOrange,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SizedBox(
            width: 800,
            child: Card(
              elevation: 6,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Informations Client et Vente"),
                      const SizedBox(height: 8),
                      _info("👤 Client", data['nom']),
                      if (data["contactClient"] != null)
                        _info("📞 Contact", data['contactClient']),
                      _info("🧑‍💼 Vendeur", data['operateur']),
                      _info("📅 Date", _formatDate(data["date"])),
                      _info("🧾 Statut", data['statut']),
                      const Divider(thickness: 1.2),
                      const SizedBox(height: 16),
                      _sectionTitle("🛒 Détails des produits"),
                      const SizedBox(height: 8),
                      ...produits.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "${item['nom'] ?? '-'} x${item['quantite'] ?? 0}",
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Prix unitaire : ${item['prix_unitaire'] ?? 0} Fcfa",
                                      style: _detailStyle()),
                                  Text(
                                      "Remise : ${item['remise'] ?? 0} ${item['remiseType'] == 'pourcent' ? '%' : 'Fcfa'}",
                                      style: _detailStyle()),
                                  Text("TVA : ${item['tva'] ?? 0}%",
                                      style: _detailStyle()),
                                  Text(
                                      "Sous-total : ${item['sous_total'] ?? 0} Fcfa",
                                      style: _detailStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          )),
                      const Divider(thickness: 1.2),
                      const SizedBox(height: 16),
                      _sectionTitle("🧾 Récapitulatif"),
                      const SizedBox(height: 8),
                      _info("Sous-total brut",
                          "${_calculeSousTotalBrut(produits)} Fcfa"),
                      _info("Remise globale",
                          "${data['remiseGlobale'] ?? 0} ${data['remiseGlobaleType'] == 'pourcent' ? '%' : 'Fcfa'}"),
                      _info("TVA globale", "${data['tvaGlobale'] ?? 0}%"),
                      _info("Frais de livraison",
                          "${data['livraison'] ?? 0} Fcfa"),
                      _info("Frais d'emballage",
                          "${data['emballage'] ?? 0} Fcfa"),
                      const Divider(),
                      _info("💰 Total à payer", "${data['total'] ?? 0} Fcfa",
                          bold: true, color: Colors.blueAccent),
                      _info("💵 Montant reçu",
                          "${data['montant_recu'] ?? 0} Fcfa"),
                      _info(
                          "💸 Monnaie rendue", "${data['monnaie'] ?? 0} Fcfa"),
                      if ((data["reste"] ?? 0) > 0)
                        _info("❗ Reste à payer", "${data['reste'] ?? 0} Fcfa",
                            bold: true, color: Colors.redAccent),
                      _info("Mode de paiement", data['type_paiement'] ?? '-'),
                      const SizedBox(height: 16),
                      Center(
                        child: Text("Merci pour votre achat !",
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _info(String label, dynamic value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value?.toString() ?? '-',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color)),
        ],
      ),
    );
  }

  TextStyle _detailStyle({FontWeight fontWeight = FontWeight.normal}) {
    return GoogleFonts.poppins(
        fontSize: 13, fontWeight: fontWeight, color: Colors.black87);
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "-";
    }
  }

  int _calculeSousTotalBrut(List<Map<String, dynamic>> produits) {
    int total = 0;
    for (var item in produits) {
      total += (item['sous_total'] ?? 0) as int;
    }
    return total;
  }

  Future<void> generateInvoicePdf({
    required Map<String, dynamic> data,
    required List<Map<String, dynamic>> produits,
  }) async {
    final pdf = pw.Document();

    final total = data['total'] ?? 0;
    final montantRecu = data['montant_recu'] ?? 0;
    final reste = data['reste'] ?? 0;
    final monnaie = data['monnaie'] ?? 0;
    DateTime.parse(data['date']);
    final sousTotalBrut = _calculeSousTotalBrut(produits);

    final remiseGlobale = data['remiseGlobale'] ?? 0;
    final remiseGlobaleType =
        data['remiseGlobaleType'] == 'pourcent' ? '%' : 'F';

    final tvaGlobale = data['tvaGlobale'] ?? 0;
    final livraison = data['livraison'] ?? 0;
    final emballage = data['emballage'] ?? 0;
    final modePaiement = data['type_paiement'] ?? '-';

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Nom de ta boutique',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(data['typeDoc'] ?? "RECU",
                        style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey800)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                    "N° : ${data['_id']?.toString().substring(0, 4) ?? '-'}"),
                pw.SizedBox(height: 16),
                pw.Text("Client : ${data['nom'] ?? '-'}"),
                pw.Text("Contact : ${data['contactClient'] ?? '-'}"),
                pw.SizedBox(height: 8),
                pw.Text("Vendeur : ${data['operateur'] ?? '-'}"),
                pw.Text("Date : ${_formatDate(data['date'])}"),
                pw.Text("Statut : ${data['statut'] ?? '-'}"),
                pw.SizedBox(height: 16),
                pw.Divider(),

                // Tableau des produits
                pw.Table.fromTextArray(
                  border: null,
                  headers: [
                    'Produit',
                    'Qté',
                    'PU',
                    'Remise',
                    'TVA',
                    'Sous-total'
                  ],
                  data: produits.map((e) {
                    return [
                      e['nom'] ?? '-',
                      '${e['quantite'] ?? 0}',
                      '${e['prix_unitaire'] ?? 0} F',
                      '${(e['remise'] ?? 0)} ${e['remise_type'] == 'pourcent' ? '%' : 'F'}',
                      '${e['tva'] ?? 0}%',
                      '${e['sous_total'] ?? 0} F',
                    ];
                  }).toList(),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey800),
                ),

                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 8),

                // Récapitulatif
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Sous-total brut : $sousTotalBrut F",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        if (remiseGlobale > 0)
                          pw.Text(
                              "Remise globale : $remiseGlobale $remiseGlobaleType"),
                        if (tvaGlobale > 0)
                          pw.Text("TVA globale : $tvaGlobale%"),
                        if (livraison > 0)
                          pw.Text("Frais de livraison : $livraison F"),
                        if (emballage > 0)
                          pw.Text("Frais d'emballage : $emballage F"),
                        pw.SizedBox(height: 6),
                        pw.Text("Total : $total F",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                                color: PdfColors.blue800)),
                        pw.Text("Montant reçu : $montantRecu F"),
                        pw.Text("Monnaie rendue : $monnaie F"),
                        if (reste > 0)
                          pw.Text("Reste à payer : $reste F",
                              style: pw.TextStyle(
                                  color: PdfColors.red,
                                  fontWeight: pw.FontWeight.bold)),
                        pw.Text("Mode de paiement : $modePaiement"),
                      ],
                    )
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Center(
                  child: pw.Text("Merci pour votre achat !",
                      style: pw.TextStyle(
                          fontSize: 14, fontWeight: pw.FontWeight.bold)),
                )
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
