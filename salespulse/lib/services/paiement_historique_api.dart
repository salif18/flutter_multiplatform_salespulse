import 'package:dio/dio.dart';
import 'package:salespulse/https/domaine.dart';
const String domaineName = Domaine.domaineURI;
class PaiementService {
  final Dio dio = Dio();

  Future<List<Map<String, dynamic>>> getPaiements(String token) async {
     var uri = "$domaineName/paiements/mes";

    try {
      final response = await dio.get(
        uri,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return List<Map<String, dynamic>>.from(response.data["paiements"]);
    } catch (e) {
      throw Exception("Erreur lors de la récupération des paiements");
    }
  }
  
  Future<List<Map<String, dynamic>>> postPaiements(data,String token) async {
    var uri = "$domaineName/paiements";
    try {
      final response = await dio.post(
        uri,
        data: data,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      return List<Map<String, dynamic>>.from(response.data["paiements"]);
    } catch (e) {
      throw Exception("Erreur lors de la récupération des paiements");
    }
  }
}
