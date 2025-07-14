import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesVentes {
   Dio dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(milliseconds: 60000),  // 15 secondes
    receiveTimeout: const Duration(milliseconds: 60000),  // 15 secondes
  ),
);

//AJOUTER DES COMMANDES
  Future<Response> postOrders(Map<String, dynamic> data, String token) async {
    var uri = "$domaineName/ventes";
    return await dio.post(
      uri,
      data: data,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      ),
    );
  }

  //obtenir depenses
getAllVentes(
  String token, {
  String? clientId,
  String? dateDebut,
  String? dateFin,
}) async {
  final uri = Uri.parse('$domaineName/ventes').replace(queryParameters: {
    if (clientId != null) 'clientId': clientId,
    if (dateDebut != null) 'dateDebut': dateDebut,
    if (dateFin != null) 'dateFin': dateFin,
  });

  return await dio.get(
    uri.toString(),
    options: Options(headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token"
    }),
  );
}



  //delete
  deleteVentes(id, token) async {
    var uri = "$domaineName/ventes/single/$id";
    return await http.delete(
      Uri.parse(uri),
      headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
      },
    );
  }

  //messade d'affichage de reponse de la requette recus
  void showSnackBarSuccessPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400)),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
          label: "",
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }),
    ));
  }

//messade d'affichage des reponse de la requette en cas dechec
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 255, 35, 19),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: "",
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }
}
