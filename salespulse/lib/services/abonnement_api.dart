import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/https/domaine.dart';
import 'package:salespulse/models/abonnement_model.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';
const String domaineName = Domaine.domaineURI;

class AbonnementApi {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000),
      receiveTimeout: const Duration(milliseconds: 15000),
    ),
  );

  // ✅ Appel pour acheter un abonnement
  acheterAbonnement({
    required BuildContext context,
    required String type, // "premium" ou "essai"
    required int montant,
    required String mode,
    required String token,
  }) async {
    var uri = "$domaineName/abonnements";

     return await dio.post(
        uri,
        data: {"type": type, "montant":montant, "moyen_paiement":mode},
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
      );
  }

// ✅ verifier abonnement actif 
verifierAbonnement(BuildContext context, String token) async {
  var uri = "$domaineName/abonnements/valability";
  
  try {
    return await dio.get(
      uri,
      options: Options(
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      ),
    );
  // ✅ Abonnement actif : ne rien faire ou retourner la réponse
  } on DioException catch (e) {
    if (e.response?.statusCode == 403 &&
        e.response!.data['error']
            .toString()
            .toLowerCase()
            .contains("abonnement est expiré")) {

      // ❗ D'abord fermer le dialog s'il y en a un ouvert
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Abonnement expiré"),
            content: const Text("Votre abonnement a expiré. Veuillez le renouveler pour continuer."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.pop(context); // Ferme la boîte de dialogue
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AbonnementScreen()),
                  );
                },
              )
            ],
          ),
        );
      }
    } else {
      // Pour toute autre erreur Dio
      debugPrint("Erreur : ${e.message}");
    }
  } catch (err) {
    debugPrint("Erreur inattendue : $err");
  }
}

   getHistoriqueAbonnement(BuildContext context, String token) async {
  var uri = "$domaineName/abonnements/historiques";

  try {
    final res = await dio.get(
      uri,
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
    );

    List data = res.data['historiques'];
    return data.map((e) => HistoriqueAbonnement.fromJson(e)).toList();
  } on DioException {
       ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text( "Problème de connexion : Vérifiez votre Internet.", style: GoogleFonts.poppins(fontSize: 14),)));

  } on TimeoutException {
     ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(  "Le serveur ne répond pas. Veuillez réessayer plus tard.",style: GoogleFonts.poppins(fontSize: 14),)));
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    debugPrint(e.toString());
  }
}
}
