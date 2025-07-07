import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // On garde juste pour formatter la date affichée

import 'package:appwrite/appwrite.dart';
import '../modeles/DevoirModele.dart';
import '../depos/devoir_repository.dart';
import 'ListeDevoirsPage.dart';
  import 'dart:io';
import 'dart:typed_data';

class CreationDevoirPage extends StatefulWidget {
  final String enseignantUtilisateurId;
  final String etablissementId;

  const CreationDevoirPage({
    super.key,
    required this.enseignantUtilisateurId,
    required this.etablissementId,
  });

  @override
  State<CreationDevoirPage> createState() => _CreationDevoirPageState();
}

class _CreationDevoirPageState extends State<CreationDevoirPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Appwrite stockage
  late final Client _appwriteClient;
  late final Storage _storage;

  String? _enseignantDocId;

  // Classes et matières selon enseignant & établissement
  List<_ClasseAvecMatieres> _classesAvecMatieres = [];

  String? _classeSelectionneeId;
  List<DocumentSnapshot> _matieres = [];
  String? _matiereSelectionneeId;

  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _dateRemise;
  PlatformFile? _fichier;

  bool _loading = true;
  bool _loadingMatieres = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _appwriteClient = Client()
        .setEndpoint('https://cloud.appwrite.io/v1') // Remplacer
        .setProject('6853190c0001df11877c'); // Remplacer
    _storage = Storage(_appwriteClient);

    _chargerEnseignantEtClasses();
  }

  Future<void> _chargerEnseignantEtClasses() async {
    setState(() => _loading = true);
    try {
      // 1. Trouver doc enseignant à partir de utilisateurId
      final enseignantSnap = await _firestore
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.enseignantUtilisateurId)
          .limit(1)
          .get();

      if (enseignantSnap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Enseignant introuvable")));
        }
        setState(() => _loading = false);
        return;
      }

      _enseignantDocId = enseignantSnap.docs.first.id;

      // 2. Charger toutes les classes de l'établissement où enseignant est inscrit
      final classesSnap = await _firestore
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      // 3. Charger enseignements (matières enseignées par cet enseignant)
      final enseignementsSnap = await _firestore
          .collection('enseignements')
          .where('enseignantId', isEqualTo: _enseignantDocId)
          .get();

      final enseignementsMatieres = enseignementsSnap.docs
          .map((d) => d.data()['matiereId'] as String)
          .toSet();

      // 4. Filtrer classes où enseignant appartient + matières enseignées dans la classe
      List<_ClasseAvecMatieres> temp = [];

      for (final classeDoc in classesSnap.docs) {
        final data = classeDoc.data();
        final enseignantsIds = List<String>.from(data['enseignantsIds'] ?? []);
        if (!enseignantsIds.contains(_enseignantDocId)) continue;

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

      setState(() {
        _classesAvecMatieres = temp;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur chargement: $e')));
      }
      setState(() => _loading = false);
    }
  }

  // Charge les documents matières selon classe sélectionnée
  Future<void> _chargerMatieresPourClasse(String classeId) async {
    setState(() {
      _loadingMatieres = true;
      _matieres = [];
      _matiereSelectionneeId = null;
    });

    try {
      final classe = _classesAvecMatieres.firstWhere(
          (c) => c.classeId == classeId,
          orElse: () => _ClasseAvecMatieres(
              classeId: '', nomClasse: '', niveauClasse: '', matieresIds: []));

      if (classe.matieresIds.isEmpty) {
        setState(() {
          _matieres = [];
          _loadingMatieres = false;
        });
        return;
      }

      final matieresSnapshot = await _firestore
          .collection('matieres')
          .where(FieldPath.documentId, whereIn: classe.matieresIds)
          .get();

      setState(() {
        _matieres = matieresSnapshot.docs;
        _loadingMatieres = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur chargement matières : $e')));
      }
      setState(() => _loadingMatieres = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRemise ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      // locale retirée volontairement
      builder: (context, child) =>
          Theme(data: Theme.of(context), child: child ?? const SizedBox.shrink()),
    );
    if (picked != null) {
      setState(() => _dateRemise = picked);
    }
  }

  Future<void> _choisirFichier() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fichier = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erreur sélection fichier : $e")));
      }
    }
  }



Future<String?> _uploadFichierAppwrite(PlatformFile fichier) async {
  try {
    Uint8List? fileBytes;

    if (fichier.bytes != null) {
      // Sur le web (ou si bytes dispo)
      fileBytes = fichier.bytes;
    } else if (fichier.path != null) {
      // Sur mobile, lire le fichier à partir du path
      final file = File(fichier.path!);
      fileBytes = await file.readAsBytes();
    } else {
      throw Exception("Le fichier ne contient pas de données et pas de chemin");
    }

    const bucketId = '6854df330032c7be516c'; // Remplacer ici

    final result = await _storage.createFile(
      bucketId: bucketId,
      fileId: ID.unique(),
      file: InputFile(
        bytes: fileBytes!,
        filename: fichier.name,
      ),
    );

    return result.$id;
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur upload fichier : $e")));
    }
    return null;
  }
}

Future<List<String>> _chargerParentsDesEleves(List<String> elevesIds) async {
  try {
    if (elevesIds.isEmpty) {
      return [];
    }

    // Firestore limite 10 éléments max dans whereIn
    const int batchSize = 10;
    List<String> allParentIds = [];

    for (var i = 0; i < elevesIds.length; i += batchSize) {
      final batch = elevesIds.sublist(i, i + batchSize > elevesIds.length ? elevesIds.length : i + batchSize);

      final famillesSnap = await _firestore
          .collection('famille')
          .where('eleveId', whereIn: batch)
          .get();


      final parentIdsBatch = famillesSnap.docs.map((doc) {
        final data = doc.data();
        final parentId = data['parentId'];
        return parentId as String;
      }).toSet().toList();

      allParentIds.addAll(parentIdsBatch);
    }

    final uniqueParentIds = allParentIds.toSet().toList();
    return uniqueParentIds;
  } catch (e, stacktrace) {
    return [];
  }
}




  Future<List<String>> _chargerElevesIdsDeClasse(String classeId) async {
    try {
      final classeDoc =
          await _firestore.collection('classes').doc(classeId).get();
      if (classeDoc.exists) {
        return List<String>.from(classeDoc.data()?['elevesIds'] ?? []);
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_classeSelectionneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une classe')));
      return;
    }
    if (_matiereSelectionneeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une matière')));
      return;
    }
    if (_dateRemise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez choisir une date de remise')));
      return;
    }
    if (_enseignantDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Identifiant enseignant introuvable")));
      return;
    }

    setState(() => _submitting = true);

    try {
      String? fichierId;
      String? fichierType;

      if (_fichier != null) {
        fichierId = await _uploadFichierAppwrite(_fichier!);
        if (fichierId == null) throw Exception("Erreur upload fichier");
        fichierType = _fichier!.extension;
      }

      final elevesIds = await _chargerElevesIdsDeClasse(_classeSelectionneeId!);
      final parentIds = await _chargerParentsDesEleves(elevesIds);


      final devoir = DevoirModele(
        id: '',
        titre: _titreController.text.trim(),
        description: _descriptionController.text.trim(),
        etablissementId: widget.etablissementId,
        classeId: _classeSelectionneeId!,
        matiereId: _matiereSelectionneeId!,
        enseignantId: _enseignantDocId!,
        eleveIds: elevesIds,
        parentIds: parentIds,
        lusPar: [],
        dateRemise: _dateRemise!,
        fichierUrl: fichierId,
        fichierType: fichierType,
        dateCreation: DateTime.now(),
      );

      final repo = DevoirRepository();
      await repo.ajouterDevoir(devoir);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Devoir envoyé avec succès')));
        //Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

   return Scaffold(
  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Form(
      key: _formKey,
      child: ListView(
        children: [
          // Dropdowns Classe & Matière côte à côte
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  menuMaxHeight: 300,
                  isDense: true,
                  style: const TextStyle(fontSize: 14),
                  itemHeight: 48,
                  decoration: InputDecoration(
                    labelText: 'Classe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    isDense: true, // Option supplémentaire
                  ),
                  value: _classeSelectionneeId,
                  items: _classesAvecMatieres
                      .map((c) => DropdownMenuItem(
                            value: c.classeId,
                            child: Text(
                              '${c.nomClasse} (${c.niveauClasse})',
                              overflow: TextOverflow.ellipsis, 
                              style: const TextStyle(color: Colors.black),// Pour les textes longs
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _classeSelectionneeId = val;
                      _matiereSelectionneeId = null;
                      _matieres = [];
                    });
                    if (val != null) _chargerMatieresPourClasse(val);
                  },
                  validator: (val) => val == null ? 'Choisissez une classe' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _loadingMatieres
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Matière',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        value: _matiereSelectionneeId,
                        items: _matieres
                            .map(
                              (doc) => DropdownMenuItem(
                                value: doc.id,
                                child: Text(doc['nom'] ?? 'Matière'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() => _matiereSelectionneeId = val);
                        },
                        validator: (val) => val == null ? 'Choisissez une matière' : null,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Titre
          TextFormField(
            controller: _titreController,
            decoration: InputDecoration(
              labelText: 'Titre du devoir',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Entrez un titre' : null,
          ),
          const SizedBox(height: 20),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            maxLines: 4,
            validator: (val) =>
                val == null || val.trim().isEmpty ? 'Entrez une description' : null,
          ),
          const SizedBox(height: 20),

          // Date de remise
          Row(
            children: [
              Expanded(
                child: Text(
                  _dateRemise == null
                      ? 'Date de remise non choisie'
                      : 'Date de remise : ${DateFormat('dd/MM/yyyy').format(_dateRemise!)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: _pickDate,
                child: const Text('Choisir date'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fichier
          ListTile(
            title: Text(
              _fichier == null ? 'Aucun fichier sélectionné' : _fichier!.name,
              style: const TextStyle(fontSize: 16),
            ),
            trailing: ElevatedButton(
              onPressed: _choisirFichier,
              child: const Text('Joindre un fichier (optionnel)'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 30),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  : const Text(
                      'Envoyer le devoir',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  floatingActionButton: FloatingActionButton(
    backgroundColor:  Colors.grey,
    foregroundColor: Colors.black,
  onPressed: () {
    if (_enseignantDocId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListeDevoirsPage(enseignantId: _enseignantDocId!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de charger les devoirs, identifiant enseignant introuvable")),
      );
    }
  },
  tooltip: 'Voir devoirs soumis',
  child: const Icon(Icons.list_alt),
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
