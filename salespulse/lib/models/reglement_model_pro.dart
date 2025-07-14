class ReglementModel {
  final String id;
  final String userId;
  final String venteId;
  final String clientId;
  final int montant;
  final String type;
  final String mode;
  final String operateur;
  final String nom;
  final DateTime date;

  ReglementModel({
    required this.id,
    required this.userId,
    required this.venteId,
    required this.clientId,
    required this.montant,
    required this.type,
    required this.mode,
    required this.operateur,
    required this.nom,
    required this.date,
  });

  factory ReglementModel.fromJson(Map<String, dynamic> json) {
    return ReglementModel(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      venteId: json['venteId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      montant: json['montant'] ?? 0,
      type: json['type']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      operateur: json['operateur']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'venteId': venteId,
      'clientId': clientId,
      'montant': montant,
      'type': type,
      'mode': mode,
      'operateur': operateur,
      'nom': nom,
      'date': date.toIso8601String(),
    };
  }
}
