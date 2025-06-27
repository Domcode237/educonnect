import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/MatiereModele.dart';
import 'package:educonnect/donnees/depots/depos_enseignement.dart';
import 'package:educonnect/modules/admin/vues/lier_enseignant_matiere.dart';

// Importe le client Appwrite global que tu utilises (comme dans ListeEnseignants)
import 'package:educonnect/main.dart'; // <-- ici où est déclaré appwriteClient

class DetailsEnseignant extends StatefulWidget {
  final UtilisateurModele enseignant;

  const DetailsEnseignant({super.key, required this.enseignant});

  @override
  State<DetailsEnseignant> createState() => _DetailsEnseignantState();
}

class _DetailsEnseignantState extends State<DetailsEnseignant> {
  final EnseignementDepot _enseignementDepot = EnseignementDepot();

  late final String etablissementId;
  List<MatiereModele> _matieresEnseignees = [];
  bool _loading = true;

  String? _enseignantId; // ID Firestore de l'enseignant (dans collection enseignants)

  // Variable locale pour URL photo construite
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    etablissementId = widget.enseignant.etablissementId;

    _photoUrl = _getAppwriteImageUrl(widget.enseignant.photo);

    _initEnseignantIdEtChargerMatieres();
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Future<void> _initEnseignantIdEtChargerMatieres() async {
    setState(() => _loading = true);

    final enseignantSnap = await FirebaseFirestore.instance
        .collection('enseignants')
        .where('utilisateurId', isEqualTo: widget.enseignant.id)
        .limit(1)
        .get();

    if (enseignantSnap.docs.isEmpty) {
      setState(() {
        _matieresEnseignees = [];
        _loading = false;
      });
      return;
    }

    _enseignantId = enseignantSnap.docs.first.id;

    final enseignements = await _enseignementDepot.getEnseignementsPourEnseignant(_enseignantId!);

    final matiereIds = enseignements.map((e) => e.matiereId).toList();

    if (matiereIds.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('matieres')
          .where(FieldPath.documentId, whereIn: matiereIds)
          .get();

      setState(() {
        _matieresEnseignees = snapshot.docs
            .map((doc) => MatiereModele.fromMap(doc.data(), doc.id))
            .toList();
        _loading = false;
      });
    } else {
      setState(() {
        _matieresEnseignees = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 19, 51, 76);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de l'enseignant"),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSectionTitle("Informations Personnelles"),
            _buildInfoRow(Icons.person, "Nom complet", "${widget.enseignant.nom} ${widget.enseignant.prenom}"),
            _buildInfoRow(Icons.email, "Email", widget.enseignant.email),
            _buildInfoRow(Icons.phone, "Téléphone", widget.enseignant.numeroTelephone),
            _buildInfoRow(Icons.home, "Adresse", widget.enseignant.adresse),
            _buildInfoRow(Icons.badge, "Statut", widget.enseignant.statut ? "Actif" : "Inactif"),
            const SizedBox(height: 30),
            _buildSectionTitle("Matières Enseignées"),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_matieresEnseignees.isEmpty)
              const Text("Aucune matière liée pour cet enseignant.")
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _matieresEnseignees.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final matiere = _matieresEnseignees[index];
                  return ListTile(
                    title: Text(matiere.nom),
                    subtitle: Text("Coefficient: ${matiere.coefficient}"),
                    leading: const Icon(Icons.book, color: Colors.blue),
                  );
                },
              ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LierEnseignantMatierePage(
                        enseignant: widget.enseignant,
                        etablissementId: etablissementId,
                      ),
                    ),
                  );
                  if (updated == true) {
                    _initEnseignantIdEtChargerMatieres();
                  }
                },
                icon: const Icon(Icons.link),
                label: const Text("Lier à une matière"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
            child: _photoUrl == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 12),
          Text(
            "${widget.enseignant.nom} ${widget.enseignant.prenom}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            widget.enseignant.email,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Color.fromARGB(255, 25, 49, 82),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : "Non renseigné",
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
