class MouvementModel {
  final String id;
  final String productId;
  final String productNom;
  final String userId;
  final String type;
  final int quantite;
  final int prixAchat;
  final int ancienStock;
  final int nouveauStock;
  final String description;
  final DateTime date;

  MouvementModel({
    required this.id,
    required this.productId,
    required this.productNom,
    required this.userId,
    required this.type,
    required this.quantite,
    required this.prixAchat,
    required this.ancienStock,
    required this.nouveauStock,
    required this.description,
    required this.date,
  });

  factory MouvementModel.fromJson(Map<String, dynamic> json) {
    return MouvementModel(
      id: json['_id'] ?? '',
      productId: json['productId'] != null ? json['productId']['_id'] ?? '' : '',
      productNom: json['productId'] != null ? json['productId']['nom'] ?? '' : '',
      userId: json['userId'] != null ? json['userId']['_id'] ?? '' : '',
      type: json['type'] ?? '',
      quantite: json['quantite'] ?? 0,
      prixAchat:  json["prix_achat"] ?? 0,
      ancienStock: json['ancien_stock'] ?? 0,
      nouveauStock: json['nouveau_stock'] ?? 0,
      description: json['description'] ?? '',
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
