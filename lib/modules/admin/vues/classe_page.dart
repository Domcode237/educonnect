import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/routes/noms_routes.dart';
import 'package:educonnect/modules/admin/vues/modifier_classe.dart';

class ClassesPage extends StatefulWidget {
  final String monIdEtablissement;

  const ClassesPage({Key? key, required this.monIdEtablissement}) : super(key: key);

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  String searchQuery = '';

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  void _supprimerClasse(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette classe ?"),
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
      try {
        await FirebaseFirestore.instance.collection('classes').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Classe supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression : $e')),
          );
        }
      }
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
            padding: const EdgeInsets.fromLTRB(12, 30, 12, 10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Rechercher une classe',
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
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .where('etablissementId', isEqualTo: widget.monIdEtablissement)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Erreur de chargement"));
                }

                final docs = snapshot.data?.docs ?? [];

                // Filtrage local sur la recherche
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
                          'Nombre de classes : ${filteredDocs.length}',
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
                          ? const Center(child: Text("Aucune classe trouvée."))
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final id = doc.id;
                                final nom = data['nom'] ?? 'Nom inconnu';
                                final niveau = data['niveau'] ?? 'Niveau inconnu';

                                final editButton = IconButton(
                                  icon: Icon(Icons.edit, color: primaryColor),
                                  tooltip: "Modifier",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ModifierClassePage(
                                          idClasse: doc.id,
                                        ),
                                      ),
                                    );
                                  },
                                );

                                final deleteButton = IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Supprimer",
                                  onPressed: () => _supprimerClasse(context, id),
                                );

                                return isLargeScreen
                                    ? Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: ListTile(
                                          leading: Icon(Icons.class_, size: 48, color: primaryColor),
                                          title: Text(nom, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                          subtitle: Text("Niveau : $niveau"),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [editButton, deleteButton],
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              NomsRoutes.classedetail,
                                              arguments: {'id': id},
                                            );
                                          },
                                        ),
                                      )
                                    : Card(
                                        margin: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        elevation: 3,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: primaryColor.withOpacity(0.1),
                                            child: Icon(Icons.class_, color: primaryColor),
                                          ),
                                          title: Text(nom),
                                          subtitle: Text("Niveau : $niveau"),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [editButton, deleteButton],
                                          ),
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              NomsRoutes.classedetail,
                                              arguments: {'id': id},
                                            );
                                          },
                                        ),
                                      );
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
          Navigator.pushNamed(
            context,
            NomsRoutes.ajoutclasse,
            arguments: widget.monIdEtablissement,
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter une classe',
      ),
    );
  }
}
