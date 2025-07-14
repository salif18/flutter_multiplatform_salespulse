class HistoriqueAbonnement {
  final String type;
  final String statut;
  final DateTime debut;
  final DateTime fin;

  HistoriqueAbonnement({
    required this.type,
    required this.statut,
    required this.debut,
    required this.fin,
  });

  factory HistoriqueAbonnement.fromJson(Map<String, dynamic> json) {
    return HistoriqueAbonnement(
      type: json['type'],
      statut: json['statut'],
      debut: DateTime.parse(json['date_debut']),
      fin: DateTime.parse(json['date_fin']),
    );
  }
}
