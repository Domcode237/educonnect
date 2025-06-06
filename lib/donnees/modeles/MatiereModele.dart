class MatiereModele {
  final String id;
  final String nom;
  final double coefficient;
  final String enseignantId;

  MatiereModele({
    required this.id,
    required this.nom,
    required this.coefficient,
    required this.enseignantId,
  });

  factory MatiereModele.fromMap(Map<String, dynamic> map, [String? id]) {
    return MatiereModele(
      id: id ?? map['id'] ?? '',
      nom: map['nom'] ?? '',
      coefficient: map['coefficient']?.toDouble() ?? 1.0,
      enseignantId: map['enseignantId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'coefficient': coefficient,
      'enseignantId': enseignantId,
    };
  }
}
