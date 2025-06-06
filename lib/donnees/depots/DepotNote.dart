import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/NoteModele.dart';

class DepotNote {
  final _db = FirebaseFirestore.instance;

  Future<void> ajouterNote(NoteModele note) async {
    await _db.collection('notes').add(note.toMap());
  }

  Future<void> modifierNote(String id, NoteModele note) async {
    await _db.collection('notes').doc(id).update(note.toMap());
  }

  Future<void> supprimerNote(String id) async {
    await _db.collection('notes').doc(id).delete();
  }

  Future<List<NoteModele>> getToutesLesNotes() async {
    final snapshot = await _db.collection('notes').get();
    return snapshot.docs.map((doc) => NoteModele.fromMap(doc.data())).toList();
  }

  Future<List<NoteModele>> getNotesParEleve(String eleveId) async {
    final snapshot = await _db
        .collection('notes')
        .where('eleveId', isEqualTo: eleveId)
        .get();
    return snapshot.docs.map((doc) => NoteModele.fromMap(doc.data())).toList();
  }
}
