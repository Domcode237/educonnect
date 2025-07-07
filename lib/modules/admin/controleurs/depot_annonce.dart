import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/model_annonce.dart';

class DepotAnnonce {
  final CollectionReference annoncesRef = FirebaseFirestore.instance.collection('annonces');

  /// Ajouter une nouvelle annonce
  Future<void> ajouterAnnonce(AnnonceModele annonce) async {
    await annoncesRef.doc(annonce.id).set(annonce.toMap());
  }

  /// Générer automatiquement un nouvel ID pour une annonce
  String genererNouvelId() {
    return annoncesRef.doc().id;
  }

  /// Récupérer toutes les annonces d’un établissement
  Stream<List<AnnonceModele>> obtenirAnnoncesParEtablissement(String etablissementId) {
    return annoncesRef
        .where('etablissementId', isEqualTo: etablissementId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnnonceModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Marquer une annonce comme lue par un utilisateur
  Future<void> marquerCommeLue(String annonceId, String utilisateurId) async {
    await annoncesRef.doc(annonceId).update({
      'luePar': FieldValue.arrayUnion([utilisateurId]),
    });
  }

  /// Supprimer une annonce
  Future<void> supprimerAnnonce(String annonceId) async {
    await annoncesRef.doc(annonceId).delete();
  }

  /// Récupérer une annonce par ID
  Future<AnnonceModele?> getAnnonceParId(String id) async {
    final doc = await annoncesRef.doc(id).get();
    if (!doc.exists) return null;
    return AnnonceModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
