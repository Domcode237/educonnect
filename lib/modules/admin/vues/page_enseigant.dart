import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/main.dart';
import 'package:educonnect/modules/admin/vues/modifier_enseignant.dart';
import 'package:educonnect/modules/admin/vues/detail_enseignant.dart';
import 'package:educonnect/donnees/modeles/EnseignantModele.dart';

class ListeEnseignants extends StatefulWidget {
  final String etablissementId;

  const ListeEnseignants({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeEnseignants> createState() => _ListeEnseignantsState();
}

class _ListeEnseignantsState extends State<ListeEnseignants> {
  String searchQuery = '';
  String? roleEnseignantId;

  @override
  void initState() {
    super.initState();
    _fetchRoleEnseignantId();
  }

  Future<void> _fetchRoleEnseignantId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('nom', isEqualTo: 'enseignant')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        roleEnseignantId = snapshot.docs.first.id;
      });
    }
  }

  Future<void> _supprimerUtilisateur(BuildContext context, String utilisateurId) async {
    final enseignantSnap = await FirebaseFirestore.instance
        .collection('enseignants')
        .where('utilisateurId', isEqualTo: utilisateurId)
        .limit(1)
        .get();

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer cet enseignant ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Annuler")),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmation == true) {
      try {
        // Supprime depuis "utilisateurs"
        await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).delete();

        // Supprime aussi depuis "enseignants"
        if (enseignantSnap.docs.isNotEmpty) {
          await enseignantSnap.docs.first.reference.delete();
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant supprimé avec succès')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);

    if (roleEnseignantId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final enseignantsStream = FirebaseFirestore.instance
        .collection('utilisateurs')
        .where('roleId', isEqualTo: roleEnseignantId)
        .where('etablissementId', isEqualTo: widget.etablissementId)
        .snapshots();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un enseignant',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: enseignantsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                final enseignants = snapshot.data?.docs
                        .map((doc) => UtilisateurModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                        .where((ens) =>
                            ens.nom.toLowerCase().contains(searchQuery) ||
                            ens.prenom.toLowerCase().contains(searchQuery) ||
                            ens.email.toLowerCase().contains(searchQuery))
                        .toList() ??
                    [];

                if (enseignants.isEmpty) {
                  return const Center(child: Text("Aucun enseignant trouvé."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: enseignants.length,
                  itemBuilder: (context, index) =>
                      _buildEnseignantCard(context, enseignants[index], primaryColor),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/ajoutenseignant',
            arguments: {'etablissementId': widget.etablissementId},
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un enseignant',
      ),
    );
  }

  Widget _buildEnseignantCard(BuildContext context, UtilisateurModele enseignant, Color primaryColor) {
    final photoUrl = _getAppwriteImageUrl(enseignant.photo);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailsEnseignant(enseignant: enseignant),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black87),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? Icon(Icons.person, color: primaryColor, size: 32)
                          : null,
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: enseignant.statut ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${enseignant.nom} ${enseignant.prenom}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              enseignant.email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: "Modifier",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModifierEnseignant(enseignant: enseignant),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Supprimer",
                  onPressed: () {
                    _supprimerUtilisateur(context, enseignant.id);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoIconText(Icons.phone, enseignant.numeroTelephone, primaryColor),
                _infoIconText(Icons.location_on, enseignant.adresse, primaryColor),
                _infoIconText(Icons.school, "Établissement", primaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoIconText(IconData icon, String text, Color color) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

