class EtablissementModele {
  final String id;
  final String nom;
  final String type;
  final String description;
  final String adresse;
  final String ville;
  final String region;
  final String pays;
  final String codePostal;
  final String email;
  final String telephone;

  EtablissementModele({
    required this.id,
    required this.nom,
    required this.type,
    required this.description,
    required this.adresse,
    required this.ville,
    required this.region,
    required this.pays,
    required this.codePostal,
    required this.email,
    required this.telephone,
  });

  factory EtablissementModele.fromMap(Map<String, dynamic> map, String id) {
    return EtablissementModele(
      id: id,
      nom: map['nom'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      region: map['region'] ?? '',
      pays: map['pays'] ?? '',
      codePostal: map['codePostal'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'type': type,
      'description': description,
      'adresse': adresse,
      'ville': ville,
      'region': region,
      'pays': pays,
      'codePostal': codePostal,
      'email': email,
      'telephone': telephone,
    };
  }
}
