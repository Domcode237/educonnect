import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/modules/admin/modeles/model_matiere.dart';

class MatiereController {
  final CollectionReference _matiereRef =
      FirebaseFirestore.instance.collection('matieres');

  final String etablissementId; // ID de l'établissement connecté

  MatiereController({required this.etablissementId});

  // Ajouter une matière (avec l'id établissement)
  Future<void> ajouterMatiere(MatiereModele matiere) async {
    try {
      // On s'assure que l'objet matiere contient bien l'id établissement correct
      final matiereAvecEtablissement = MatiereModele(
        id: matiere.id,
        nom: matiere.nom,
        coefficient: matiere.coefficient,
        description: matiere.description,
        etablissementId: etablissementId,
      );

      await _matiereRef.doc(matiere.id).set(matiereAvecEtablissement.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la matière : $e');
    }
  }

  // Lire toutes les matières de l'établissement connecté uniquement
  Future<List<MatiereModele>> lireToutesLesMatieres() async {
    try {
      QuerySnapshot snapshot = await _matiereRef
          .where('etablissementId', isEqualTo: etablissementId)
          .get();

      return snapshot.docs.map((doc) {
        return MatiereModele.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la lecture des matières : $e');
    }
  }

  // Lire une matière par ID (vérifie aussi l'établissement)
  Future<MatiereModele?> lireMatiereParId(String id) async {
    try {
      DocumentSnapshot doc = await _matiereRef.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          return MatiereModele.fromMap(data, doc.id);
        } else {
          // La matière ne fait pas partie de cet établissement
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Erreur lors de la lecture de la matière : $e');
    }
  }

  // Mettre à jour une matière (vérifie l'établissement aussi)
  Future<void> modifierMatiere(MatiereModele matiere) async {
    try {
      // On récupère la matière existante pour vérifier l'établissement
      DocumentSnapshot doc = await _matiereRef.doc(matiere.id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _matiereRef.doc(matiere.id).update(matiere.toMap());
        } else {
          throw Exception('Vous ne pouvez pas modifier une matière d\'un autre établissement.');
        }
      } else {
        throw Exception('Matière non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la modification de la matière : $e');
    }
  }

  // Supprimer une matière (vérifie l'établissement aussi)
  Future<void> supprimerMatiere(String id) async {
    try {
      DocumentSnapshot doc = await _matiereRef.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _matiereRef.doc(id).delete();
        } else {
          throw Exception('Vous ne pouvez pas supprimer une matière d\'un autre établissement.');
        }
      } else {
        throw Exception('Matière non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la matière : $e');
    }
  }

  // Supprimer toutes les matières de l'établissement connecté uniquement
  Future<void> supprimerToutesLesMatieres() async {
    try {
      QuerySnapshot snapshot = await _matiereRef
          .where('etablissementId', isEqualTo: etablissementId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de toutes les matières : $e');
    }
  }
}
