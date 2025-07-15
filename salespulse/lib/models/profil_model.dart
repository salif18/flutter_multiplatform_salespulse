class ProfilModel{
  final String? id;
  final String? userId;
  final String? adminId;
  final String? cloudinaryId;
  final String? image;

  ProfilModel({
      required this.id,
      required this.userId,
      required this.adminId, 
      required this.cloudinaryId,
      required this.image
  });

  factory ProfilModel.fromJson(Map<String,dynamic> json){
      return ProfilModel(
        id:json["_id"] ?? "",
        userId:  json["userId"] ?? "",
        adminId:  json["adminId"] ?? "",
        cloudinaryId: json["cloudinaryId"] ?? "",
        image:json["image"] ?? ""
      );
  }

  Map<String,dynamic>toJson(){
    return {
          "_id":id,
          "userId":userId,
          "adminId":adminId,
          "cloudinaryId":cloudinaryId,
          "image":image
    };
  }
}