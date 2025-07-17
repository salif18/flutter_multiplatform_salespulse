import "dart:convert";

import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

import "package:http/http.dart" as http;
import 'package:dio/dio.dart';
import "package:salespulse/https/domaine.dart";

const String domaineName = Domaine.domaineURI;

class ServicesAuth {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 100000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 100000), // 15 secondes
    ),
  );

  // fonction de connection
  postLoginUser(data) async {
    var url = "$domaineName/auth/login";
    return await http.post(Uri.parse(url), body: jsonEncode(data), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer "
    });
  }

   //obtenir categorie pour formulaire
  getUsers(token) async {
    var uri = "$domaineName/auth/utilisateurs";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

// fonction de creation de compte
  postRegistreUser(data) async {
    var url = "$domaineName/auth/registre";
    return await http.post(Uri.parse(url), body: jsonEncode(data), headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer "
    });
  }

//fontion de modification de passeword
  postUpdateUser(data, token) async {
    var uri = "$domaineName/auth/update_user";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );
  }

  //fontion de modification de passeword
  postUpdatePassword(data, token) async {
    var uri = "$domaineName/auth/update_password";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );
  }

  //fontion de reinitialisation de password
  postResetPassword(data) async {
    var uri = "$domaineName/reset/reset_token";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer "},
    );
  }

  //fontion de validation de mot de password reinitialiser
  postValidatePassword(data) async {
    var uri = "$domaineName/reset/reset_valid";
    return await http.post(
      Uri.parse(uri),
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer "},
    );
  }

  //message en cas de succès!
  void showSnackBarSuccessPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 255, 157, 11),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: "",
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ));
  }

   //obtenir categorie pour formulaire
  deleteAdminCounts(token) async {
    var uri = "$domaineName/auth/admin-compte";
    return await dio.delete(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //message en cas d'erreur!
  void showSnackBarErrorPersonalized(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message,
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400)),
      backgroundColor: const Color.fromARGB(255, 32, 19, 54),
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
