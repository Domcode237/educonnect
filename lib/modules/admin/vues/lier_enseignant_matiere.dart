import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/MatiereModele.dart';
import 'package:educonnect/donnees/depots/depos_enseignement.dart';

class LierEnseignantMatierePage extends StatefulWidget {
  final UtilisateurModele enseignant;
  final String etablissementId;

  const LierEnseignantMatierePage({
    super.key,
    required this.enseignant,
    required this.etablissementId,
  });

  @override
  State<LierEnseignantMatierePage> createState() => _LierEnseignantMatierePageState();
}

class _LierEnseignantMatierePageState extends State<LierEnseignantMatierePage> {
  final TextEditingController _searchController = TextEditingController();
  final EnseignementDepot _enseignementDepot = EnseignementDepot();

  List<MatiereModele> _matieres = [];
  List<MatiereModele> _filteredMatieres = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _chargerMatieres();
    _searchController.addListener(_filtrerMatieres);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargerMatieres() async {
    setState(() => _loading = true);
    final snapshot = await FirebaseFirestore.instance
        .collection('matieres')
        .where('etablissementId', isEqualTo: widget.etablissementId)
        .get();

    _matieres = snapshot.docs.map((doc) => MatiereModele.fromMap(doc.data(), doc.id)).toList();

    _filteredMatieres = List.from(_matieres);
    setState(() => _loading = false);
  }

  void _filtrerMatieres() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMatieres = _matieres
          .where((m) => m.nom.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _lierMatiere(MatiereModele matiere) async {
    try {
      // 1. Récupérer l'ID enseignant correspondant à l'utilisateur
      final enseignantSnap = await FirebaseFirestore.instance
          .collection('enseignants')
          .where('utilisateurId', isEqualTo: widget.enseignant.id)
          .limit(1)
          .get();

      if (enseignantSnap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun enseignant trouvé pour cet utilisateur.")),
        );
        return;
      }

      final enseignantId = enseignantSnap.docs.first.id;

      // 2. Ajouter l'enseignement avec l'ID enseignant (pas utilisateur)
      await _enseignementDepot.ajouterEnseignement(enseignantId, matiere.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("La matière '${matiere.nom}' a été liée à l'enseignant.")),
      );

      Navigator.of(context).pop(true); // signaler la mise à jour à la page précédente
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la liaison : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 19, 51, 76);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lier enseignant à une matière"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Rechercher une matière",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredMatieres.isEmpty
                      ? const Center(child: Text("Aucune matière trouvée."))
                      : ListView.separated(
                          itemCount: _filteredMatieres.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final matiere = _filteredMatieres[index];
                            return ListTile(
                              title: Text(matiere.nom),
                              subtitle: Text("Coefficient: ${matiere.coefficient}"),
                              trailing: ElevatedButton(
                                onPressed: () => _lierMatiere(matiere),
                                child: const Text("Lier"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
