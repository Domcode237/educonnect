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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DepotNotification _depotNotif = DepotNotification();

  String? enseignantId;
  List<_ClasseAvecMatieres> classesAvecMatieres = [];
  String? classeChoisieId;
  String? matiereChoisieId;
  String? matiereChoisieNom;
  List<Map<String, dynamic>> eleves = [];
  Set<String> presents = {};
  bool loading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _prepareLocaleAndData();
  }

  Future<void> _prepareLocaleAndData() async {
    await initializeDateFormatting('fr_FR', null);
    await _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);
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

      final enseignementsMatieres = enseignementsSnap.docs
          .map((d) => d.data()['matiereId'] as String)
          .toSet();

      List<_ClasseAvecMatieres> temp = [];

      for (final classeDoc in classesSnap.docs) {
        final data = classeDoc.data();
        final enseignantsIds = List<String>.from(data['enseignantsIds'] ?? []);
        if (!enseignantsIds.contains(enseignantId)) {
          continue;
        }

        final classeMatieres = List<String>.from(data['matieresIds'] ?? []);
        final matieresPourEnseignant = classeMatieres
            .where((m) => enseignementsMatieres.contains(m))
            .toList();

        if (matieresPourEnseignant.isNotEmpty) {
          temp.add(_ClasseAvecMatieres(
            classeId: classeDoc.id,
            nomClasse: data['nom'] ?? '',
            niveauClasse: data['niveau'] ?? '',
            matieresIds: matieresPourEnseignant,
          ));
        }
      }

      setState(() => classesAvecMatieres = temp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors du chargement : $e")),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchEleves(String classeId) async {
    setState(() {
      loading = true;
      eleves.clear();
      presents.clear();
    });

    try {
      final classeDoc = await _firestore.collection('classes').doc(classeId).get();
      final elevesIds = List<String>.from(classeDoc['elevesIds'] ?? []);

      final elevesFutures = elevesIds.map((eleveId) async {
        final eleveDoc = await _firestore.collection('eleves').doc(eleveId).get();
        if (!eleveDoc.exists) return null;

        final utilisateurId = eleveDoc['utilisateurId'];
        final utilisateurDoc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
        if (!utilisateurDoc.exists) return null;

        return {
          'eleveId': eleveId,
          'utilisateurId': utilisateurId,
          'nom': utilisateurDoc['nom'],
          'prenom': utilisateurDoc['prenom'],
          'photo': utilisateurDoc['photo'],
        };
      });

      final results = await Future.wait(elevesFutures);
      setState(() => eleves = results.whereType<Map<String, dynamic>>().toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur chargement élèves : $e")),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> enregistrerAppel() async {
    if (classeChoisieId == null || matiereChoisieId == null || enseignantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une classe et matière.")),
      );
      return;
    }

    setState(() => saving = true);

    try {
      final absents = eleves
          .map((e) => e['eleveId'] as String)
          .where((id) => !presents.contains(id))
          .toList();

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

        final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
        final dateStr = dateFormat.format(DateTime.now());

        final Map<String, String> eleveNoms = {
          for (var e in eleves)
            e['eleveId'] as String: "${e['prenom']} ${e['nom']}"
        };

        List<NotificationModele> notifications = [];

        for (final doc in famillesSnap.docs) {
          final famille = FamilleModele.fromMap(doc.data(), doc.id);
          final nomEleve = eleveNoms[famille.eleveId] ?? "votre enfant";

          notifications.add(NotificationModele(
            id: '',
            eleveId: famille.eleveId,
            parentId: famille.parentId,
            expediteurId: enseignantId!,
            expediteurRole: 'enseignant',
            etablissementId: widget.etablissementId,
            titre: 'Alerte d\'absence',
            message:
                "Le $dateStr, $nomEleve est absent(e) en classe ${_getNomClasse()} pour la matière ${_getNomMatiere()}.",
            lu: false,
            createdAt: DateTime.now(),
            type: 'absence',
            metadata: {
              'classeId': classeChoisieId!,
              'matiereId': matiereChoisieId!,
            },
          ));
        }

        await _depotNotif.ajouterNotificationsParLot(notifications);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appel enregistré et notifications envoyées.")),
        );
        setState(() {
          classeChoisieId = null;
          matiereChoisieId = null;
          matiereChoisieNom = null;
          eleves.clear();
          presents.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur appel/notification : $e")),
        );
      }
    } finally {
      setState(() => saving = false);
    }
  }

  String _getNomClasse() {
    final classe = classesAvecMatieres.firstWhere(
      (c) => c.classeId == classeChoisieId,
      orElse: () => _ClasseAvecMatieres(
        classeId: '',
        nomClasse: 'inconnue',
        niveauClasse: '',
        matieresIds: [],
      ),
    );
    return classe.nomClasse;
  }

  String _getNomMatiere() => matiereChoisieNom ?? 'inconnue';

  Future<List<Map<String, String>>> _fetchMatieresForClasse(
      String enseignantId, String classeId) async {
    final enseignementsSnap = await _firestore
        .collection('enseignements')
        .where('enseignantId', isEqualTo: enseignantId)
        .get();

    final classeDoc = await _firestore.collection('classes').doc(classeId).get();
    final classeMatieres = List<String>.from(classeDoc['matieresIds'] ?? []);

    final List<Map<String, String>> matieres = [];
    for (final doc in enseignementsSnap.docs) {
      final matiereId = doc['matiereId'];
      if (classeMatieres.contains(matiereId)) {
        final matiereDoc = await _firestore.collection('matieres').doc(matiereId).get();
        if (matiereDoc.exists) {
          matieres.add({'id': matiereId, 'nom': matiereDoc['nom']});
        }
      }
    }

    return matieres;
  }

  @override
  Widget build(BuildContext context) {
    if (loading || enseignantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<String>(
              value: classeChoisieId,
              hint: const Text("Choisir classe"),
              isExpanded: true,
              items: classesAvecMatieres
                  .map((c) => DropdownMenuItem(
                        value: c.classeId,
                        child: Text("${c.nomClasse} (${c.niveauClasse})"),
                      ))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  classeChoisieId = val;
                  matiereChoisieId = null;
                  matiereChoisieNom = null;
                  eleves.clear();
                  presents.clear();
                });
              },
            ),
            if (classeChoisieId != null && enseignantId != null)
              FutureBuilder<List<Map<String, String>>>(
                future: _fetchMatieresForClasse(
                    enseignantId!, classeChoisieId!),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snap.hasError) {
                    return const Text("Erreur chargement matières");
                  }
                  final data = snap.data ?? [];
                  return DropdownButton<String>(
                    value: matiereChoisieId,
                    hint: const Text("Choisir matière"),
                    isExpanded: true,
                    items: data
                        .map((m) => DropdownMenuItem(
                              value: m['id'],
                              child: Text(m['nom'] ?? ''),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      setState(() {
                        matiereChoisieId = val;
                        eleves.clear();
                        presents.clear();
                        matiereChoisieNom = null;
                      });
                      if (val != null && classeChoisieId != null && enseignantId != null) {
                        final mats = await _fetchMatieresForClasse(
                            enseignantId!, classeChoisieId!);
                        final matSelectionnee = mats.firstWhere(
                            (m) => m['id'] == val,
                            orElse: () => {'nom': 'inconnue'});
                        setState(() {
                          matiereChoisieNom = matSelectionnee['nom'];
                        });
                        await fetchEleves(classeChoisieId!);
                      }
                    },
                  );
                },
              ),
            const Divider(),
            Expanded(
              child: eleves.isEmpty
                  ? const Center(child: Text("Aucun élève"))
                  : ListView(
                      children: eleves.map((e) {
                        final eleveId = e['eleveId'] as String;
                        return CheckboxListTile(
                          title: Text("${e['prenom']} ${e['nom']}"),
                          value: presents.contains(eleveId),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                presents.add(eleveId);
                              } else {
                                presents.remove(eleveId);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
            ),
            ElevatedButton(
              onPressed: saving ? null : enregistrerAppel,
              child: saving
                  ? const CircularProgressIndicator()
                  : const Text("Valider et Notifier"),
            ),
          ],
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
