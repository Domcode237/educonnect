import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class NotesPage extends StatefulWidget {
  final String etablissementId;
  final String utilisateurId;

  const NotesPage({
    super.key,
    required this.etablissementId,
    required this.utilisateurId,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? enseignantId;

  List<_ClasseAvecMatieres> classesAvecMatieres = [];
  String? classeChoisieId;

  List<Map<String, String>> matieres = [];
  String? matiereChoisieId;

  List<_EleveAvecNom> eleves = [];

  Map<String, String> notesStr = {};
  String descriptionExercice = '';

  final List<String> typesNotes = ['Exercice', 'Examen'];
  String? typeNote;

  final List<String> sequences = ['Séquence 1', 'Séquence 2', 'Séquence 3','Séquence 4', 'Séquence 5', 'Séquence 6'];
  String? sequenceChoisie;

  bool loading = true;
  bool saving = false;

  final boutonClassMatiereStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.red.shade300;
      }
      return Colors.red.shade100.withOpacity(0.25);
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      }
      return Colors.red.shade900;
    }),
    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    elevation: MaterialStateProperty.all(0),
    minimumSize: MaterialStateProperty.all(const Size(90, 32)),
  );

  final boutonTypeSeqStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.green.shade400;
      }
      return Colors.green.shade100.withOpacity(0.25);
    }),
    foregroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.selected)) {
        return Colors.white;
      }
      return Colors.green.shade900;
    }),
    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    elevation: MaterialStateProperty.all(0),
    minimumSize: MaterialStateProperty.all(const Size(90, 32)),
  );

  final boutonValiderStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade400,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    elevation: 3,
    minimumSize: const Size(180, 48),
  );

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) => _initData());
  }

  Future<void> _initData() async {
    try {
      final enseignantSnap = await _firestore
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (enseignantSnap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Enseignant introuvable.")),
          );
        }
        setState(() => loading = false);
        return;
      }

      enseignantId = enseignantSnap.docs.first.id;

      final classesSnap = await _firestore
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      final enseignementsSnap = await _firestore
          .collection('enseignements')
          .where('enseignantId', isEqualTo: enseignantId)
          .get();

      final enseignementMatieres =
          enseignementsSnap.docs.map((e) => e['matiereId'] as String).toSet();

      List<_ClasseAvecMatieres> temp = [];

      for (var doc in classesSnap.docs) {
        final data = doc.data();
        final enseignantsIds = List<String>.from(data['enseignantsIds'] ?? []);
        if (!enseignantsIds.contains(enseignantId)) continue;

        final matieresIds = List<String>.from(data['matieresIds'] ?? []);
        final matieresAssociees =
            matieresIds.where((id) => enseignementMatieres.contains(id)).toList();

        if (matieresAssociees.isNotEmpty) {
          temp.add(_ClasseAvecMatieres(
            classeId: doc.id,
            nomClasse: data['nom'] ?? '',
            niveauClasse: data['niveau'] ?? '',
            matieresIds: matieresAssociees,
            elevesIds: List<String>.from(data['elevesIds'] ?? []), // <-- ajouter ici
          ));
        }
      }

      setState(() {
        classesAvecMatieres = temp;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur: $e")));
      }
      setState(() => loading = false);
    }
  }

  Future<void> _chargerMatieres(String classeId) async {
    matieres.clear();
    final classeDoc = await _firestore.collection('classes').doc(classeId).get();
    final matieresIds = List<String>.from(classeDoc['matieresIds'] ?? []);

    final enseignementsSnap = await _firestore
        .collection('enseignements')
        .where('enseignantId', isEqualTo: enseignantId)
        .get();

    for (var doc in enseignementsSnap.docs) {
      final matId = doc['matiereId'];
      if (matieresIds.contains(matId)) {
        final matDoc = await _firestore.collection('matieres').doc(matId).get();
        matieres.add({'id': matId, 'nom': matDoc['nom']});
      }
    }
    setState(() {});
  }

  Future<void> _chargerEleves(String classeId) async {
    final classeDoc = await _firestore.collection('classes').doc(classeId).get();
    final elevesIds = List<String>.from(classeDoc['elevesIds'] ?? []);

    final futures = elevesIds.map((eleveId) async {
      final eleveDoc = await _firestore.collection('eleves').doc(eleveId).get();
      if (!eleveDoc.exists) return null;

      final utilisateurId = eleveDoc['utilisateurId'];
      final userDoc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
      if (!userDoc.exists) return null;

      return _EleveAvecNom(
        eleveId: eleveDoc.id,
        utilisateurId: utilisateurId,
        nom: userDoc['nom'] ?? 'Nom inconnu',
        prenom: userDoc['prenom'] ?? '',
        notesIds: List<String>.from(eleveDoc['notesIds'] ?? []),
      );
    });

    final results = await Future.wait(futures);

    setState(() {
      eleves = results.whereType<_EleveAvecNom>().toList();
      notesStr.clear();
      descriptionExercice = '';
    });
  }

  String _getMention(double note) {
    if (note >= 16) return "Très bien";
    if (note >= 14) return "Bien";
    if (note >= 12) return "Assez bien";
    if (note >= 10) return "Passable";
    return "Insuffisant";
  }

  Future<void> _enregistrerNotes() async {
    if (classeChoisieId == null || matiereChoisieId == null || typeNote == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sélection incomplète.")));
      return;
    }

    if (typeNote == 'Exercice' && descriptionExercice.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez saisir la description de l'exercice.")));
      return;
    }

    // Ici on accepte que certaines notes soient absentes (notification prévue)
    for (var entry in notesStr.entries) {
      final noteStr = entry.value.trim();
      if (noteStr.isNotEmpty) {
        final noteVal = double.tryParse(noteStr.replaceAll(',', '.'));
        if (noteVal == null || noteVal < 0 || noteVal > 20) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Les notes doivent être entre 0 et 20.")));
          return;
        }
      }
    }

    setState(() => saving = true);

    try {
      final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.now());
      final matiereDoc = await _firestore.collection('matieres').doc(matiereChoisieId).get();
      final matiereNom = matiereDoc.exists ? matiereDoc['nom'] : 'matière inconnue';
      final classe = classesAvecMatieres.firstWhere(
      (c) => c.classeId == classeChoisieId,
      orElse: () => _ClasseAvecMatieres(
        classeId: '',
        nomClasse: '',
        niveauClasse: '',
        matieresIds: [],
        elevesIds:[], // <-- ajouter ici aussi
      ),
    );

// 🔁 Parcours des élèves
for (final eleveId in classe.elevesIds) {
  print("[DEBUG] Chargement des données de l'élève avec ID: $eleveId");

  final eleveDoc = await _firestore.collection('eleves').doc(eleveId).get();
  if (!eleveDoc.exists) continue;

  final eleve = eleveDoc.data()!;
  final utilisateurId = eleve['utilisateurId'];

  String prenom = 'Prénom';
  String nom = 'Nom';

  if (utilisateurId != null) {
    final utilisateurDoc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
    if (utilisateurDoc.exists) {
      final utilisateur = utilisateurDoc.data()!;
      prenom = utilisateur['prenom'] ?? prenom;
      nom = utilisateur['nom'] ?? nom;
    }
  }


  final noteStr = notesStr[eleveId]?.trim() ?? '';
  final hasNote = noteStr.isNotEmpty;
  double? noteVal = hasNote ? double.parse(noteStr.replaceAll(',', '.')) : null;
  String mention = noteVal != null ? _getMention(noteVal) : 'Aucune note';

  String messageParent;
  String messageEleve;
  DocumentReference? noteDoc;

  if (hasNote) {
    noteDoc = await _firestore.collection('notes').add({
      'valeur': noteVal,
      'type': typeNote!,
      'mention': mention,
      'eleveId': eleveId,
      'matiereId': matiereChoisieId!,
      'date': Timestamp.now(),
      if (typeNote == 'Exercice') 'description': descriptionExercice.trim(),
      if (typeNote == 'Examen') 'sequence': sequenceChoisie ?? '',
    });

    await _firestore.collection('eleves').doc(eleveId).update({
      'notesIds': FieldValue.arrayUnion([noteDoc.id]),
    });

    messageParent =
        "Le $dateStr, $prenom $nom a reçu une nouvelle note ($noteVal) en $matiereNom.";
    if (typeNote == 'Exercice') {
      messageParent += " Exercice : \"$descriptionExercice\".";
    } else if (typeNote == 'Examen') {
      messageParent += " Examen : ${sequenceChoisie ?? 'séquence inconnue'}.";
    }

    messageEleve = "Tu as une nouvelle note ($noteVal) en $matiereNom.";
  } else {
    messageParent =
        "Le $dateStr, aucune note n'a été enregistrée pour votre enfant $prenom $nom en $matiereNom.";
    messageEleve =
        "Le $dateStr, aucune note n'a été enregistrée pour toi en $matiereNom.";
  }

  // ✅ Recherche des familles liées à l'élève
  print("[DEBUG] Recherche des familles liées à l'élève $eleveId...");
  final famillesSnap = await _firestore
      .collection('famille')
      .where('eleveId', isEqualTo: eleveId) // ✅ champs conforme à ta structure
      .get();

  print("[DEBUG] ${famillesSnap.docs.length} famille(s) trouvée(s) pour $prenom $nom.");

  for (final familleDoc in famillesSnap.docs) {
    final parentId = familleDoc.data()['parentId'];
    print("[DEBUG] Envoi de la notification au parent : $parentId");

    await _firestore.collection('notifications').add({
    'eleveId': eleveId,
    'parentId': parentId,
    'expediteurRole': 'enseignant',
    'etablissementId': widget.etablissementId, // à adapter selon ton contexte
    'titre': 'Nouvelle note en $matiereNom',
    'message': messageParent,
    'lu': false,
    'createdAt': Timestamp.now(),
    'type': 'note',
    'metadata': {
      'note': noteVal,
      'matiere': matiereNom,
      'typeNote': typeNote,
      if (typeNote == 'Exercice') 'description': descriptionExercice.trim(),
      if (typeNote == 'Examen') 'sequence': sequenceChoisie ?? '',
      if (noteDoc != null) 'noteId': noteDoc.id,
    },
  });

  }

  // ✅ Notification à l’élève
  await _firestore.collection('notifications').add({
    'destinataireId': utilisateurId,
    'type': 'note',
    'message': messageEleve,
    'date': Timestamp.now(),
    'vu': false,
    'eleveId': eleveId,
    if (hasNote && noteDoc != null) 'noteId': noteDoc.id,
  });

  print("[DEBUG] Notification élève envoyée à $utilisateurId\n");
}




      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notes et notifications enregistrées avec succès.")));

      setState(() {
        notesStr.clear();
        descriptionExercice = '';
        typeNote = null;
        sequenceChoisie = null;
        matiereChoisieId = null;
        classeChoisieId = null;
        eleves.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur lors de l'enregistrement : $e")));
    } finally {
      setState(() => saving = false);
    }
  }

  Widget _buildBoutonsChoix<T>({
    required List<T> items,
    required T selected,
    required String Function(T) labelBuilder,
    required void Function(T) onSelected,
    required ButtonStyle style,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) {
        final bool isSelected = item == selected;
        return ChoiceChip(
          label: Text(labelBuilder(item), style: const TextStyle(fontWeight: FontWeight.w600)),
          selected: isSelected,
          onSelected: (_) => onSelected(item),
          selectedColor: style.backgroundColor?.resolve({MaterialState.selected}) ?? Colors.red,
          backgroundColor: style.backgroundColor?.resolve({}) ?? Colors.red.shade100,
          labelStyle: TextStyle(
            color: isSelected
                ? (style.foregroundColor?.resolve({MaterialState.selected}) ?? Colors.white)
                : (style.foregroundColor?.resolve({}) ?? Colors.red.shade900),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        );
      }).toList(),
    );
  }
@override
Widget build(BuildContext context) {
  if (loading) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Choisir la classe
            const Text(
              'Choisir la classe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: classesAvecMatieres.map((c) {
                  final selected = c.classeId == classeChoisieId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${c.nomClasse} (${c.niveauClasse})'),
                      selected: selected,
                      onSelected: (bool select) async {
                        if (!select) return;
                        setState(() {
                          classeChoisieId = c.classeId;
                          matiereChoisieId = null;
                          eleves.clear();
                          notesStr.clear();
                          descriptionExercice = '';
                          typeNote = null;
                          sequenceChoisie = null;
                        });
                        await _chargerMatieres(c.classeId);
                      },
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.pink[50],
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // Choisir la matière
            if (classeChoisieId != null) ...[
              const Text(
                'Choisir la matière',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: matieres.map((m) {
                    final selected = m['id'] == matiereChoisieId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(m['nom'] ?? ''),
                        selected: selected,
                        onSelected: (bool select) async {
                          if (!select) return;
                          setState(() {
                            matiereChoisieId = m['id'];
                            eleves.clear();
                            notesStr.clear();
                            descriptionExercice = '';
                            typeNote = null;
                            sequenceChoisie = null;
                          });
                          await _chargerEleves(classeChoisieId!);
                        },
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Type de note
            const Text(
              'Type de note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: typesNotes.map((t) {
                  final selected = t == typeNote;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: selected,
                      onSelected: (bool select) {
                        if (!select) return;
                        setState(() {
                          typeNote = t;
                          sequenceChoisie = null;
                          descriptionExercice = '';
                          notesStr.clear();
                        });
                      },
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Séquence ou description exercice
            if (typeNote == 'Examen') ...[
              const Text(
                'Séquence',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: sequences.map((s) {
                    final selected = s == sequenceChoisie;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: selected,
                        onSelected: (bool select) {
                          if (!select) return;
                          setState(() => sequenceChoisie = s);
                        },
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.grey[200],
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ] else if (typeNote == 'Exercice') ...[
              TextField(
                decoration: const InputDecoration(
                  labelText: "Description de l'exercice",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                onChanged: (val) => setState(() => descriptionExercice = val),
              ),
              const SizedBox(height: 20),
            ],

            // Liste élèves + saisie notes
            if (eleves.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        for (var e in eleves) {
                          notesStr[e.eleveId] = '20'; // exemple note max à cocher
                        }
                      });
                    },
                    child: const Text('Remplir notes max'),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        notesStr.clear();
                      });
                    },
                    child: const Text('Effacer toutes les notes'),
                    style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: eleves.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final eleve = eleves[index];
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text('${eleve.prenom} ${eleve.nom}', style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Note',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          onChanged: (val) => notesStr[eleve.eleveId] = val,
                          controller: TextEditingController(text: notesStr[eleve.eleveId] ?? ''),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],

            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer'),
                onPressed: saving ? null : _enregistrerNotes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}





class _ClasseAvecMatieres {
  final String classeId;
  final String nomClasse;
  final String niveauClasse;
  final List<String> matieresIds;
  final List<String> elevesIds; // <-- ajouter ici


  _ClasseAvecMatieres({
    required this.classeId,
    required this.nomClasse,
    required this.niveauClasse,
    required this.matieresIds,
    required this.elevesIds, // <-- ajouter ici aussi

  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ClasseAvecMatieres &&
          runtimeType == other.runtimeType &&
          classeId == other.classeId;

  @override
  int get hashCode => classeId.hashCode;
}

class _EleveAvecNom {
  final String eleveId;
  final String utilisateurId;
  final String nom;
  final String prenom;
  final List<String> notesIds;

  _EleveAvecNom({
    required this.eleveId,
    required this.utilisateurId,
    required this.nom,
    required this.prenom,
    required this.notesIds,
  });
}
