import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/DevoirModele.dart';

class DevoirRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Ajouter un devoir dans Firestore
  Future<void> ajouterDevoir(DevoirModele devoir) async {
    try {
      await _firestore.collection('devoirs').add(devoir.toMap());
      print('✅ Devoir ajouté avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du devoir : $e');
      rethrow;
    }
  }

  /// 🔹 Récupérer tous les devoirs pour un établissement et une classe donnée
  Future<List<DevoirModele>> getDevoirsParEtablissementEtClasse(String etablissementId, String classeId) async {
    try {
      final querySnapshot = await _firestore
          .collection('devoirs')
          .where('etablissementId', isEqualTo: etablissementId)
          .where('classeId', isEqualTo: classeId)
          .orderBy('dateRemise')
          .get();

      return querySnapshot.docs
          .map((doc) => DevoirModele.fromDocument(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des devoirs : $e');
      rethrow;
    }
  }

  /// 🔹 Récupérer tous les devoirs pour un établissement, une classe et une matière
  Future<List<DevoirModele>> getDevoirsParEtablissementClasseEtMatiere(String etablissementId, String classeId, String matiereId) async {
    try {
      final querySnapshot = await _firestore
          .collection('devoirs')
          .where('etablissementId', isEqualTo: etablissementId)
          .where('classeId', isEqualTo: classeId)
          .where('matiereId', isEqualTo: matiereId)
          .orderBy('dateRemise')
          .get();

      return querySnapshot.docs
          .map((doc) => DevoirModele.fromDocument(doc))
          .toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des devoirs : $e');
      rethrow;
    }
  }

  /// 🔹 Marquer un devoir comme lu pour un utilisateur (élève ou parent)
  Future<void> marquerDevoirCommeLu(String devoirId, String utilisateurId) async {
    try {
      final docRef = _firestore.collection('devoirs').doc(devoirId);
      await docRef.update({
        'lusPar': FieldValue.arrayUnion([utilisateurId]),
      });
      print('👁️ Devoir marqué comme lu pour $utilisateurId');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour de la lecture : $e');
      rethrow;
    }
  }

  /// 🔹 Supprimer un devoir (si besoin)
  Future<void> supprimerDevoir(String devoirId) async {
    try {
      await _firestore.collection('devoirs').doc(devoirId).delete();
      print('🗑️ Devoir supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression : $e');
      rethrow;
    }
  }
}
