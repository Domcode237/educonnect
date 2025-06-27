import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModele {
  final String id;
  final String eleveId;
  final String parentId;
  final String expediteurId;
  final String expediteurRole; // 'enseignant' ou 'administrateur'
  final String etablissementId; // 🔥 nouveau champ ajouté
  final String titre;
  final String message;
  final bool lu;
  final DateTime createdAt;
  final String? type; // 'absence', 'note', etc.
  final Map<String, dynamic>? metadata;

  NotificationModele({
    required this.id,
    required this.eleveId,
    required this.parentId,
    required this.expediteurId,
    required this.expediteurRole,
    required this.etablissementId, // 🔥
    required this.titre,
    required this.message,
    required this.lu,
    required this.createdAt,
    this.type,
    this.metadata,
  });

  factory NotificationModele.fromMap(String id, Map<String, dynamic> data) {
    return NotificationModele(
      id: id,
      eleveId: data['eleveId'] ?? '',
      parentId: data['parentId'] ?? '',
      expediteurId: data['expediteurId'] ?? '',
      expediteurRole: data['expediteurRole'] ?? '',
      etablissementId: data['etablissementId'] ?? '', // 🔥
      titre: data['titre'] ?? '',
      message: data['message'] ?? '',
      lu: data['lu'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eleveId': eleveId,
      'parentId': parentId,
      'expediteurId': expediteurId,
      'expediteurRole': expediteurRole,
      'etablissementId': etablissementId, // 🔥
      'titre': titre,
      'message': message,
      'lu': lu,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'metadata': metadata,
    };
  }

  static NotificationModele empty() => NotificationModele(
        id: '',
        eleveId: '',
        parentId: '',
        expediteurId: '',
        expediteurRole: '',
        etablissementId: '', // 🔥
        titre: '',
        message: '',
        lu: false,
        createdAt: DateTime.now(),
        type: null,
        metadata: null,
      );
}
