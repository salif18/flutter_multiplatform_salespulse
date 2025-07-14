class FournisseurModel {
  final String id;
  final String userId;
  final String prenom;
  final String nom;
  final int numero;
  final String address;
  final String produit;
  
  FournisseurModel(
      {required this.id,
      required this.userId,
      required this.prenom,
      required this.nom,
      required this.numero,
      required this.address,
      required this.produit});

  factory FournisseurModel.fromJson(Map<String, dynamic> json) {
    return FournisseurModel(
        id: json["_id"],
        userId: json["userId"],
        prenom: json["prenom"],
        nom: json["nom"],
        numero: json["numero"],
        address: json["address"],
        produit: json["produit"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "prenom": prenom,
      "nom": nom,
      "numero": numero,
      "address": address,
      "produit": produit
    };
  }
}
