import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/routes/noms_routes.dart';
import 'package:educonnect/modules/superadmin/vues/modifier_role.dart';

class RolesPage extends StatefulWidget {
  const RolesPage({Key? key}) : super(key: key);

  @override
  State<RolesPage> createState() => _RolesPageState();
}

class _RolesPageState extends State<RolesPage> {
  String searchQuery = '';

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  void _supprimerRole(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer ce rôle ?"),
        actions: [
          TextButton(
            child: Text("Annuler", style: TextStyle(color: _getPrimaryColor(context))),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      await FirebaseFirestore.instance.collection('roles').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rôle supprimé avec succès')),
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
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 30, bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher un rôle',
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
              ],
            ),
          ),

          // Affichage dynamique des rôles
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('roles').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement"));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final nom = data['nom']?.toString().toLowerCase() ?? '';
                  return nom.contains(searchQuery);
                }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nombre de rôles : ${filteredDocs.length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: filteredDocs.isEmpty
                          ? const Center(child: Text("Aucun rôle correspondant trouvé."))
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final String id = doc.id;
                                final String nom = data['nom'] ?? 'Nom inconnu';
                                final String description = data['description'] ?? 'Aucune description';

                                if (isLargeScreen) {
                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.person, size: 48, color: primaryColor),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(nom, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 8),
                                                Text("Description : $description", style: Theme.of(context).textTheme.bodyMedium),
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
                                                      builder: (context) => ModifierRole(
                                                        id: id,
                                                        nom: nom,
                                                        description: description,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                tooltip: "Supprimer",
                                                onPressed: () => _supprimerRole(context, id),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                    elevation: 3,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: primaryColor.withOpacity(0.1),
                                        child: Icon(Icons.person, color: primaryColor),
                                      ),
                                      title: Text(nom, style: Theme.of(context).textTheme.titleMedium),
                                      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
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
                                                  builder: (context) => ModifierRole(
                                                    id: id,
                                                    nom: nom,
                                                    description: description,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: "Supprimer",
                                            onPressed: () => _supprimerRole(context, id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, NomsRoutes.ajoutRole);
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un rôle',
      ),
    );
  }
}
