import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/modules/admin/vues/modifier_matire.dart';
import 'package:educonnect/routes/noms_routes.dart';

class MatieresPage extends StatefulWidget {
  final String monIdEtablissement;

  const MatieresPage({Key? key, required this.monIdEtablissement}) : super(key: key);

  @override
  State<MatieresPage> createState() => _MatieresPageState();
}

class _MatieresPageState extends State<MatieresPage> {
  String searchQuery = '';

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  void _supprimerMatiere(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cette matière ?"),
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
        await FirebaseFirestore.instance.collection('matieres').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Matière supprimée avec succès')),
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
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher une matière',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matieres')
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
                          'Nombre de matières : ${filteredDocs.length}',
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
                          ? const Center(child: Text("Aucune matière trouvée."))
                          : ListView.builder(
                              itemCount: filteredDocs.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final id = doc.id;
                                final nom = data['nom'] ?? 'Nom inconnu';
                                final description = data['description'] ?? 'description inconnue';
                                final coefficient = data['coefficient']?.toDouble() ?? 0.0;

                                final editButton = IconButton(
                                  icon: Icon(Icons.edit, color: primaryColor),
                                  tooltip: "Modifier",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ModifierMatiere(
                                          id: id,
                                          nom: nom,
                                          description: description,
                                          coefficient: coefficient,
                                          etablissementId: widget.monIdEtablissement,
                                        ),
                                      ),
                                    );
                                  },
                                );

                                final deleteButton = IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Supprimer",
                                  onPressed: () => _supprimerMatiere(context, id),
                                );

                                return isLargeScreen
                                    ? Card(
                                        elevation: 4,
                                        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.book, size: 48, color: primaryColor),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(nom, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 8),
                                                    Text("Coefficient : $coefficient", style: Theme.of(context).textTheme.bodyMedium),
                                                  ],
                                                ),
                                              ),
                                              Column(children: [editButton, deleteButton]),
                                            ],
                                          ),
                                        ),
                                      )
                                    : Card(
                                        margin: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        elevation: 3,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: primaryColor.withOpacity(0.1),
                                            child: Icon(Icons.book, color: primaryColor),
                                          ),
                                          title: Text(nom, style: Theme.of(context).textTheme.titleMedium),
                                          subtitle: Text("Coefficient : $coefficient", style: Theme.of(context).textTheme.bodySmall),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [editButton, deleteButton],
                                          ),
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
            NomsRoutes.ajoutmatiere,
            arguments: widget.monIdEtablissement,
          );
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter une matière',
      ),
    );
  }
}
