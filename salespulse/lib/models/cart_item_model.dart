class CartItemModel {
  dynamic productId;
  String image;
  String nom;
  String categories;
  int prixAchat;
  int prixVente;
  int qty;
  int stocks;


  CartItemModel(
      {required this.productId,
      required this.image,
      required this.nom,
      required this.categories,
      required this.prixAchat,
      required this.prixVente,
      required this.qty,
      required this.stocks,
      });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
        productId: json["_id"],
        image: json["image"],
        nom: json["nom"],
        categories: json["categories"],
        prixAchat: json["prix_achat"],
        prixVente: json["prix_vente"],
        qty: json["qty"],
        stocks: json["stocks"],
        );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": productId,
      "image": image,
      "nom": nom,
      "categories": categories,
      "prix_achat": prixAchat,
      "prix_vente": prixVente,
      "qty": qty,
      "stocks": stocks,
    };
  }
}
