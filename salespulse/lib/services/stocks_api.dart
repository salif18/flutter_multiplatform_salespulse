import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesStocks {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );

  //ajouter depense
  postNewProduct(data, token) async {
    var uri = "$domaineName/products";
    return await dio.post(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

    //ajouter depense
  updateProduct(FormData data, String token, String id) async {
  var uri = "$domaineName/products/single/$id";
  return await dio.put(
    uri,
    data: data,
    options: Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'multipart/form-data', // Important pour FormData
      },
    ),
  );
}
  //ajouter depense
  updateStockProduct(data, token, id) async {
    var uri = "$domaineName/products/stocks/$id";
    return await dio.put(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //obtenir depenses
  getAllProducts(token) async {
    var uri = "$domaineName/products";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //delete
  deleteProduct(id, token) async {
    var uri = "$domaineName/products/single/$id";
    return await http.delete(
      Uri.parse(uri),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );
  }


saveHistoriqueInventaire(data, String token) async {
  Dio dio = Dio();
   var uri = "$domaineName/inventaire-historiques/save";
    return await dio.post(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
}

 //obtenir depenses
  getHistoriqueInventaire(token) async {
    var uri = "$domaineName/inventaire-historiques";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
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
      backgroundColor: Colors.red,
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
