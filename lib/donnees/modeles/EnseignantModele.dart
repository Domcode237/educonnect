class EnseignantModele {
  final String id;
  final String utilisateurId;

  EnseignantModele({
    required this.id,
    required this.utilisateurId,
  });

  // Convertir depuis Firestore
  factory EnseignantModele.fromMap(Map<String, dynamic> map, String id) {
    return EnseignantModele(
      id: id,
      utilisateurId: map['utilisateurId'] ?? '',
    );
  }

  // Convertir en map pour l'enregistrement
  Map<String, dynamic> toMap() {
    return {
      'utilisateurId': utilisateurId,
    };
  }
}
