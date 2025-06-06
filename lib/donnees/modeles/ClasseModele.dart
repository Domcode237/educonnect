class ClasseModele {
  final String id;
  final String nom;
  final String niveau;
  final List<String> matieresIds; // Liste d’ID de Matières
  final List<String> elevesIds;   // Liste d’ID d’Élèves

  ClasseModele({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.matieresIds,
    required this.elevesIds,
  });

  factory ClasseModele.fromMap(Map<String, dynamic> map, String id) {
    return ClasseModele(
      id: id,
      nom: map['nom'] ?? '',
      niveau: map['niveau'] ?? '',
      matieresIds: List<String>.from(map['matieresIds'] ?? []),
      elevesIds: List<String>.from(map['elevesIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'niveau': niveau,
      'matieresIds': matieresIds,
      'elevesIds': elevesIds,
    };
  }
}
