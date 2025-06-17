import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/admin/vues/modifer_eleve.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

class ListeEleves extends StatefulWidget {
  const ListeEleves({Key? key}) : super(key: key);

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String searchQuery = '';

  static Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  Future<void> _supprimerUtilisateur(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet utilisateur ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text("Annuler", style: TextStyle(color: _getPrimaryColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await FirebaseFirestore.instance.collection('utilisateurs').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    final isLargeScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher un utilisateur',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('utilisateurs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];

                final utilisateurs = docs
                    .map((doc) => UtilisateurModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
                    .where((utilisateur) =>
                        utilisateur.nom.toLowerCase().contains(searchQuery) ||
                        utilisateur.prenom.toLowerCase().contains(searchQuery) ||
                        utilisateur.email.toLowerCase().contains(searchQuery))
                    .toList();

                if (utilisateurs.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur trouvé."));
                }

                return ListView.builder(
                  itemCount: utilisateurs.length,
                  itemBuilder: (context, index) {
                    final utilisateur = utilisateurs[index];

                    return isLargeScreen
                        ? _buildUtilisateurCardLarge(context, utilisateur, primaryColor)
                        : _buildUtilisateurCardSmall(context, utilisateur, primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/ajouteleve'); // adapte selon ta route
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un utilisateur',
      ),
    );
  }

  Widget _buildUtilisateurCardLarge(BuildContext context, UtilisateurModele utilisateur, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person, size: 48, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${utilisateur.nom} ${utilisateur.prenom}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Email : ${utilisateur.email}"),
                  Text("Téléphone : ${utilisateur.numeroTelephone}"),
                  Text("Adresse : ${utilisateur.adresse}"),
                  Text("Role ID : ${utilisateur.roleId}"),
                  Text("Établissement ID : ${utilisateur.etablissementId}"),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: "Modifier",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModificationEleveVue(eleveId: utilisateur.id),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Supprimer",
                  onPressed: () => _supprimerUtilisateur(context, utilisateur.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilisateurCardSmall(BuildContext context, UtilisateurModele utilisateur, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: primaryColor),
        ),
        title: Text("${utilisateur.nom} ${utilisateur.prenom}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email : ${utilisateur.email}"),
            Text("Tél : ${utilisateur.numeroTelephone}"),
            Text("Role ID : ${utilisateur.roleId}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: "Modifier",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModificationEleveVue(eleveId: utilisateur.id),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Supprimer",
              onPressed: () => _supprimerUtilisateur(context, utilisateur.id),
            ),
          ],
        ),
      ),
    );
  }
}
