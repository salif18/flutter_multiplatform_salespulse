class HistoriqueInventaireModel {
  final String userId;
  final String nom;
  final int stockSysteme;
  final int stockReel;
  final int ecart;
  final DateTime date;
  final String operateur;
  final String motif;
  final String productId;

  HistoriqueInventaireModel({
    required this.userId,
    required this.nom,
    required this.stockSysteme,
    required this.stockReel,
    required this.ecart,
    required this.date,
    required this.operateur,
    required this.motif,
    required this.productId,
  });

  factory HistoriqueInventaireModel.fromJson(Map<String, dynamic> json) {
    return HistoriqueInventaireModel(
      userId: json['userId'] ?? "",
      nom: json['nom']  ?? "",
      stockSysteme: json['stock_systeme']  ?? "",
      stockReel: json['stock_reel']  ?? "",
      ecart: json['ecart']  ?? "",
      date:  DateTime.parse(json["date"]  ?? ""),
      operateur: json['operateur']  ?? "",
      motif: json['motif'],
      productId: json['productId']  ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "nom": nom,
      "stock_systeme": stockSysteme,
      "stock_reel": stockReel,
      "ecart": ecart,
      "date": date.toIso8601String(),
      "operateur": operateur,
      "motif": motif,
      "productId": productId,
    };
  }
}
