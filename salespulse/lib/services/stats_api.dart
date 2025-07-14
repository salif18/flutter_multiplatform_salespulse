import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesStats {
  //obtenir depenses
   Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );


  getStatsGenerales(selectedMonth,token)async{
    var uri = "$domaineName/stats?mois=$selectedMonth";
    return await dio.get(uri,
      options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  Future<Response> getVentesDuJour(String token) async {
  var uri = "$domaineName/stats/jour";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesHebdomadaires(String token) async {
  var uri = "$domaineName/stats/semaine";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getVentesAnnee(String token) async {
  var uri = "$domaineName/stats/annee";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getClientRetard(String token) async {
  var uri = "$domaineName/stats/clients-en-retard";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

Future<Response> getOperationUser(String token, periode, userId) async {
  var uri = "$domaineName/stats/operations-utilisateur?periode=$periode&userId=$userId";
  return await dio.get(uri,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      }));
}

//message en cas de succès!
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
        },
      ),
    ));
  }

  //message en cas d'erreur!
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400)),
      backgroundColor: Colors.redAccent,
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
