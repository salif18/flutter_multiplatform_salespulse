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
    // Calcul prix unitaire après remise
    final double prixUnitaire = (item['prix_unitaire'] ?? 0).toDouble();
    final double remise = (item['remise'] ?? 0).toDouble();
    final String remiseType = item['remiseType'] ?? '';
    double prixApresRemise = prixUnitaire;

    if (remise > 0) {
      if (remiseType == 'pourcent') {
        prixApresRemise = prixUnitaire * (1 - remise / 100);
      } else {
        prixApresRemise = prixUnitaire - remise;
      }
    }

    final int quantite = item['quantite'] ?? 0;
    final double sousTotal = prixApresRemise * quantite;

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
            Text("${item['nom'] ?? '-'} x$quantite",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
                "Prix unitaire : ${currencyFormat.format(prixUnitaire)}",
                style: _detailStyle()),
            if (remise > 0)
              Text(
                  "Remise : $remise ${remiseType == 'pourcent' ? '%' : 'FCFA'}",
                  style: _detailStyle()),
            if ((item['tva'] ?? 0) > 0)
              Text("TVA : ${item['tva'] ?? 0}%", style: _detailStyle()),
            Text(
                "Sous-total : ${currencyFormat.format(sousTotal)}",
                style: _detailStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> data,
      List<Map<String, dynamic>> produits, NumberFormat currencyFormat) {
    // Calcul total HT en tenant compte des remises produits
    final double totalHT = produits.fold(0, (sum, p) {
      final double prixUnitaire = (p['prix_unitaire'] ?? 0).toDouble();
      final double remise = (p['remise'] ?? 0).toDouble();
      final String remiseType = p['remiseType'] ?? '';
      double prixApresRemise = prixUnitaire;

      if (remise > 0) {
        if (remiseType == 'pourcent') {
          prixApresRemise = prixUnitaire * (1 - remise / 100);
        } else {
          prixApresRemise = prixUnitaire - remise;
        }
      }

      final int quantite = p['quantite'] ?? 0;
      return sum + prixApresRemise * quantite;
    });

    final double tvaGlobale = (data['tvaGlobale'] ?? 0).toDouble();
    final double totalTVA = tvaGlobale > 0
        ? totalHT * tvaGlobale / 100
        : produits.fold(0, (sum, p) {
            final double prixUnitaire = (p['prix_unitaire'] ?? 0).toDouble();
            final double remise = (p['remise'] ?? 0).toDouble();
            final String remiseType = p['remiseType'] ?? '';
            double prixApresRemise = prixUnitaire;

            if (remise > 0) {
              if (remiseType == 'pourcent') {
                prixApresRemise = prixUnitaire * (1 - remise / 100);
              } else {
                prixApresRemise = prixUnitaire - remise;
              }
            }

            final int quantite = p['quantite'] ?? 0;
            final double tvaProduit = (p['tva'] ?? 0).toDouble();

            return sum + (prixApresRemise * quantite * tvaProduit / 100);
          });

    double totalTTC = totalHT + totalTVA;

    // Application remise globale si existante
    final double remiseGlobale = (data['remiseGlobale'] ?? 0).toDouble();
    final String remiseGlobaleType = data['remiseGlobaleType'] ?? '';

    if (remiseGlobale > 0) {
      if (remiseGlobaleType == 'pourcent') {
        totalTTC -= totalTTC * remiseGlobale / 100;
      } else {
        totalTTC -= remiseGlobale;
      }
    }

    totalTTC += (data['livraison'] ?? 0) + (data['emballage'] ?? 0);

    final reste = (data['reste'] ?? 0) > 0 ? data['reste'] : 0;

    return Column(
      children: [
        _info("Sous-total HT", currencyFormat.format(totalHT)),
        if (remiseGlobale > 0)
          _info("Remise globale",
              "$remiseGlobale ${remiseGlobaleType == 'pourcent' ? '%' : 'FCFA'}"),
        if (tvaGlobale > 0)
          _info("TVA globale", "$tvaGlobale%"),
        if ((data['livraison'] ?? 0) > 0)
          _info("Frais de livraison", currencyFormat.format(data['livraison'])),
        if ((data['emballage'] ?? 0) > 0)
          _info("Frais d'emballage", currencyFormat.format(data['emballage'])),
        const Divider(),
        _info("💰 Total TTC", currencyFormat.format(totalTTC),
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

    // Calcul du total HT avec remise produits
    final double totalHT = produits.fold(0, (sum, p) {
      final double prixUnitaire = (p['prix_unitaire'] ?? 0).toDouble();
      final double remise = (p['remise'] ?? 0).toDouble();
      final String remiseType = p['remiseType'] ?? '';
      double prixApresRemise = prixUnitaire;

      if (remise > 0) {
        if (remiseType == 'pourcent') {
          prixApresRemise = prixUnitaire * (1 - remise / 100);
        } else {
          prixApresRemise = prixUnitaire - remise;
        }
      }

      final int quantite = p['quantite'] ?? 0;
      return sum + prixApresRemise * quantite;
    });

    // Calcul TVA
    final double tvaGlobale = (data['tvaGlobale'] ?? 0).toDouble();
    double totalTVA = 0;
    if (tvaGlobale > 0) {
      totalTVA = totalHT * tvaGlobale / 100;
    } else {
      totalTVA = produits.fold(0, (sum, p) {
        final double prixUnitaire = (p['prix_unitaire'] ?? 0).toDouble();
        final double remise = (p['remise'] ?? 0).toDouble();
        final String remiseType = p['remiseType'] ?? '';
        double prixApresRemise = prixUnitaire;

        if (remise > 0) {
          if (remiseType == 'pourcent') {
            prixApresRemise = prixUnitaire * (1 - remise / 100);
          } else {
            prixApresRemise = prixUnitaire - remise;
          }
        }

        final int quantite = p['quantite'] ?? 0;
        final double tvaProduit = (p['tva'] ?? 0).toDouble();

        return sum + (prixApresRemise * quantite * tvaProduit / 100);
      });
    }

    double totalTTC = totalHT + totalTVA;

    // Application remise globale
    final double remiseGlobale = (data['remiseGlobale'] ?? 0).toDouble();
    final String remiseGlobaleType = data['remiseGlobaleType'] ?? '';

    if (remiseGlobale > 0) {
      if (remiseGlobaleType == 'pourcent') {
        totalTTC -= totalTTC * remiseGlobale / 100;
      } else {
        totalTTC -= remiseGlobale;
      }
    }

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
                  pw.Text('REÇU DE VENTE',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("N°: ${data['facture_number'] ?? '-'}",
                          style: const pw.TextStyle(fontSize: 12)),
                      pw.Text("Date: ${_formatDate(data['date'] ?? '')}",
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
                      pw.Text("Adresse: ${data['client_address']}"),
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
                    final double prixUnitaire = (p['prix_unitaire'] ?? 0).toDouble();
                    final double remise = (p['remise'] ?? 0).toDouble();
                    final String remiseType = p['remiseType'] ?? '';
                    double prixApresRemise = prixUnitaire;

                    if (remise > 0) {
                      if (remiseType == 'pourcent') {
                        prixApresRemise = prixUnitaire * (1 - remise / 100);
                      } else {
                        prixApresRemise = prixUnitaire - remise;
                      }
                    }

                    final int quantite = p['quantite'] ?? 0;
                    final double totalHT = prixApresRemise * quantite;

                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(p['nom'] ?? '-'),
                              if (remise > 0)
                                pw.Text(
                                  "Remise: $remise ${remiseType == 'pourcent' ? '%' : 'FCFA'}",
                                  style: const pw.TextStyle(
                                      fontSize: 10, color: PdfColors.grey600),
                                ),
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(quantite.toString(),
                              textAlign: pw.TextAlign.center),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(currencyFormat.format(prixUnitaire),
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
            
                     // Total TTC
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text("Total TTC: ",
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.Text(currencyFormat.format(totalHT + totalTVA),
                            style: const pw.TextStyle(fontSize: 14)),
                      ],
                    ),

                    // Livraison (si applicable)
                    if ((data['livraison'] ?? 0) > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Frais de Livraison: ",
                              style: pw.TextStyle(
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
                          pw.Text("Frais d'Emballage: ",
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.Text(currencyFormat.format(data['emballage'])),
                        ],
                      ),
                    ],
  
                     // Remise Globale (si applicable)
                    if (remiseGlobale > 0) ...[
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("Remise Globale: "),
                          pw.Text(
                              "$remiseGlobale ${remiseGlobaleType == 'pourcent' ? '%' : 'FCFA'}",
                              style:
                                  const pw.TextStyle(color: PdfColors.green)),
                        ],
                      ),
                    ],

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
                          if ((data["reste"] ?? 0) > 0) pw.SizedBox(height: 4),
                          if ((data["reste"] ?? 0) > 0)
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
               pw.Text(
                data['facture_footer'] ?? "Merci pour votre confiance !",
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  fontSize: 12,
                ),
                textAlign: data["footer_alignement"] == 'centre'
                    ? pw.TextAlign.center
                    : data["footer_alignement"] == 'droite'
                        ? pw.TextAlign.right
                        : pw.TextAlign.left,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) => pdf.save());
  }
}

