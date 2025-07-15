// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class RecuVenteScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const RecuVenteScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final produits = List<Map<String, dynamic>>.from(data["produits"]);
    final currencyFormat =
        NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA');

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Reçu de Vente",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.blue),
            onPressed: () =>
                _generateInvoicePdf(data, produits, currencyFormat),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.deepOrange),
            onPressed: () => Navigator.pop(context),
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
                      ...produits.map(
                          (item) => _buildProductItem(item, currencyFormat)),
                      const Divider(thickness: 1.2),
                      const SizedBox(height: 16),
                      _sectionTitle("🧾 Récapitulatif"),
                      const SizedBox(height: 8),
                      _buildSummarySection(data, produits, currencyFormat),
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

  Widget _buildProductItem(
      Map<String, dynamic> item, NumberFormat currencyFormat) {
    return Padding(
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
            Text("${item['nom'] ?? '-'} x${item['quantite'] ?? 0}",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                "Prix unitaire : ${currencyFormat.format(item['prix_unitaire'] ?? 0)}",
                style: _detailStyle()),
            if ((item['remise'] ?? 0) > 0)
              Text(
                  "Remise : ${item['remise'] ?? 0} ${item['remiseType'] == 'pourcent' ? '%' : 'FCFA'}",
                  style: _detailStyle()),
            if ((item['tva'] ?? 0) > 0)
              Text("TVA : ${item['tva'] ?? 0}%", style: _detailStyle()),
            Text(
                "Sous-total : ${currencyFormat.format(item['sous_total'] ?? 0)}",
                style: _detailStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> data,
      List<Map<String, dynamic>> produits, NumberFormat currencyFormat) {
    final double sousTotalBrut =
        produits.fold(0, (sum, item) => sum + (item['sous_total'] ?? 0));
    final reste = (data['reste'] ?? 0) > 0 ? data['reste'] : 0;

    return Column(
      children: [
        _info("Sous-total brut", currencyFormat.format(sousTotalBrut)),
        if ((data['remiseGlobale'] ?? 0) > 0)
          _info("Remise globale",
              "${data['remiseGlobale']} ${data['remiseGlobaleType'] == 'pourcent' ? '%' : 'FCFA'}"),
        if ((data['tvaGlobale'] ?? 0) > 0)
          _info("TVA globale", "${data['tvaGlobale']}%"),
        if ((data['livraison'] ?? 0) > 0)
          _info("Frais de livraison", currencyFormat.format(data['livraison'])),
        if ((data['emballage'] ?? 0) > 0)
          _info("Frais d'emballage", currencyFormat.format(data['emballage'])),
        const Divider(),
        _info("💰 Total à payer", currencyFormat.format(data['total'] ?? 0),
            bold: true, color: Colors.blueAccent),
        _info("💵 Montant reçu",
            currencyFormat.format(data['montant_recu'] ?? 0)),
        if ((data['monnaie'] ?? 0) > 0)
          _info("💸 Monnaie rendue", currencyFormat.format(data['monnaie'])),
        if (reste > 0)
          _info("❗ Reste à payer", currencyFormat.format(reste),
              bold: true, color: Colors.redAccent),
        _info("Mode de paiement", data['type_paiement'] ?? '-'),
      ],
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
      return DateFormat("dd/MM/yyyy à HH'h'mm").format(date);
    } catch (_) {
      return "-";
    }
  }

  Future<void> _generateInvoicePdf(Map<String, dynamic> data,
      List<Map<String, dynamic>> produits, NumberFormat currencyFormat) async {
    final pdf = pw.Document();

    // 1. Calcul du Total HT
    final double totalHT = produits.fold(
        0, (sum, p) => sum + (p['prix_unitaire'] * p['quantite']));

    // 2. Calcul TVA selon le mode (produit/global)
    double totalTVA = 0;
    double totalTTC = 0;

    // Mode TVA par produit
    if (data['tvaGlobale'] == null || data['tvaGlobale'] == 0) {
      totalTVA = produits.fold(0, (sum, p) {
        final tvaProduit = p['tva'] ?? 0;
        return sum + ((p['prix_unitaire'] * p['quantite'] * tvaProduit) / 100);
      });
    }
    // Mode TVA globale
    else {
      totalTVA = (totalHT * data['tvaGlobale']) / 100;
    }

    totalTTC = totalHT + totalTVA;

    // 3. Application de la remise globale si elle existe
    if ((data['remiseGlobale'] ?? 0) > 0) {
      if (data['remiseGlobaleType'] == 'pourcent') {
        totalTTC -= totalTTC * data['remiseGlobale'] / 100;
      } else {
        totalTTC -= data['remiseGlobale'];
      }
    }

    // 4. Ajout des frais supplémentaires
    totalTTC += (data['livraison'] ?? 0) + (data['emballage'] ?? 0);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(24),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('RECU DE VENTE',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("N°: ${data['facture_number']}",
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text("Date: ${_formatDate(data['date'])}",
                          style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Informations client
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("CLIENT",
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text("Nom: ${data['nom'] ?? '-'}"),
                    if (data['contactClient'] != null)
                      pw.Text("Contact: ${data['contactClient']}"),
                      if (data['client_address'] != null)
                      pw.Text("Addresse: ${data['client_address']}"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau des produits
              pw.Text("DÉTAIL DES ARTICLES",
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Désignation",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Qté",
                            textAlign: pw.TextAlign.center,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("P.U",
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text("Montant HT",
                            textAlign: pw.TextAlign.right,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...produits.map((p) {
                    final prixHT = p['prix_unitaire'];
                    // final montantTVA = (prixHT * p['quantite'] * (p['tva'] ?? 0)) / 100;
                    final totalHT = prixHT * p['quantite'];

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(p['nom']),
                              if ((p['remise'] ?? 0) > 0)
                                pw.Text(
                                  "Remise: ${p['remise']} ${p['remiseType'] == 'pourcent' ? '%' : 'FCFA'}",
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey600),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(p['quantite'].toString(),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(currencyFormat.format(prixHT),
                              textAlign: pw.TextAlign.right),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(currencyFormat.format(totalHT),
                              textAlign: pw.TextAlign.right),
                        ),
                      ],
                    );
                  })
                ],
              ),
              pw.SizedBox(height: 20),

              // Section Totaux
              pw.Container(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    // Total HT
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text("Total HT : ",
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFormat.format(totalHT)),
                      ],
                    ),

                    // Total TVA (si applicable)
                    if (totalTVA > 0) pw.SizedBox(height: 5),
                    if (totalTVA > 0)
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("TVA : ",
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text(currencyFormat.format(totalTVA)),
                        ],
                      ),

                    // Remise Globale (si applicable)
                    if ((data['remiseGlobale'] ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Remise Globale: "),
                          pw.Text(
                              "${data['remiseGlobale']} ${data['remiseGlobaleType'] == 'pourcent' ? '%' : 'FCFA'}",
                              style:
                                  const pw.TextStyle(color: PdfColors.green)),
                        ],
                      ),
                    ],

                    // Livraison (si applicable)
                    if ((data['livraison'] ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Frais de Livraison: ", style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.Text(currencyFormat.format(data['livraison'])),
                        ],
                      ),
                    ],

                    // Emballage (si applicable)
                    if ((data['emballage'] ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Frais d'Emballage: ", style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.Text(currencyFormat.format(data['emballage'])),
                        ],
                      ),
                    ],

                     // Total TTC
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text("Total TTC: ",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(currencyFormat.format(totalTTC),
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),

                    // Montant Net à Payer
                    pw.SizedBox(height: 10),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue700),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text("NET À PAYER: ",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 16)),
                              pw.Text(currencyFormat.format(data['total']),
                                  style: const pw.TextStyle(
                                      fontSize: 16, color: PdfColors.blue700)),
                            ],
                          ),

                          // Détails de paiement
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Text("Montant Reçu: ",
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  currencyFormat.format(data['montant_recu'])),
                            ],
                          ),

                          // Monnaie Rendue
                          if ((data['monnaie'] ?? 0) > 0)
                            pw.SizedBox(height: 4),
                          if ((data['monnaie'] ?? 0) > 0)
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text("Monnaie Rendue: ",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(currencyFormat.format(data['monnaie'])),
                              ],
                            ),

                          // Reste à Payer
                          if (data["reste"] > 0) pw.SizedBox(height: 4),
                          if (data["reste"] > 0)
                            pw.Row(
                              mainAxisSize: pw.MainAxisSize.min,
                              children: [
                                pw.Text("Reste à Payer: ",
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red)),
                                pw.Text(currencyFormat.format(data["reste"]),
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColors.red)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Pied de page
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Mode de Paiement: ${data['type_paiement']}"),
                  pw.Text("Statut: ${data['statut']}"),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text("Merci pour votre confiance !",
                  style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic, fontSize: 12)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) => pdf.save());
  }
}

// // ignore_for_file: depend_on_referenced_packages, deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:provider/provider.dart';
// import 'package:salespulse/providers/auth_provider.dart';

// class RecuVenteScreen extends StatelessWidget {
//   final Map data;

//   const RecuVenteScreen({super.key, required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     // Vérification automatique de l'authentification
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!await authProvider.checkAuth()) {
//         Navigator.pushReplacementNamed(context, '/login');
//       }
//     });

//     if (authProvider.isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     final produits = List<Map<String, dynamic>>.from(data["produits"]);

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: Colors.white, //const Color(0xff001c30),
//         title: Text("Reçu de Vente",
//             style: GoogleFonts.poppins(
//                 color: Colors.black, fontWeight: FontWeight.w600)),
//         actions: [
//           IconButton(
//             icon: const Icon(
//               Icons.print,
//               color: Colors.blue,
//             ),
//             onPressed: () async {
//               // Impression
//               await generateInvoicePdf(
//                 data: data as Map<String, dynamic>, // contient tous les champs
//                 produits: List<Map<String, dynamic>>.from(data['produits']),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(
//               Icons.cancel,
//               color: Colors.deepOrange,
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Center(
//           child: SizedBox(
//             width: 800,
//             child: Card(
//               elevation: 6,
//               color: Colors.white,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12)),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _sectionTitle("Informations Client et Vente"),
//                       const SizedBox(height: 8),
//                       _info("👤 Client", data['nom']),
//                       if (data["contactClient"] != null)
//                         _info("📞 Contact", data['contactClient']),
//                       _info("🧑‍💼 Vendeur", data['operateur']),
//                       _info("📅 Date", _formatDate(data["date"])),
//                       _info("🧾 Statut", data['statut']),
//                       const Divider(thickness: 1.2),
//                       const SizedBox(height: 16),
//                       _sectionTitle("🛒 Détails des produits"),
//                       const SizedBox(height: 8),
//                       ...produits.map((item) => Padding(
//                             padding: const EdgeInsets.only(bottom: 12),
//                             child: Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 border: Border.all(color: Colors.grey.shade300),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                       "${item['nom'] ?? '-'} x${item['quantite'] ?? 0}",
//                                       style: GoogleFonts.poppins(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w600)),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                       "Prix unitaire : ${item['prix_unitaire'] ?? 0} Fcfa",
//                                       style: _detailStyle()),
//                                   Text(
//                                       "Remise : ${item['remise'] ?? 0} ${item['remiseType'] == 'pourcent' ? '%' : 'Fcfa'}",
//                                       style: _detailStyle()),
//                                   Text("TVA : ${item['tva'] ?? 0}%",
//                                       style: _detailStyle()),
//                                   Text(
//                                       "Sous-total : ${item['sous_total'] ?? 0} Fcfa",
//                                       style: _detailStyle(
//                                           fontWeight: FontWeight.bold)),
//                                 ],
//                               ),
//                             ),
//                           )),
//                       const Divider(thickness: 1.2),
//                       const SizedBox(height: 16),
//                       _sectionTitle("🧾 Récapitulatif"),
//                       const SizedBox(height: 8),
//                       _info("Sous-total brut",
//                           "${_calculeSousTotalBrut(produits)} Fcfa"),
//                       _info("Remise globale",
//                           "${data['remiseGlobale'] ?? 0} ${data['remiseGlobaleType'] == 'pourcent' ? '%' : 'Fcfa'}"),
//                       _info("TVA globale", "${data['tvaGlobale'] ?? 0}%"),
//                       _info("Frais de livraison",
//                           "${data['livraison'] ?? 0} Fcfa"),
//                       _info("Frais d'emballage",
//                           "${data['emballage'] ?? 0} Fcfa"),
//                       const Divider(),
//                       _info("💰 Total à payer", "${data['total'] ?? 0} Fcfa",
//                           bold: true, color: Colors.blueAccent),
//                       _info("💵 Montant reçu",
//                           "${data['montant_recu'] ?? 0} Fcfa"),
//                       _info(
//                           "💸 Monnaie rendue", "${data['monnaie'] ?? 0} Fcfa"),
//                       if ((data["reste"] ?? 0) > 0)
//                         _info("❗ Reste à payer", "${data['reste'] ?? 0} Fcfa",
//                             bold: true, color: Colors.redAccent),
//                       _info("Mode de paiement", data['type_paiement'] ?? '-'),
//                       const SizedBox(height: 16),
//                       Center(
//                         child: Text("Merci pour votre achat !",
//                             style: GoogleFonts.poppins(
//                                 fontSize: 16, fontWeight: FontWeight.w600)),
//                       )
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _sectionTitle(String title) {
//     return Text(title,
//         style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold));
//   }

//   Widget _info(String label, dynamic value, {bool bold = false, Color? color}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: GoogleFonts.poppins(
//                   fontSize: 14, fontWeight: FontWeight.w500)),
//           Text(value?.toString() ?? '-',
//               style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   fontWeight: bold ? FontWeight.bold : FontWeight.normal,
//                   color: color)),
//         ],
//       ),
//     );
//   }

//   TextStyle _detailStyle({FontWeight fontWeight = FontWeight.normal}) {
//     return GoogleFonts.poppins(
//         fontSize: 13, fontWeight: fontWeight, color: Colors.black87);
//   }

//   String _formatDate(String isoDate) {
//     try {
//       final date = DateTime.parse(isoDate);
//       return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}";
//     } catch (_) {
//       return "-";
//     }
//   }

//   int _calculeSousTotalBrut(List<Map<String, dynamic>> produits) {
//     int total = 0;
//     for (var item in produits) {
//       total += (item['sous_total'] ?? 0) as int;
//     }
//     return total;
//   }

//   Future<void> generateInvoicePdf({
//     required Map<String, dynamic> data,
//     required List<Map<String, dynamic>> produits,
//   }) async {
//     final pdf = pw.Document();

//     final total = data['total'] ?? 0;
//     final montantRecu = data['montant_recu'] ?? 0;
//     final reste = data['reste'] ?? 0;
//     final monnaie = data['monnaie'] ?? 0;
//     DateTime.parse(data['date']);
//     final sousTotalBrut = _calculeSousTotalBrut(produits);

//     final remiseGlobale = data['remiseGlobale'] ?? 0;
//     final remiseGlobaleType =
//         data['remiseGlobaleType'] == 'pourcent' ? '%' : 'F';

//     final tvaGlobale = data['tvaGlobale'] ?? 0;
//     final livraison = data['livraison'] ?? 0;
//     final emballage = data['emballage'] ?? 0;
//     final modePaiement = data['type_paiement'] ?? '-';

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           return pw.Padding(
//             padding: const pw.EdgeInsets.all(24),
//             child: pw.Column(
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 // En-tête
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                   children: [
//                     pw.Text('Nom de ta boutique',
//                         style: pw.TextStyle(
//                             fontSize: 18, fontWeight: pw.FontWeight.bold)),
//                     pw.Text(data['typeDoc'] ?? "RECU",
//                         style: pw.TextStyle(
//                             fontSize: 20,
//                             fontWeight: pw.FontWeight.bold,
//                             color: PdfColors.blueGrey800)),
//                   ],
//                 ),
//                 pw.SizedBox(height: 8),
//                 pw.Text(
//                     "N° : ${data['_id']?.toString().substring(0, 4) ?? '-'}"),
//                 pw.SizedBox(height: 16),
//                 pw.Text("Client : ${data['nom'] ?? '-'}"),
//                 pw.Text("Contact : ${data['contactClient'] ?? '-'}"),
//                 pw.SizedBox(height: 8),
//                 pw.Text("Vendeur : ${data['operateur'] ?? '-'}"),
//                 pw.Text("Date : ${_formatDate(data['date'])}"),
//                 pw.Text("Statut : ${data['statut'] ?? '-'}"),
//                 pw.SizedBox(height: 16),
//                 pw.Divider(),

//                 // Tableau des produits
//                 pw.Table.fromTextArray(
//                   border: null,
//                   headers: [
//                     'Produit',
//                     'Qté',
//                     'PU',
//                     'Remise',
//                     'TVA',
//                     'Sous-total'
//                   ],
//                   data: produits.map((e) {
//                     return [
//                       e['nom'] ?? '-',
//                       '${e['quantite'] ?? 0}',
//                       '${e['prix_unitaire'] ?? 0} F',
//                       '${(e['remise'] ?? 0)} ${e['remise_type'] == 'pourcent' ? '%' : 'F'}',
//                       '${e['tva'] ?? 0}%',
//                       '${e['sous_total'] ?? 0} F',
//                     ];
//                   }).toList(),
//                   cellAlignment: pw.Alignment.centerLeft,
//                   headerStyle: pw.TextStyle(
//                       fontWeight: pw.FontWeight.bold, color: PdfColors.white),
//                   headerDecoration:
//                       const pw.BoxDecoration(color: PdfColors.blueGrey800),
//                 ),

//                 pw.SizedBox(height: 16),
//                 pw.Divider(),
//                 pw.SizedBox(height: 8),

//                 // Récapitulatif
//                 pw.Row(
//                   mainAxisAlignment: pw.MainAxisAlignment.end,
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Column(
//                       crossAxisAlignment: pw.CrossAxisAlignment.start,
//                       children: [
//                         pw.Text("Sous-total brut : $sousTotalBrut F",
//                             style:
//                                 pw.TextStyle(fontWeight: pw.FontWeight.bold)),
//                         if (remiseGlobale > 0)
//                           pw.Text(
//                               "Remise globale : $remiseGlobale $remiseGlobaleType"),
//                         if (tvaGlobale > 0)
//                           pw.Text("TVA globale : $tvaGlobale%"),
//                         if (livraison > 0)
//                           pw.Text("Frais de livraison : $livraison F"),
//                         if (emballage > 0)
//                           pw.Text("Frais d'emballage : $emballage F"),
//                         pw.SizedBox(height: 6),
//                         pw.Text("Total : $total F",
//                             style: pw.TextStyle(
//                                 fontWeight: pw.FontWeight.bold,
//                                 fontSize: 13,
//                                 color: PdfColors.blue800)),
//                         pw.Text("Montant reçu : $montantRecu F"),
//                         pw.Text("Monnaie rendue : $monnaie F"),
//                         if (reste > 0)
//                           pw.Text("Reste à payer : $reste F",
//                               style: pw.TextStyle(
//                                   color: PdfColors.red,
//                                   fontWeight: pw.FontWeight.bold)),
//                         pw.Text("Mode de paiement : $modePaiement"),
//                       ],
//                     )
//                   ],
//                 ),
//                 pw.SizedBox(height: 30),
//                 pw.Center(
//                   child: pw.Text("Merci pour votre achat !",
//                       style: pw.TextStyle(
//                           fontSize: 14, fontWeight: pw.FontWeight.bold)),
//                 )
//               ],
//             ),
//           );
//         },
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }
// }
