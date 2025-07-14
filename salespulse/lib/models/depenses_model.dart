class DepensesModel {
  String id;
  String userId;
  int montants;
  String motifs;
  final String type;
  DateTime date;

  DepensesModel(
      {
      required this.id,
      required this.userId,
      required this.montants,
      required this.motifs,
      required this.type,
      required this.date
      });

  factory DepensesModel.fromJson(Map<String, dynamic> json) {
    return DepensesModel(
        id: json["_id"],
        userId: json["userId"],
        montants: json["montants"],
        motifs: json["motifs"],
        type: json["type"],
        date: DateTime.parse(json["createdAt"]));
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "userId": userId,
      "montants": montants,
      "motifs": motifs,
      "type":type,
      "createdAt": date.toIso8601String()
    };
  }
}
