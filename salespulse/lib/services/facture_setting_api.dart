
import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesFactures {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );


  updateFactureSettings(data, token) async {
    var uri = "$domaineName/facture/settings";
    return await dio.put(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //obtenir categorie pour formulaire
  getFactureSettings(token) async {
    var uri = "$domaineName/facture/settings";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //supprimer categorie
  deleteFactureSettings(id, token) async {
    var uri = "$domaineName/facture/settings/$id";
    return await dio.delete(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }
}