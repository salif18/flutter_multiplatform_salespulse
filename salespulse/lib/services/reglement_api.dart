import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';

const String domaineName = Domaine.domaineURI;

class ServicesReglements {
  Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(milliseconds: 15000), // 15 secondes
      receiveTimeout: const Duration(milliseconds: 15000), // 15 secondes
    ),
  );

  //ajouter de categorie pour formulaire
  postReglements(data, token) async {
    var uri = "$domaineName/reglements";
    return await dio.post(uri,
        data: data,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //obtenir categorie pour formulaire
  getReglements(token) async {
    var uri = "$domaineName/reglements";
    return await dio.get(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }

  //supprimer categorie
  deleteReglements(id, token) async {
    var uri = "$domaineName/reglements/single/$id";
    return await dio.delete(uri,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        ));
  }
}