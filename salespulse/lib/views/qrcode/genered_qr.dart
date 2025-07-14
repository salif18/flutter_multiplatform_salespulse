import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:salespulse/utils/app_size.dart';

class GeneredQRCode extends StatefulWidget {
  const GeneredQRCode({super.key});

  @override
  State<GeneredQRCode> createState() => _GeneredQRCodeState();
}

class _GeneredQRCodeState extends State<GeneredQRCode> {
  String? qrData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff001c30),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xff001c30),
            leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  size: AppSizes.iconLarge,
                  color: Colors.orange,
                )),
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Generer QR Code",
                  style: GoogleFonts.roboto(
                      fontSize: AppSizes.fontLarge, color: Colors.orange)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextFormField(
                    onFieldSubmitted: (value) {
                      setState(() {
                        qrData = value;
                      });
                    },
                    decoration: const InputDecoration(
                        // Bordure quand le TextField est activé
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 2.0, color: Colors.orange),
                        ),
                        // Bordure quand le TextField est focus
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(width: 3.0, color: Colors.orange),
                        ),
                        filled: true,
                        fillColor: Color.fromARGB(255, 230, 230, 230),
                        labelStyle: TextStyle(
                            fontFamily: "roboto",
                            color: Color.fromARGB(255, 0, 0, 0)),
                        hintText: 'Entrer un donnée pour generer un code QR',
                        hintStyle: TextStyle(
                            fontFamily: "roboto",
                            color: Color.fromARGB(255, 65, 65, 65))),
                  ),
                  const SizedBox(height: 20),
                  if (qrData != null)
                    Container(
                      alignment: Alignment.center,
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          borderRadius: BorderRadius.circular(20)),
                      child: QrImageView(
                        backgroundColor: Colors.orange,
                        data: qrData!,
                        size: 200.0, // Taille du QR code
                        version: QrVersions.auto,
                        gapless: false,
                      ),
                    )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
