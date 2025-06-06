class UtilisateurModele {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numeroTelephone;
  final String adresse;
  final String motDePasse;
  final bool statut;
  final String roleId; // Juste l'ID du rôle
  final String etablissementId; // Juste l'ID de l'établissement

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
    };
  }

  @override
  String toString() {
    return 'Utilisateur(id: $id, nom: $nom, prenom: $prenom, roleId: $roleId, etablissementId: $etablissementId)';
  }
}
