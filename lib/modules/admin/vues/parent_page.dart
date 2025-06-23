import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/modules/admin/vues/ajouter_parent.dart';
import 'package:educonnect/modules/admin/vues/modifier_parent.dart';
import 'package:educonnect/modules/admin/vues/parent_detail.dart';
import 'package:educonnect/main.dart';

class ListeParents extends StatefulWidget {
  final String etablissementId;

  const ListeParents({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeParents> createState() => _ListeParentsState();
}

class _ListeParentsState extends State<ListeParents> {
  String searchQuery = '';

  bool isValidId(String? id) => id != null && id.isNotEmpty;

  Future<void> _supprimerParent(BuildContext context, String utilisateurId, String parentId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce parent ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance.collection('parents').doc(parentId).delete();
        await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).delete();
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent supprimé avec succès')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
      }
    }
  }

  Future<List<ParentModele>> _chargerParentsFiltres() async {
    final snapshot = await FirebaseFirestore.instance.collection('parents').get();

    List<ParentModele> filteredParents = [];

    for (var doc in snapshot.docs) {
      final parent = ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      final utilisateurDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(parent.utilisateurId)
          .get();

      if (utilisateurDoc.exists) {
        final utilisateurData = utilisateurDoc.data() as Map<String, dynamic>;
        final utilisateur = UtilisateurModele.fromMap(utilisateurData, utilisateurDoc.id);

        if (utilisateur.etablissementId == widget.etablissementId) {
          filteredParents.add(parent);
        }
      }
    }

    return filteredParents;
  }

  Future<bool> _filtrerParentParRecherche(ParentModele parent) async {
    if (searchQuery.isEmpty) return true;
    try {
      final utilisateurDoc = await FirebaseFirestore.instance.collection('utilisateurs').doc(parent.utilisateurId).get();
      if (!utilisateurDoc.exists) return false;
      final utilisateur = UtilisateurModele.fromMap(utilisateurDoc.data()! as Map<String, dynamic>, utilisateurDoc.id);
      final fullName = '${utilisateur.nom} ${utilisateur.prenom}'.toLowerCase();
      return fullName.contains(searchQuery);
    } catch (_) {
      return false;
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: 'Rechercher un parent...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildUtilisateurCard(BuildContext context, ParentModele parent, UtilisateurModele utilisateur) {
    final photoUrl = _getAppwriteImageUrl(utilisateur.photo);
    final statutColor = (utilisateur.statut == true) ? Colors.green : Colors.red;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailsParentVue(parent: parent, utilisateur: utilisateur),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? const Icon(Icons.person, color: Colors.blueAccent) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statutColor,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${utilisateur.nom} ${utilisateur.prenom}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            utilisateur.email,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ModifierParent(parentId: parent.id)),
                    ).then((_) => setState(() {})),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _supprimerParent(context, utilisateur.id, parent.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<ParentModele>>(
                  future: _chargerParentsFiltres(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Erreur : ${snapshot.error}"));
                    }
                    final parents = snapshot.data ?? [];
                    if (parents.isEmpty) {
                      return const Center(child: Text("Aucun parent trouvé."));
                    }
                    return FutureBuilder<List<ParentModele>>(
                      future: Future.wait(parents.map((parent) async {
                        if (await _filtrerParentParRecherche(parent)) return parent;
                        return null;
                      }).toList()).then((results) => results.whereType<ParentModele>().toList()),
                      builder: (context, filteredSnapshot) {
                        if (!filteredSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final filteredParents = filteredSnapshot.data!;
                        if (filteredParents.isEmpty) {
                          return const Center(child: Text("Aucun parent ne correspond à la recherche."));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredParents.length,
                          itemBuilder: (context, index) {
                            final parent = filteredParents[index];
                            if (!isValidId(parent.utilisateurId)) {
                              return const ListTile(title: Text('ID utilisateur invalide'));
                            }
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('utilisateurs').doc(parent.utilisateurId).get(),
                              builder: (context, utilisateurSnapshot) {
                                if (utilisateurSnapshot.connectionState == ConnectionState.waiting) {
                                  return const ListTile(title: Text('Chargement...'));
                                }
                                if (!utilisateurSnapshot.hasData || !utilisateurSnapshot.data!.exists) {
                                  return const ListTile(title: Text('Utilisateur non trouvé'));
                                }
                                final utilisateur = UtilisateurModele.fromMap(
                                  utilisateurSnapshot.data!.data()! as Map<String, dynamic>,
                                  utilisateurSnapshot.data!.id,
                                );
                                return _buildUtilisateurCard(context, parent, utilisateur);
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AjoutParentVue(etablissementId: widget.etablissementId),
          ),
        ).then((_) => setState(() {})),
        child: const Icon(Icons.add),
      ),
    );
  }
}
