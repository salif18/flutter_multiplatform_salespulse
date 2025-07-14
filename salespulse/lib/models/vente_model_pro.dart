// Model future pour mode pro

class ProductItemModel {
  final String productId;
  final String nom;
  final String? image;
  final int prixUnitaire;
  final int prixAchat;
  final int? remise;
  final String? remiseType;
  bool isPromo;
  final int prixVente;
  final int? tva;
  final int? fraisLivraison;
  final int? fraisEmballage;
  int quantite;
  int sousTotal;
  int? stocks; // ✅ stock disponible

  ProductItemModel(
      {required this.productId,
      required this.nom,
      required this.image,
      required this.prixAchat,
      required this.prixUnitaire,
      required this.remise,
      required this.remiseType,
      required this.isPromo,
      required this.prixVente,
      required this.tva,
      required this.fraisLivraison,
      required this.fraisEmballage,
      required this.quantite,
      required this.sousTotal,
      required this.stocks});

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
        productId: json['productId'] ?? "",
        nom: json['nom'] ?? "",
        image: json["image"] ?? "",
        prixAchat: json["prix_achat"],
        prixUnitaire: json['prix_unitaire'] ?? "",
        remise: json["remise"] ?? 0,
        remiseType: json["remise_type"] ?? "",
        isPromo: json['isPromo'] == true || json['isPromo'] == 'true',
        prixVente: json["prix_vente"] ?? 0,
        tva: json["tva"] ?? "",
        fraisLivraison: json["frais_livraison"] ?? "",
        fraisEmballage: json["frais_emballage"] ?? "",
        quantite: json['quantite'] ?? "",
        sousTotal: json['sous_total'] ?? "",
        stocks: json["stocks"] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'nom': nom,
      'image': image,
      'prix_achat': prixAchat,
      'prix_unitaire': prixUnitaire,
      'remise': remise, // en FCFA ou %
      'remise_type': remiseType,
      'isPromo':isPromo == true,
      'prix_vente':prixVente,
      'tva': tva, // % appliqué (ex: 18)
      'frais_livraison': fraisLivraison, // en FCFA
      'frais_emballage': fraisEmballage, //
      'quantite': quantite,
      'sous_total': sousTotal,
      'stocks': stocks
    };
  }
}

class VenteModel {
  final String id;
  final String userId;
  final String? clientId;
  final String? clientNom;
  final String? contactClient;
  final List<ProductItemModel> produits;
  final int total;
  final int montantRecu;
  final int? remiseGlobale;
  final String? remiseGlobaleType;
  final int? tvaGlobale;
  final int? livraison;
  final int? emballage;
  final int monnaie;
  final int reste;
  final String typePaiement;
  final String statut;
  final DateTime date;

  VenteModel({
    required this.id,
    required this.userId,
    this.clientId,
    this.clientNom,
    this.contactClient,
    required this.produits,
    required this.total,
    required this.montantRecu,
    required this.remiseGlobale,
    required this.remiseGlobaleType,
    required this.tvaGlobale,
    required this.livraison,
    required this.emballage,
    required this.monnaie,
    required this.reste,
    required this.typePaiement,
    required this.statut,
    required this.date,
  });

  factory VenteModel.fromJson(Map<String, dynamic> json) {
    return VenteModel(
      id: json['_id'] ?? "",
      userId: json['userId'] ?? "",
      clientId: json['clientId'] ?? "",
      // ignore: unnecessary_type_check
      clientNom: json['nom'],
      contactClient: json["contactClient"] ?? "",
      produits: (json['produits'] as List)
          .map((item) => ProductItemModel.fromJson(item))
          .toList(),
      total: json['total'] ?? "",
      montantRecu: json['montant_recu'] ?? "",
      remiseGlobale: json["remiseGlobale"] ?? "",
      remiseGlobaleType: json["remiseGlobaleType"] ?? "",
      tvaGlobale: json["tvaGlobale"] ?? "",
      livraison: json["livraison"] ?? "",
      emballage: json["emballage"] ?? "",
      monnaie: json['monnaie'] ?? "",
      reste: json["reste"] ?? "",
      typePaiement: json['type_paiement'] ?? "",
      statut: json['statut'],
      date: DateTime.parse(json['date'] ?? ""),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'clientId': clientId,
      'nom': clientNom,
      'contactClient': contactClient,
      'produits': produits.map((p) => p.toJson()).toList(),
      'total': total,
      'montant_recu': montantRecu,
      'remiseGlobale': remiseGlobale,
      'remiseGlobaleType': remiseGlobaleType,
      'tvaGlobale': tvaGlobale,
      'livraison': livraison,
      'emballage': emballage,
      'monnaie': monnaie,
      'reste': reste,
      'type_paiement': typePaiement,
      'statut': statut,
      'date': date.toIso8601String(),
    };
  }
}
