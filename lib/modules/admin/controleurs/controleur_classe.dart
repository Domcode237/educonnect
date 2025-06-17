import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/modules/admin/modeles/model_classe.dart';

class ClasseController {
  final CollectionReference _classesRef =
      FirebaseFirestore.instance.collection('classes');

  final String etablissementId; // ID de l'établissement connecté

  ClasseController({required this.etablissementId});

  /// 🔹 Créer une nouvelle classe (ajoute automatiquement l'etablissementId)
  Future<void> ajouterClasse(ClasseModele classe) async {
    try {
      final classeAvecEtablissement = ClasseModele(
        id: classe.id,
        nom: classe.nom,
        niveau: classe.niveau,
        etablissementId: etablissementId,
        matieresIds: classe.matieresIds,
        elevesIds: classe.elevesIds,
        enseignantsIds: classe.enseignantsIds,
      );

      await _classesRef.doc(classe.id).set(classeAvecEtablissement.toMap());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la classe : $e');
    }
  }

  /// 🔹 Lire toutes les classes de l'établissement connecté uniquement
  Future<List<ClasseModele>> getToutesLesClasses() async {
    try {
      final snapshot = await _classesRef
          .where('etablissementId', isEqualTo: etablissementId)
          .get();

      return snapshot.docs.map((doc) {
        return ClasseModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la lecture des classes : $e');
    }
  }

  /// 🔹 Lire une classe par ID (vérifie l'établissement)
  Future<ClasseModele?> getClasseParId(String id) async {
    try {
      final doc = await _classesRef.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          return ClasseModele.fromMap(data, doc.id);
        } else {
          return null; // La classe ne fait pas partie de cet établissement
        }
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la lecture de la classe : $e');
    }
  }

  /// 🔹 Supprimer une classe (vérifie l'établissement)
  Future<void> supprimerClasse(String id) async {
    try {
      final doc = await _classesRef.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(id).delete();
        } else {
          throw Exception('Vous ne pouvez pas supprimer une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la classe : $e');
    }
  }

  /// 🔹 Ajouter un élève à une classe (vérifie l'établissement)
  Future<void> ajouterEleve(String classeId, String eleveId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'elevesIds': FieldValue.arrayUnion([eleveId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'élève : $e');
    }
  }

  /// 🔹 Supprimer un élève d’une classe (vérifie l'établissement)
  Future<void> supprimerEleve(String classeId, String eleveId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'elevesIds': FieldValue.arrayRemove([eleveId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'élève : $e');
    }
  }

  /// 🔹 Ajouter une matière à une classe (vérifie l'établissement)
  Future<void> ajouterMatiere(String classeId, String matiereId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'matieresIds': FieldValue.arrayUnion([matiereId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de la matière : $e');
    }
  }

  /// 🔹 Supprimer une matière d’une classe (vérifie l'établissement)
  Future<void> supprimerMatiere(String classeId, String matiereId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'matieresIds': FieldValue.arrayRemove([matiereId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la matière : $e');
    }
  }

  /// 🔹 Ajouter un enseignant à une classe (vérifie l'établissement)
  Future<void> ajouterEnseignant(String classeId, String enseignantId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'enseignantsIds': FieldValue.arrayUnion([enseignantId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'enseignant : $e');
    }
  }

  /// 🔹 Supprimer un enseignant d’une classe (vérifie l'établissement)
  Future<void> supprimerEnseignant(String classeId, String enseignantId) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          await _classesRef.doc(classeId).update({
            'enseignantsIds': FieldValue.arrayRemove([enseignantId]),
          });
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'enseignant : $e');
    }
  }

  /// 🔹 Mettre à jour les infos générales d’une classe (nom, niveau) - vérifie l'établissement
  Future<void> mettreAJourClasse(String classeId,
      {String? nom, String? niveau}) async {
    try {
      final doc = await _classesRef.doc(classeId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['etablissementId'] == etablissementId) {
          final Map<String, dynamic> updates = {};
          if (nom != null) updates['nom'] = nom;
          if (niveau != null) updates['niveau'] = niveau;

          if (updates.isNotEmpty) {
            await _classesRef.doc(classeId).update(updates);
          }
        } else {
          throw Exception('Vous ne pouvez pas modifier une classe d\'un autre établissement.');
        }
      } else {
        throw Exception('Classe non trouvée.');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la classe : $e');
    }
  }
}
