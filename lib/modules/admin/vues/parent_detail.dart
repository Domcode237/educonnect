import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/modules/admin/vues/lier_parent_enfant.dart';
import 'package:educonnect/main.dart';

class DetailsParentVue extends StatefulWidget {
  final ParentModele parent;
  final UtilisateurModele utilisateur;

  const DetailsParentVue({
    Key? key,
    required this.parent,
    required this.utilisateur,
  }) : super(key: key);

  @override
  State<DetailsParentVue> createState() => _DetailsParentVueState();
}

class _DetailsParentVueState extends State<DetailsParentVue> {
  bool isLoading = true;

  // Liste des enfants liés avec données complètes (élève + utilisateur + classe)
  List<_EnfantDetail> enfantsDetails = [];

  // Toutes les classes chargées (pour retrouver les noms)
  List<ClasseModele> classes = [];

  @override
  void initState() {
    super.initState();
    _chargerEnfantsLies();
  }

  Future<void> _chargerEnfantsLies() async {
    try {
      setState(() {
        isLoading = true;
      });

      // 1. Charger toutes les classes pour le même établissement du parent
      final etabId = widget.utilisateur.etablissementId;
      if (etabId == null || etabId.isEmpty) {
        throw "Établissement introuvable pour ce parent";
      }
      final clsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: etabId)
          .get();
      classes = clsSnap.docs.map((d) => ClasseModele.fromMap(d.data(), d.id)).toList();

      // 2. Récupérer la liste des enfants liés à ce parent via la collection 'famille' (ou 'familles')
      final familleSnap = await FirebaseFirestore.instance
          .collection('famille') // nom exact à vérifier selon ta base
          .where('parentId', isEqualTo: widget.parent.id)
          .get();

      // Extraire les ids élèves liés
      final List<String> eleveIdsLies = familleSnap.docs.map((doc) => doc.data()['eleveId'] as String).toList();

      if (eleveIdsLies.isEmpty) {
        // Aucun enfant lié
        enfantsDetails = [];
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 3. Charger les données des élèves (EleveModele) par batch
      List<EleveModele> eleves = [];
      for (int i = 0; i < eleveIdsLies.length; i += 10) {
        final batchIds = eleveIdsLies.sublist(i, i + 10 > eleveIdsLies.length ? eleveIdsLies.length : i + 10);
        final eleveSnap = await FirebaseFirestore.instance
            .collection('eleves')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        eleves.addAll(eleveSnap.docs.map((d) => EleveModele.fromMap(d.data(), d.id)));
      }

      // 4. Extraire les utilisateurIds des élèves
      final List<String> utilisateurIds = eleves.map((e) => e.utilisateurId).toList();

      // 5. Charger les utilisateurs correspondants (propriétaires des élèves) par batch
      List<UtilisateurModele> utilisateurs = [];
      for (int i = 0; i < utilisateurIds.length; i += 10) {
        final batchIds = utilisateurIds.sublist(i, i + 10 > utilisateurIds.length ? utilisateurIds.length : i + 10);
        final userSnap = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
        utilisateurs.addAll(userSnap.docs.map((d) => UtilisateurModele.fromMap(d.data(), d.id)));
      }

      // 6. Construire la liste complète des enfants détaillés
      enfantsDetails = eleves.map((eleve) {
        final utilisateur = utilisateurs.firstWhere(
          (u) => u.id == eleve.utilisateurId,
          orElse: () => UtilisateurRoleEmpty(),
        );

        // Trouver la classe de l'élève
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

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur chargement enfants liés : $e")));
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _getAppwriteImageUrl(widget.utilisateur.photo);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du parent"),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shadowColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.blue.shade100,
                            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                            child: photoUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${widget.utilisateur.nom} ${widget.utilisateur.prenom}",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(widget.utilisateur.statut ? "En ligne" : "Hors ligne"),
                            backgroundColor: widget.utilisateur.statut ? Colors.green[100] : Colors.red[100],
                            avatar: Icon(
                              widget.utilisateur.statut ? Icons.check_circle : Icons.cancel,
                              color: widget.utilisateur.statut ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Informations du parent",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 20, thickness: 1),
                          _buildInfoTile(Icons.email, "Email", widget.utilisateur.email),
                          _buildInfoTile(Icons.phone, "Téléphone", widget.utilisateur.numeroTelephone),
                          if (widget.utilisateur.adresse.isNotEmpty)
                            _buildInfoTile(Icons.location_on, "Adresse", widget.utilisateur.adresse),
                          _buildInfoTile(Icons.badge, "ID du parent", widget.parent.id),
                          _buildInfoTile(Icons.account_box, "ID utilisateur", widget.utilisateur.id),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Enfant(s) lié(s)",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(height: 20, thickness: 1),

                          enfantsDetails.isEmpty
                              ? const Text("Aucun enfant lié.", style: TextStyle(fontSize: 16, color: Colors.grey))
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: enfantsDetails.length,
                                  itemBuilder: (context, index) {
                                    final enfant = enfantsDetails[index];
                                    final photoEnfantUrl = _getAppwriteImageUrl(enfant.utilisateur.photo);
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue.shade100,
                                        backgroundImage:
                                            photoEnfantUrl != null ? NetworkImage(photoEnfantUrl) : null,
                                        child: photoEnfantUrl == null
                                            ? const Icon(Icons.child_care, color: Colors.white)
                                            : null,
                                      ),
                                      title: Text("${enfant.utilisateur.nom} ${enfant.utilisateur.prenom}"),
                                      subtitle: Text("Classe : ${enfant.classe.nom}"),
                                    );
                                  },
                                ),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LierParentEnfantVue(parentId: widget.parent.id),
                                ),
                              ).then((_) {
                                // Recharger la liste après un éventuel lien ajouté
                                _chargerEnfantsLies();
                              });
                            },
                            icon: const Icon(Icons.link),
                            label: const Text("Lier à un enfant"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              minimumSize: const Size.fromHeight(45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Classe privée pour stocker enfant + utilisateur + classe
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

// Classe pour utilisateur vide (cas fallback)
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
