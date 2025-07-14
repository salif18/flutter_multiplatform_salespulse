import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:salespulse/views/qrcode/genered_qr.dart';

class MobileScannerView extends StatefulWidget {
  const MobileScannerView({super.key});

  @override
  State<StatefulWidget> createState() => _MobileScannerViewState();
}

class _MobileScannerViewState extends State<MobileScannerView> {
  String? scannedData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff001c30), // Couleur de fond sombre
      appBar: AppBar(
        backgroundColor: const Color(0xff001c30),
        title: const Text(
          'Scanner QR Code',
          style: TextStyle(
            color: Colors.orange, // Couleur du texte en orange
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              controller: MobileScannerController(
                detectionSpeed: DetectionSpeed.noDuplicates, // Evite les doublons
                returnImage: true, // Retourne l'image capturée
              ),
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                final Uint8List? image = capture.image;

                for (final barcode in barcodes) {
                  setState(() {
                    scannedData = barcode.rawValue ?? 'Aucune donnée trouvée';
                  });
                }

                // Affiche l'image scannée si elle est disponible
                if (image != null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('QR Code Scanné'),
                      content: Image(image: MemoryImage(image)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: const Color(0xff001c30), // Même couleur de fond que le reste
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    scannedData != null
                        ? 'Résultat : $scannedData'
                        : 'Scanne un code QR',
                    style: const TextStyle(
                      color: Colors.orange, // Style du texte en orange
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 20),
                  TextButton(
                    onPressed: () {
                      // Action ou navigation vers une autre page
                       Navigator.push(context, MaterialPageRoute(builder: (context)=> const GeneredQRCode()));
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 12.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0)),
                      side: const BorderSide(color: Colors.orange, width: 2.0),
                    ),
                    child: Text(
                      'Créer un code QR',
                      style: GoogleFonts.roboto(
                        color: Colors.orange,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
