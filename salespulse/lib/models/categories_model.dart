class CategoriesModel{
  final String id;
  String userId;
  final String name ;
  CategoriesModel({
    required this.id,
    required this.userId,
    required this.name
  });

factory CategoriesModel.fromJson(Map<String,dynamic> json){
  return CategoriesModel(
    id: json["_id"],
    userId: json["userId"],
    name: json["name"]
    );
}

Map<String,dynamic> toJson(){
  return {
    "_id":id,
    "userId":userId,
    "name":name
  };
}
}