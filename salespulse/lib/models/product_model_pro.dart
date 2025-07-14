class ProductModel {
  final String id;
  final String userId;
  final String? cloudinaryId;
  final String? image;
  final String nom;
  final String categories;
  final String description;
  final int prixAchat;
  final int prixVente;
   int stocks;
  final int seuilAlerte;
  final String unite;
  final String statut; // "disponible" ou "indisponible"
  bool isPromo;
  final int prixPromo;
  final DateTime? dateDebutPromo;
  final DateTime? dateFinPromo;
  final DateTime dateAchat;
  final DateTime? dateExpiration;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.userId,
    this.cloudinaryId,
    this.image,
    required this.nom,
    required this.categories,
    required this.description,
    required this.prixAchat,
    required this.prixVente,
    required this.stocks,
    required this.seuilAlerte,
    required this.unite,
    required this.statut,
    required this.isPromo,
    required this.dateDebutPromo,
    required this.dateFinPromo,
    required this.prixPromo,
    required this.dateAchat,
    this.dateExpiration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? "",
      userId: json['userId'] ?? "",
      cloudinaryId: json['cloudinaryId'] ?? "",
      image: json['image'] ?? "",
      nom: json['nom'] ?? "",
      categories: json['categories'] ?? "",
      description: json['description'] ?? '',
      prixAchat: json['prix_achat'] ?? "",
      prixVente: json['prix_vente'] ?? "",
      stocks: json['stocks'] ?? "",
      seuilAlerte: json['seuil_alerte'] ?? 5,
      unite: json['unite'] ?? 'pièce',
      statut: json['statut'] ?? 'disponible',
      isPromo: json['isPromo'] == true || json['isPromo'] == 'true',
      prixPromo: json['prix_promo'] ?? 0,
      dateDebutPromo:json['date_debut_promo'] != null
          ? DateTime.tryParse(json['date_debut_promo'])
          : null,
      dateFinPromo :json['date_fin_promo'] != null
          ? DateTime.tryParse(json['date_fin_promo'])
          : null,
      dateAchat: DateTime.parse(json['date_achat'] ?? ""),
      dateExpiration: json['date_expiration'] != null
          ? DateTime.tryParse(json['date_expiration'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? ""),
      updatedAt: DateTime.parse(json['updatedAt'] ?? ""),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userId": userId,
      "cloudinaryId": cloudinaryId,
      "image": image,
      "nom": nom,
      "categories": categories,
      "description": description,
      "prix_achat": prixAchat,
      "prix_vente": prixVente,
      "stocks": stocks,
      "seuil_alerte": seuilAlerte,
      "unite": unite,
      "statut": statut,
      "isPromo": isPromo == true,
      "date_debut_promo":dateDebutPromo?.toIso8601String(),
      "date_fin_promo":dateFinPromo?.toIso8601String(),
      "prix_promo": prixPromo,
      "date_achat": dateAchat.toIso8601String(),
      "date_expiration": dateExpiration?.toIso8601String(),
    };
  }
}
