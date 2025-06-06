import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';

class DepotClasse {
  final _db = FirebaseFirestore.instance;

  Future<void> ajouterClasse(ClasseModele classe) async {
    await _db.collection('classes').doc(classe.id).set(classe.toMap());
  }

  Future<void> modifierClasse(String id, ClasseModele classe) async {
    await _db.collection('classes').doc(id).update(classe.toMap());
  }

  Future<void> supprimerClasse(String id) async {
    await _db.collection('classes').doc(id).delete();
  }

  Future<List<ClasseModele>> getToutesLesClasses() async {
    final snapshot = await _db.collection('classes').get();
    return snapshot.docs.map((doc) => ClasseModele.fromMap(doc.data(), doc.id)).toList();
  }

  Future<ClasseModele?> getClasseParId(String id) async {
    final doc = await _db.collection('classes').doc(id).get();
    if (doc.exists) {
      return ClasseModele.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
