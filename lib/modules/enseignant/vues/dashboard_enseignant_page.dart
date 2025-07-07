import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/MatiereModele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';

class DashboardEnseignantPage extends StatefulWidget {
  final UtilisateurModele enseignant;

  const DashboardEnseignantPage({super.key, required this.enseignant});

  @override
  State<DashboardEnseignantPage> createState() => _DashboardEnseignantPageState();
}

class _DashboardEnseignantPageState extends State<DashboardEnseignantPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  String? _etablissementNom;
  String? _enseignantId;

  // Map classeNom -> List des matières de cette classe
  Map<String, List<_MatiereAvecCoef>> _matieresParClasse = {};

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    setState(() => _loading = true);

    try {
      // Charger nom de l’établissement
      if (widget.enseignant.etablissementId.isNotEmpty) {
        final etabDoc = await _firestore
            .collection('etablissements')
            .doc(widget.enseignant.etablissementId)
            .get();
        if (etabDoc.exists) {
          _etablissementNom = etabDoc.get('nom');
        }
      }

      // Trouver ID interne de l’enseignant
      final enseignantSnap = await _firestore
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.enseignant.id)
          .limit(1)
          .get();

      if (enseignantSnap.docs.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      _enseignantId = enseignantSnap.docs.first.id;

      // Charger les matières enseignées
      final enseignementsSnap = await _firestore
          .collection('enseignements')
          .where('enseignantId', isEqualTo: _enseignantId)
          .get();

      final Set<String> matiereIds = enseignementsSnap.docs
          .map((doc) => doc.data()['matiereId'] as String)
          .toSet();

      Map<String, List<_MatiereAvecCoef>> tempMatieresParClasse = {};

      for (final matiereId in matiereIds) {
        final matiereDoc = await _firestore.collection('matieres').doc(matiereId).get();
        if (!matiereDoc.exists) continue;
        final matiere = MatiereModele.fromMap(matiereDoc.data()!, matiereDoc.id);

        final classesSnap = await _firestore
            .collection('classes')
            .where('matieresIds', arrayContains: matiereId)
            .get();

        for (final classeDoc in classesSnap.docs) {
          final classeData = classeDoc.data();
          final enseignantsIds = List<String>.from(classeData['enseignantsIds'] ?? []);
          if (!enseignantsIds.contains(_enseignantId)) continue;

          final classe = ClasseModele.fromMap(classeData, classeDoc.id);

          tempMatieresParClasse.putIfAbsent(classe.nom, () => []);
          tempMatieresParClasse[classe.nom]!.add(
            _MatiereAvecCoef(matiere.nom, matiere.coefficient),
          );
        }
      }

      setState(() {
        _matieresParClasse = tempMatieresParClasse;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  const Text(
                    "Matières par classe",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_matieresParClasse.isEmpty)
                    const Text("Aucune matière liée."),
                  ..._matieresParClasse.entries.map((entry) {
                    return _buildClasseSection(entry.key, entry.value);
                  }).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bienvenue ${widget.enseignant.prenom} ${widget.enseignant.nom}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_etablissementNom != null)
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _etablissementNom!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildClasseSection(String classeNom, List<_MatiereAvecCoef> matieres) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            classeNom,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matieres.length,
            itemBuilder: (context, index) {
              final matiere = matieres[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  "${matiere.nom} (Coef. ${matiere.coefficient})",
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MatiereAvecCoef {
  final String nom;
  final double coefficient;

  _MatiereAvecCoef(this.nom, this.coefficient);
}
