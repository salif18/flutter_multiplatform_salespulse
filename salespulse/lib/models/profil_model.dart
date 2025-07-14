class ProfilModel{
  final String? id;
  final String? userId;
  final String? cloudinaryId;
  final String? image;

  ProfilModel({
      required this.id,
      required this.userId, 
      required this.cloudinaryId,
      required this.image
  });

  factory ProfilModel.fromJson(Map<String,dynamic> json){
      return ProfilModel(
        id:json["_id"] ?? "",
        userId:  json["userId"] ?? "",
        cloudinaryId: json["cloudinaryId"] ?? "",
        image:json["image"] ?? ""
      );
  }

  Map<String,dynamic>toJson(){
    return {
          "_id":id,
          "userId":userId,
          "cloudinaryId":cloudinaryId,
          "image":image
    };
  }
}