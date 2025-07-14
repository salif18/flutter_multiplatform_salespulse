import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';
import 'package:salespulse/models/mouvements_model_pro.dart';
const String domaineName = Domaine.domaineURI;
class ServicesMouvements {
  final Dio dio = Dio();
  var uri = "$domaineName/mouvements";

  Future<Map<String, dynamic>> getMouvements({
    required String adminId,
    required String token,
    required String productId,
    String? type,
    DateTime? dateDebut,
    DateTime? dateFin,
    int page = 1,
    int limit = 20,
  }) async {
    Map<String, dynamic> queryParameters = {
      "productId": productId,
      "page": page.toString(),
      "limit": limit.toString(),
    };

    if (type != null && type.isNotEmpty) {
      queryParameters["type"] = type;
    }
    if (dateDebut != null) {
      queryParameters["dateDebut"] = dateDebut.toIso8601String();
    }
    if (dateFin != null) {
      queryParameters["dateFin"] = dateFin.toIso8601String();
    }

    final response = await dio.get(
      uri,
      queryParameters: queryParameters,
      options: Options(headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"}),
    );

    if (response.statusCode == 200) {
      List mouvementsJson = response.data["mouvements"];
      List<MouvementModel> mouvements = mouvementsJson
          .map((json) => MouvementModel.fromJson(json))
          .toList();

      Map<String, dynamic> pagination = response.data["pagination"];

      return {
        "mouvements": mouvements,
        "pagination": pagination,
      };
    } else {
      throw Exception("Erreur de chargement des mouvements");
    }
  }
}
