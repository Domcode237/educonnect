import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/main.dart';

import 'note_enfant.dart';

class ListeEnfantsPage extends StatefulWidget {
  final String parentId;
  final String etablissementId;

  const ListeEnfantsPage({
    Key? key,
    required this.parentId,
    required this.etablissementId,
  }) : super(key: key);

  @override
  State<ListeEnfantsPage> createState() => _ListeEnfantsPageState();
}

class _ListeEnfantsPageState extends State<ListeEnfantsPage> {
  bool isLoading = true;
  List<_EnfantDetail> enfantsDetails = [];
  List<ClasseModele> classes = [];

  @override
  void initState() {
    super.initState();
    _chargerEnfantsLies();
  }

  Future<void> _chargerEnfantsLies() async {
    try {
      setState(() => isLoading = true);

      final clsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();
      classes = clsSnap.docs.map((d) => ClasseModele.fromMap(d.data(), d.id)).toList();

      final familleSnap = await FirebaseFirestore.instance
          .collection('famille')
          .where('parentId', isEqualTo: widget.parentId)
          .get();

      final List<String> eleveIdsLies = familleSnap.docs
          .map((doc) => doc.data()['eleveId'] as String)
          .toList();

      if (eleveIdsLies.isEmpty) {
        setState(() {
          enfantsDetails = [];
          isLoading = false;
        });
        return;
      }

      List<EleveModele> eleves = [];
      for (int i = 0; i < eleveIdsLies.length; i += 10) {
        final batchIds = eleveIdsLies.sublist(i, i + 10 > eleveIdsLies.length ? eleveIdsLies.length : i + 10);
        final eleveSnap = await FirebaseFirestore.instance
            .collection('eleves')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        eleves.addAll(eleveSnap.docs.map((d) => EleveModele.fromMap(d.data(), d.id)));
      }

      final utilisateurIds = eleves.map((e) => e.utilisateurId).toList();
      List<UtilisateurModele> utilisateurs = [];
      for (int i = 0; i < utilisateurIds.length; i += 10) {
        final batchIds = utilisateurIds.sublist(i, i + 10 > utilisateurIds.length ? utilisateurIds.length : i + 10);
        final userSnap = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        utilisateurs.addAll(userSnap.docs.map((d) => UtilisateurModele.fromMap(d.data(), d.id)));
      }

      enfantsDetails = eleves.map((eleve) {
        final utilisateur = utilisateurs.firstWhere(
          (u) => u.id == eleve.utilisateurId,
          orElse: () => UtilisateurRoleEmpty(),
        );
        final classe = classes.firstWhere(
          (c) => c.id == eleve.classeId,
          orElse: () => ClasseModele(
            id: '',
            nom: 'Inconnue',
            niveau: '',
            matieresIds: [],
            elevesIds: [],
          ),
        );
        return _EnfantDetail(eleve: eleve, utilisateur: utilisateur, classe: classe);
      }).toList();

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement enfants liés : $e")),
      );
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : enfantsDetails.isEmpty
              ? const Center(
                  child: Text(
                    "Aucun enfant lié trouvé.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: enfantsDetails.length,
                  itemBuilder: (context, index) {
                    final enfant = enfantsDetails[index];
                    final photoUrl = _getAppwriteImageUrl(enfant.utilisateur.photo);

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.teal.shade100,
                          backgroundImage:
                              photoUrl != null ? NetworkImage(photoUrl) : null,
                          child: photoUrl == null
                              ? const Icon(Icons.child_care, color: Colors.white, size: 28)
                              : null,
                        ),
                        title: Text(
                          "${enfant.utilisateur.prenom} ${enfant.utilisateur.nom}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Classe : ${enfant.classe.nom}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.teal, size: 24),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotesEnfantPage(
                                enfantId: enfant.eleve.id,
                                nomComplet:
                                    "${enfant.utilisateur.prenom} ${enfant.utilisateur.nom}",
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class _EnfantDetail {
  final EleveModele eleve;
  final UtilisateurModele utilisateur;
  final ClasseModele classe;

  _EnfantDetail({
    required this.eleve,
    required this.utilisateur,
    required this.classe,
  });
}

class UtilisateurRoleEmpty extends UtilisateurModele {
  UtilisateurRoleEmpty()
      : super(
          id: '',
          nom: '',
          prenom: '',
          email: '',
          numeroTelephone: '',
          adresse: '',
          motDePasse: '',
          statut: false,
          roleId: '',
          etablissementId: '',
          photo: null,
        );
}