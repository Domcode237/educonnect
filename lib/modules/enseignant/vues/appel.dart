import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../depos/depot_notification.dart';
import '../modeles/model_notification.dart';
import 'package:educonnect/donnees/modeles/famille_modele.dart';

class AppelPage extends StatefulWidget {
  final String etablissementId;
  final String utilisateurId;

  const AppelPage({
    super.key,
    required this.etablissementId,
    required this.utilisateurId,
  });

  @override
  State<AppelPage> createState() => _AppelPageState();
}

class _AppelPageState extends State<AppelPage> {
  final _firestore = FirebaseFirestore.instance;
  final _depotNotif = DepotNotification();
  String? enseignantId;
  String? classeChoisieId;
  String? matiereChoisieId;
  String? matiereChoisieNom;
  List<_ClasseAvecMatieres> classesAvecMatieres = [];
  List<Map<String, String>> matieres = [];
  List<Map<String, dynamic>> eleves = [];
  Set<String> presents = {};
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _prepareLocaleAndData();
  }

  Future<void> _prepareLocaleAndData() async {
    await initializeDateFormatting('fr_FR');
    await _initData();
  }

  Future<void> _initData() async {
    try {
      final snap = await _firestore
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;
      enseignantId = snap.docs.first.id;

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

      final temp = <_ClasseAvecMatieres>[];
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
            nomClasse: data['nom'],
            niveauClasse: data['niveau'],
            matieresIds: matieresAssociees,
          ));
        }
      }

      setState(() {
        classesAvecMatieres = temp;
        loading = false;
      });
    } catch (_) {
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
    final doc = await _firestore.collection('classes').doc(classeId).get();
    final ids = List<String>.from(doc['elevesIds'] ?? []);

    final futures = ids.map((id) async {
      final eDoc = await _firestore.collection('eleves').doc(id).get();
      if (!eDoc.exists) return null;
      final uId = eDoc['utilisateurId'];
      final uDoc = await _firestore.collection('utilisateurs').doc(uId).get();
      if (!uDoc.exists) return null;
      return {
        'eleveId': id,
        'prenom': uDoc['prenom'],
        'nom': uDoc['nom'],
        'photo': uDoc['photo']
      };
    });

    final results = await Future.wait(futures);
    setState(() {
      eleves = results.whereType<Map<String, dynamic>>().toList();
      presents.clear();
    });
  }

  void _toutCocher() {
    setState(() {
      presents = eleves.map((e) => e['eleveId'] as String).toSet();
    });
  }

  void _toutDecocher() {
    setState(() => presents.clear());
  }

  Future<void> enregistrerAppel() async {
    if (classeChoisieId == null || matiereChoisieId == null || enseignantId == null) return;

    setState(() => saving = true);
    final absents = eleves.map((e) => e['eleveId']).where((id) => !presents.contains(id)).toList();

    await _firestore.collection('appels').add({
      'classeId': classeChoisieId,
      'matiereId': matiereChoisieId,
      'enseignantId': enseignantId,
      'etablissementId': widget.etablissementId,
      'elevesPresents': presents.toList(),
      'elevesAbsents': absents,
      'createdAt': Timestamp.now(),
      'date': Timestamp.now(),
    });

    if (absents.isNotEmpty) {
      final famillesSnap = await _firestore
          .collection('famille')
          .where('eleveId', whereIn: absents)
          .get();

      final noms = {for (var e in eleves) e['eleveId']: "${e['prenom']} ${e['nom']}"};
      final now = DateTime.now().toLocal();

      String formaterDateAvecContexte(DateTime date) {
        final localDate = date.toLocal();

        final heure = DateFormat('HH:mm', 'fr_FR').format(localDate);

        if (now.year == localDate.year && now.month == localDate.month && now.day == localDate.day) {
          return "aujourd’hui à $heure";
        } else if (now.subtract(const Duration(days: 1)).year == localDate.year &&
            now.subtract(const Duration(days: 1)).month == localDate.month &&
            now.subtract(const Duration(days: 1)).day == localDate.day) {
          return "hier à $heure";
        } else {
          final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(localDate);
          return "$dateStr à $heure";
        }
      }

      final dateStr = formaterDateAvecContexte(now);
      List<NotificationModele> notifs = [];

      for (var doc in famillesSnap.docs) {
        final famille = FamilleModele.fromMap(doc.data(), doc.id);
        notifs.add(NotificationModele(
          id: '',
          eleveId: famille.eleveId,
          parentId: famille.parentId,
          expediteurId: enseignantId!,
          expediteurRole: 'enseignant',
          etablissementId: widget.etablissementId,
          titre: 'Absence',
          message:
              "Le $dateStr, ${noms[famille.eleveId] ?? 'votre enfant'} était absent(e) en ${_getNomMatiere()} (${_getNomClasse()}).",
          lu: false,
          createdAt: DateTime.now(),
          type: 'absence',
          metadata: {'classeId': classeChoisieId!, 'matiereId': matiereChoisieId!},
        ));
      }

      await _depotNotif.ajouterNotificationsParLot(notifs);
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appel enregistré.")));

    setState(() {
      classeChoisieId = null;
      matiereChoisieId = null;
      matiereChoisieNom = null;
      matieres.clear();
      eleves.clear();
      presents.clear();
      saving = false;
    });
  }

  String _getNomClasse() => classesAvecMatieres
      .firstWhere((c) => c.classeId == classeChoisieId,
          orElse: () => _ClasseAvecMatieres(classeId: '', nomClasse: '...', niveauClasse: '', matieresIds: []))
      .nomClasse;

  String _getNomMatiere() => matiereChoisieNom ?? '...';

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choisir la classe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                        onSelected: (selected) async {
                          if (selected) {
                            setState(() {
                              classeChoisieId = c.classeId;
                              matiereChoisieId = null;
                              matiereChoisieNom = null;
                              matieres.clear();
                              eleves.clear();
                              presents.clear();
                            });
                            await _chargerMatieres(c.classeId);
                          }
                        },
                        selectedColor: Colors.teal,
                        backgroundColor: Colors.pink[50],
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (classeChoisieId != null) ...[
                const Text('Choisir la matière', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                          onSelected: (selected) async {
                            if (selected) {
                              setState(() {
                                matiereChoisieId = m['id'];
                                matiereChoisieNom = m['nom'];
                                eleves.clear();
                                presents.clear();
                              });
                              await _chargerEleves(classeChoisieId!);
                            }
                          },
                          selectedColor: Colors.teal,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (eleves.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _toutCocher,
                      child: const Text('Tout marquer présent'),
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                    ),
                    TextButton(
                      onPressed: _toutDecocher,
                      child: const Text('Tout marquer absent'),
                      style: TextButton.styleFrom(foregroundColor: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: eleves.length,
                  itemBuilder: (context, index) {
                    final e = eleves[index];
                    final id = e['eleveId'];
                    return CheckboxListTile(
                      title: Text('${e['prenom']} ${e['nom']}'),
                      value: presents.contains(id),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            presents.add(id);
                          } else {
                            presents.remove(id);
                          }
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: saving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Valider et Notifier'),
                    onPressed: saving ? null : enregistrerAppel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
              ] else if (classeChoisieId != null && matiereChoisieId != null) ...[
                const Center(child: Text('Aucun élève')),
              ],
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

  _ClasseAvecMatieres({
    required this.classeId,
    required this.nomClasse,
    required this.niveauClasse,
    required this.matieresIds,
  });
}
