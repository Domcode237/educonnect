class FamilleModele {
  final String id;
  final String parentId;
  final String eleveId;

  FamilleModele({
    required this.id,
    required this.parentId,
    required this.eleveId,
  });

  factory FamilleModele.fromMap(Map<String, dynamic> data, String id) {
    return FamilleModele(
      id: id,
      parentId: data['parentId'] ?? '',
      eleveId: data['eleveId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'eleveId': eleveId,
    };
  }
}
