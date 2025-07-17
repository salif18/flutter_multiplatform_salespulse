class ProduitCommande {
  final String productId;
  final String? image;
  final String? nom;
  final int quantite;
  final double prixAchat;

  ProduitCommande({
    required this.productId,
    this.image,
    this.nom,
    required this.quantite,
    required this.prixAchat,
  });

  factory ProduitCommande.fromJson(Map<String, dynamic> json) {
    return ProduitCommande(
      productId: json['productId'],
      image: json['image'],
      nom:json['nom'] ?? "",
      quantite: json['quantite'],
      prixAchat: (json['prixAchat'] as num).toDouble(),
    );
  }
}

class CommandeModel {
  final String id;
  final String adminId;
  final String fournisseurId;
  final String fournisseurName;
  final String? fournisseurContact;
  final String? fournisseurAddress;
  final List<ProduitCommande> produits;
  final int? total;
   String statut;
  final String date;
  final String? notes;

  CommandeModel({
    required this.id,
    required this.adminId,
    required this.fournisseurId,
    required this.fournisseurName,
    this.fournisseurContact,
    this.fournisseurAddress,
    required this.produits,
    required this.total,
    required this.statut,
    required this.date,
    this.notes,
  });

  factory CommandeModel.fromJson(Map<String, dynamic> json) {
    return CommandeModel(
      id: json['_id'],
      adminId: json['adminId'],
      fournisseurId: json['fournisseurId'],
      fournisseurName: json['fournisseurName'],
      fournisseurContact: json['fournisseurContact'],
      fournisseurAddress: json['fournisseurAddress'],
      produits: (json['produits'] as List)
          .map((item) => ProduitCommande.fromJson(item))
          .toList(),
      total:json["total"] ?? 0,
      statut: json['statut'],
      date: json['date'],
      notes: json['notes'],
    );
  }
}
