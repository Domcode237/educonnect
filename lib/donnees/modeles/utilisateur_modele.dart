class UtilisateurModele {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numeroTelephone;
  final String adresse;
  final String motDePasse;
  final bool statut;
  final String roleId;
  final String etablissementId;
  final String? photo; 

  UtilisateurModele({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    required this.adresse,
    required this.motDePasse,
    required this.statut,
    required this.roleId,
    required this.etablissementId,
    this.photo,
  });

  factory UtilisateurModele.fromMap(Map<String, dynamic> map, String id) {
    return UtilisateurModele(
      id: id,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      numeroTelephone: map['numeroTelephone'] ?? '',
      adresse: map['adresse'] ?? '',
      motDePasse: map['motDePasse'] ?? '',
      statut: map['statut'] ?? true,
      roleId: map['roleId'] ?? '',
      etablissementId: map['etablissementId'] ?? '',
      photo: map['photo'], 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'numeroTelephone': numeroTelephone,
      'adresse': adresse,
      'motDePasse': motDePasse,
      'statut': statut,
      'roleId': roleId,
      'etablissementId': etablissementId,
      'photo': photo, 
    };
  }

  @override
  String toString() {
    return 'Utilisateur(id: $id, nom: $nom, prenom: $prenom, roleId: $roleId, etablissementId: $etablissementId, photo: $photo)';
  }

  /// Méthode statique pour retourner un utilisateur vide (valeurs par défaut)
  static UtilisateurModele empty() => UtilisateurModele(
        id: '',
        nom: '',
        prenom: '',
        email: '',
        numeroTelephone: '',
        adresse: '',
        motDePasse: '',  // champ requis
        statut: false,
        roleId: '',
        etablissementId: '',
        photo: null, // nullable
      );
}
