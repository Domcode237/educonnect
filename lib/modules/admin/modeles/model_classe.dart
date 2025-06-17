class ClasseModele {
  final String id;
  final String nom;                // Ex: "3e Allemand"
  final String niveau;             // Ex: "3e"
  final String etablissementId;    // ID de l'établissement
  final List<String> matieresIds;
  final List<String> elevesIds;
  final List<String> enseignantsIds; // Liste des IDs des enseignants

  ClasseModele({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.etablissementId,
    List<String>? matieresIds,
    List<String>? elevesIds,
    List<String>? enseignantsIds,
  })  : matieresIds = matieresIds ?? [],
        elevesIds = elevesIds ?? [],
        enseignantsIds = enseignantsIds ?? [];

  factory ClasseModele.fromMap(Map<String, dynamic> map, String id) {
    return ClasseModele(
      id: id,
      nom: map['nom'] ?? '',
      niveau: map['niveau'] ?? '',
      etablissementId: map['etablissementId'] ?? '',
      matieresIds: List<String>.from(map['matieresIds'] ?? []),
      elevesIds: List<String>.from(map['elevesIds'] ?? []),
      enseignantsIds: List<String>.from(map['enseignantsIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'niveau': niveau,
      'etablissementId': etablissementId,
      'matieresIds': matieresIds,
      'elevesIds': elevesIds,
      'enseignantsIds': enseignantsIds,
    };
  }
}
