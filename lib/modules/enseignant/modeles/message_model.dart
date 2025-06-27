import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModele {
  final String id;
  final String contenu;
  final String emetteurId;
  final String recepteurId;
  final DateTime dateEnvoi;
  final bool lu;
  final List<String> participants;  // <-- ajouté

  MessageModele({
    required this.id,
    required this.contenu,
    required this.emetteurId,
    required this.recepteurId,
    required this.dateEnvoi,
    required this.lu,
    required this.participants,  // <-- ajouté
  });

  factory MessageModele.fromMap(String id, Map<String, dynamic> data) {
    return MessageModele(
      id: id,
      contenu: data['contenu'] ?? '',
      emetteurId: data['emetteurId'] ?? '',
      recepteurId: data['recepteurId'] ?? '',
      dateEnvoi: (data['dateEnvoi'] as Timestamp).toDate(),
      lu: data['lu'] ?? false,
      participants: data.containsKey('participants')
          ? List<String>.from(data['participants'])
          : [data['emetteurId'] ?? '', data['recepteurId'] ?? ''], // fallback
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contenu': contenu,
      'emetteurId': emetteurId,
      'recepteurId': recepteurId,
      'dateEnvoi': Timestamp.fromDate(dateEnvoi),
      'lu': lu,
      'participants': participants,  // <-- ajouté
    };
  }

  MessageModele copyWith({
    String? id,
    String? contenu,
    String? emetteurId,
    String? recepteurId,
    DateTime? dateEnvoi,
    bool? lu,
    List<String>? participants,  // <-- ajouté
  }) {
    return MessageModele(
      id: id ?? this.id,
      contenu: contenu ?? this.contenu,
      emetteurId: emetteurId ?? this.emetteurId,
      recepteurId: recepteurId ?? this.recepteurId,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      lu: lu ?? this.lu,
      participants: participants ?? this.participants,
    );
  }
}
