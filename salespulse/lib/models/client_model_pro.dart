class ClientModel {
  final String id;
  final String userId;
  final String nom;
  final String contact;
  final String image;
  final int creditTotal;
  final int montantPaye;
  final int reste;
  final int monnaie;
  final String recommandation;
  final String statut;
  final DateTime date;

  ClientModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.contact,
    required this.image,
    required this.creditTotal,
    required this.montantPaye,
    required this.reste,
    required this.monnaie,
    required this.recommandation,
    required this.statut,
    required this.date,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['_id'],
      userId:json["userId"],
      nom: json['nom'],
      contact: json['contact'],
      image: json["image"] ?? "",
      creditTotal: json['credit_total'],
      montantPaye: json['montant_paye'],
      reste: json['reste'],
      monnaie: json['monnaie'],
      recommandation: json['recommandation'],
      statut: json['statut'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        "userId":userId,
        'nom': nom,
        'contact': contact,
        'image':image,
        'credit_total': creditTotal,
        'montant_paye': montantPaye,
        'reste': reste,
        'monnaie': monnaie,
        'recommandation': recommandation,
        'statut': statut,
        'date': date.toIso8601String(),
      };
}
