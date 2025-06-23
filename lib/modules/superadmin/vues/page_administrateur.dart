import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/superadmin/vues/modifier_administrateur.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/main.dart';

class ListeAdministrateurs extends StatefulWidget {
  const ListeAdministrateurs({Key? key}) : super(key: key);

  @override
  State<ListeAdministrateurs> createState() => _ListeAdministrateursState();
}

class _ListeAdministrateursState extends State<ListeAdministrateurs> {
  String searchQuery = '';
  String? roleAdministrateurId;

  @override
  void initState() {
    super.initState();
    _fetchRoleAdministrateurId();
  }

  Future<void> _fetchRoleAdministrateurId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('roles')
        .where('nom', isEqualTo: 'administrateur')
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        roleAdministrateurId = snapshot.docs.first.id;
      });
    }
  }

  Future<String> _fetchEtablissementNom(String etablissementId) async {
    final doc = await FirebaseFirestore.instance.collection('etablissements').doc(etablissementId).get();
    if (doc.exists) {
      return doc.data()?['nom'] ?? 'Non défini';
    } else {
      return 'Non défini';
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

  Future<void> _supprimerAdministrateur(BuildContext context, String utilisateurId) async {
  final confirmation = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirmer la suppression"),
      content: const Text(
          "Voulez-vous vraiment supprimer cet administrateur ainsi que le compte associé ?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text("Annuler", style: TextStyle(color: _getPrimaryColor(context))),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            "Supprimer",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmation == true) {
    try {
      // 1️⃣ Supprimer le document utilisateur
      await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).delete();

      // 2️⃣ Chercher le document administrateur lié à ce utilisateur
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('administrateurs')
          .where('utilisateurId', isEqualTo: utilisateurId)
          .limit(1)
          .get();

      if (adminSnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('administrateurs')
            .doc(adminSnapshot.docs.first.id)
            .delete();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrateur supprimé avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);

    if (roleAdministrateurId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un administrateur',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('utilisateurs')
                  .where('roleId', isEqualTo: roleAdministrateurId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }
                final docs = snapshot.data?.docs ?? [];
                final admins = docs
                    .map((doc) => UtilisateurModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((admin) =>
                        admin.nom.toLowerCase().contains(searchQuery) ||
                        admin.prenom.toLowerCase().contains(searchQuery) ||
                        admin.email.toLowerCase().contains(searchQuery))
                    .toList();

                if (admins.isEmpty) return const Center(child: Text("Aucun administrateur trouvé."));
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: admins.length,
                  itemBuilder: (context, index) => _buildAdminCard(context, admins[index], primaryColor),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ajoutadministrateur'),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un administrateur',
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, UtilisateurModele admin, Color primaryColor) {
    final photoUrl = _getAppwriteImageUrl(admin.photo);

    return FutureBuilder<String>(
      future: _fetchEtablissementNom(admin.etablissementId),
      builder: (context, snapshot) {
        final etablissementNom = snapshot.data ?? 'Chargement...';
        return Container(
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? Icon(Icons.person, color: primaryColor) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${admin.nom} ${admin.prenom}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 14, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                admin.email,
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
                          builder: (_) => ModifierAdministrateur(administrateur: admin),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Supprimer",
                    onPressed: () => _supprimerAdministrateur(context, admin.id),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _infoIconText(Icons.phone, admin.numeroTelephone, primaryColor),
                  _infoIconText(Icons.location_on, admin.adresse, primaryColor),
                  _infoIconText(Icons.school, etablissementNom, primaryColor),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: admin.statut ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
