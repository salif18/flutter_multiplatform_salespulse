// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'package:salespulse/utils/app_size.dart';
// import 'package:salespulse/views/qrcode/genered_qr.dart';

// class QRScannerView extends StatefulWidget {
//   const QRScannerView({super.key});
  
//   @override
//   State<StatefulWidget> createState() => _QRScannerViewState();
// }

// class _QRScannerViewState extends State<QRScannerView> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   String? qrText;

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xff001c30),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff001c30),
//         leading: IconButton(
//           onPressed: () => Navigator.pop(context),
//           icon: const Icon(Icons.arrow_back_ios_rounded, size: AppSizes.iconLarge, color: Colors.orange),
//         ),
//         title: Text('Scanner QR Code', style: GoogleFonts.roboto(fontSize: AppSizes.fontLarge, color: Colors.orange)),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 5,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//               overlay: QrScannerOverlayShape(
//                 borderColor: Colors.orange,
//                 borderRadius: 10,
//                 borderLength: 30,
//                 borderWidth: 10,
//                 cutOutSize: 300,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text('Scanne un code QR', style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.orange)),
//                   const SizedBox(width: 20),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.push(context, MaterialPageRoute(builder: (context) => const GeneredQRCode()));
//                     },
//                     child: Text("Créer un code QR", style: GoogleFonts.roboto(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.orange)),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;

//     controller.scannedDataStream.listen((scanData) {
//       setState(() {
//         qrText = scanData.code;
//       });
//       _showDialog(scanData.code); // Afficher le dialogue avec le résultat scanné

//       // Arrêter le scan après la première détection pour éviter les doublons
//       controller.pauseCamera();
//     });
//   }

//   void _showDialog(String? scannedValue) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Code QR Scanné", style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold)),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Vous pouvez afficher une image ici si vous avez l'URL ou le contenu de l'image
//               // Exemple d'utilisation d'une image depuis un réseau
//               // Image.network('url_de_votre_image'),
//               const SizedBox(height: 20),
//               Text(scannedValue ?? 'Aucune valeur détectée', style: GoogleFonts.roboto(fontSize: 18)),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Fermer le dialogue
//               },
//               child: Text("Fermer", style: GoogleFonts.roboto(fontSize: 16)),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
