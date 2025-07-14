class StatsYearModel {
  final int? nombreVentes;
  final int? totalVentes;
  final int? year;
  final int? month;

  StatsYearModel({
    required this.nombreVentes,
    required this.totalVentes,
    required this.year,
    required this.month,
  });

  factory StatsYearModel.fromJson(Map<String, dynamic> json) {
    return StatsYearModel(
        nombreVentes: json["nombre_ventes"] ?? "",
        totalVentes: json["total_ventes"] ?? "",
        year: json["annee"],
        month: json["mois"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "nombre_ventes": nombreVentes,
      "total_ventes": totalVentes,
      "annee": year,
      "mois": month
    };
  }
}
