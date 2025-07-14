class ProduitId {
  final String nom;
  final String categories;

  ProduitId({
    required this.nom,
    required this.categories,
  });

  // Fonction pour créer un ProduitId à partir d'un JSON
  factory ProduitId.fromJson(Map<String, dynamic> json) {
    return ProduitId(
      nom: json['nom'],
      categories: json['categories'],
    );
  }

  // Fonction pour convertir un ProduitId en JSON
  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'categories': categories,
    };
  }
}

class ProduitBestVendu {
  final ProduitId id;
  final int totalVendu;

  ProduitBestVendu({
    required this.id,
    required this.totalVendu,
  });

  // Fonction pour créer un ProduitVendu à partir d'un JSON
  factory ProduitBestVendu.fromJson(Map<String, dynamic> json) {
    return ProduitBestVendu(
      id: ProduitId.fromJson(json['_id']),
      totalVendu: json['total_vendu'],
    );
  }

  // Fonction pour convertir un ProduitVendu en JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id.toJson(),
      'total_vendu': totalVendu,
    };
  }
}
