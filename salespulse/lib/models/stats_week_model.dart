class StatsWeekModel{
  String? date;
  int? total;

 StatsWeekModel({
  required this.date,
  required this.total
 });

 factory StatsWeekModel.fromJson(Map<String,dynamic> json){
  return StatsWeekModel(
    date: json['date'] ?? "", 
    total: json["total"] ?? 0
    );
 }
 Map<String,dynamic> toJson(){
  return {
     "date":date,
     "total":total
  };
}
}