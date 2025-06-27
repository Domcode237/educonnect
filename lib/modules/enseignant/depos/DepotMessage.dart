import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/message_model.dart';

class DepotMessage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'messages';

  /// 🔹 Créer un message
  Future<void> envoyerMessage(MessageModele message) async {
    final docRef = _firestore.collection(collectionName).doc();
    final messageAvecId = message.copyWith(id: docRef.id);
    await docRef.set(messageAvecId.toMap());
  }

  /// 🔹 Récupérer tous les messages entre deux utilisateurs
  Stream<List<MessageModele>> recupererMessages(String utilisateur1Id, String utilisateur2Id) {
    return _firestore
        .collection(collectionName)
        .orderBy('dateEnvoi', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModele.fromMap(doc.id, doc.data()))
            .where((msg) =>
                (msg.emetteurId == utilisateur1Id && msg.recepteurId == utilisateur2Id) ||
                (msg.emetteurId == utilisateur2Id && msg.recepteurId == utilisateur1Id))
            .toList());
  }

  /// 🔹 Récupérer les derniers messages reçus pour un utilisateur (boîte de réception)
  Stream<List<MessageModele>> recupererMessagesRecus(String utilisateurId) {
    return _firestore
        .collection(collectionName)
        .where('recepteurId', isEqualTo: utilisateurId)
        .orderBy('dateEnvoi', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => MessageModele.fromMap(doc.id, doc.data())).toList());
  }

  /// 🔹 Mettre à jour le statut "lu"
  Future<void> marquerCommeLu(String messageId) async {
    await _firestore.collection(collectionName).doc(messageId).update({'lu': true});
  }

  /// 🔹 Supprimer un message
  Future<void> supprimerMessage(String messageId) async {
    await _firestore.collection(collectionName).doc(messageId).delete();
  }

  /// 🔹 Modifier un message (par exemple le contenu)
  Future<void> modifierMessage(String messageId, Map<String, dynamic> data) async {
    await _firestore.collection(collectionName).doc(messageId).update(data);
  }

  /// 🔹 Récupérer un message par son ID
  Future<MessageModele?> recupererMessageParId(String messageId) async {
    final doc = await _firestore.collection(collectionName).doc(messageId).get();
    if (doc.exists) {
      return MessageModele.fromMap(doc.id, doc.data()!);
    } else {
      return null;
    }
  }
}
