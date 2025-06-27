import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/model_notification.dart';

class DepotNotification {
  final CollectionReference _notifCollection =
      FirebaseFirestore.instance.collection('notifications');

  /// 🔥 Ajoute une seule notification
  Future<String> ajouterNotification(NotificationModele notification) async {
    try {
      final docRef = await _notifCollection.add(notification.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception("Erreur lors de l'ajout de la notification : $e");
    }
  }

  /// 🚀 Ajoute plusieurs notifications en une seule opération batch
  Future<void> ajouterNotificationsParLot(List<NotificationModele> notifications) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (NotificationModele notif in notifications) {
        DocumentReference docRef = _notifCollection.doc(); // Auto ID
        batch.set(docRef, notif.toMap());
      }
      await batch.commit();
    } catch (e) {
      throw Exception("Erreur lors de l'ajout par lot des notifications : $e");
    }
  }

  /// 🔍 Récupère une notification par son ID
  Future<NotificationModele?> getNotificationParId(String notificationId) async {
    try {
      final doc = await _notifCollection.doc(notificationId).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null || data is! Map<String, dynamic>) return null;
      return NotificationModele.fromMap(doc.id, data);
    } catch (e) {
      throw Exception("Erreur récupération notification : $e");
    }
  }

  /// ✅ Marque une notification comme lue
  Future<void> marquerCommeLue(String notificationId) async {
    try {
      await _notifCollection.doc(notificationId).update({'lu': true});
    } catch (e) {
      throw Exception("Erreur mise à jour du statut lu : $e");
    }
  }

  /// ❌ Supprime une notification
  Future<void> supprimerNotification(String notificationId) async {
    try {
      await _notifCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception("Erreur suppression notification : $e");
    }
  }

  /// 📥 Récupère toutes les notifications d’un utilisateur (parent)
  Stream<List<NotificationModele>> getNotificationsPourUtilisateur(String utilisateurId) {
    return _notifCollection
        .where('parentId', isEqualTo: utilisateurId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return <NotificationModele>[];

          return snapshot.docs.map((doc) {
            final data = doc.data();
            if (data == null) {
              print("Document ${doc.id} sans données");
              return null;
            }
            if (data is! Map<String, dynamic>) {
              print("Document ${doc.id} données au format inattendu: $data");
              return null;
            }
            try {
              return NotificationModele.fromMap(doc.id, data);
            } catch (e) {
              print("Erreur mapping notification ${doc.id}: $e");
              return null;
            }
          }).whereType<NotificationModele>().toList();
        });
  }

  /// 📬 Récupère les notifications non lues d’un utilisateur
  Future<List<NotificationModele>> getNotificationsNonLues(String utilisateurId) async {
    try {
      final query = await _notifCollection
          .where('parentId', isEqualTo: utilisateurId)
          .where('lu', isEqualTo: false)
          .get();

      if (query.docs.isEmpty) return [];

      return query.docs.map((doc) {
        final data = doc.data();
        if (data == null || data is! Map<String, dynamic>) {
          print("Notification non lue ${doc.id} données invalides");
          return null;
        }
        try {
          return NotificationModele.fromMap(doc.id, data);
        } catch (e) {
          print("Erreur mapping notification non lue ${doc.id}: $e");
          return null;
        }
      }).whereType<NotificationModele>().toList();
    } catch (e) {
      throw Exception("Erreur récupération notifications non lues : $e");
    }
  }

  /// 📊 Récupère toutes les notifications d’un établissement
  Stream<List<NotificationModele>> getNotificationsPourEtablissement(String etablissementId) {
    return _notifCollection
        .where('etablissementId', isEqualTo: etablissementId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return <NotificationModele>[];

          return snapshot.docs.map((doc) {
            final data = doc.data();
            if (data == null) {
              print("Document ${doc.id} sans données");
              return null;
            }
            if (data is! Map<String, dynamic>) {
              print("Document ${doc.id} données au format inattendu: $data");
              return null;
            }
            try {
              return NotificationModele.fromMap(doc.id, data);
            } catch (e) {
              print("Erreur mapping notification ${doc.id}: $e");
              return null;
            }
          }).whereType<NotificationModele>().toList();
        });
  }

  /// 🔥 Récupère la dernière notification d’un utilisateur (parent)
  Future<NotificationModele?> getDerniereNotificationPourUtilisateur(String utilisateurId) async {
    try {
      final query = await _notifCollection
          .where('parentId', isEqualTo: utilisateurId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      final data = doc.data();

      if (data == null || data is! Map<String, dynamic>) return null;

      return NotificationModele.fromMap(doc.id, data);
    } catch (e) {
      print("Erreur récupération dernière notification : $e");
      return null;
    }
  }
}
