class EnseignementModele {
  final String id;           // ID du document Firestore
  final String enseignantId; // Référence à Enseignant
  final String matiereId;    // Référence à Matière

  EnseignementModele({
    required this.id,
    required this.enseignantId,
    required this.matiereId,
  });

  factory EnseignementModele.fromMap(Map<String, dynamic> map, String id) {
    return EnseignementModele(
      id: id,
      enseignantId: map['enseignantId'] ?? '',
      matiereId: map['matiereId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enseignantId': enseignantId,
      'matiereId': matiereId,
    };
  }
}
