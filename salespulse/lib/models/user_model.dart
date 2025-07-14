class UserModel {
  final String id;
  final String  adminId;
  final String  name;
  final String  numero;
  final String  email;
  final String  role;
  final DateTime createdAt;


  UserModel({ 
    required this.id,
    required this.adminId,
    required this.name,   
    required this.numero,
    required this.email,
    required this.role,
    required this.createdAt
  });

  factory UserModel.fromJon(Map<String,dynamic> json){
      return UserModel(
        id:json['_id'] ?? "",
        adminId: json["adminId"] ?? "", 
        name: json["name"] ?? "", 
        numero: json["numero"] ?? "", 
        email: json["email"] ?? "", 
        role: json["role"] ?? "",
        createdAt: json['createdAt']  != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        );
  }

  Map<String,dynamic> tojson(){
    return {
      "_id":id,
       "adminId":adminId,
       "name":name,
       "numero":numero,
       "email":email,
       "role":role,
       "createdAt":createdAt.toIso8601String()
    };
  }
}
