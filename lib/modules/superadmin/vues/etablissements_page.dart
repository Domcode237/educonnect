import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/routes/noms_routes.dart';
import 'package:educonnect/modules/superadmin/vues/ModifierEtablissement.dart';
import 'package:educonnect/donnees/modeles/EtablissementModele.dart';

class EtablissementsPage extends StatefulWidget {
  const EtablissementsPage({super.key});

  @override
  State<EtablissementsPage> createState() => _EtablissementsPageState();
}

class _EtablissementsPageState extends State<EtablissementsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  void _supprimerEtablissement(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet établissement ?"),
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
      await FirebaseFirestore.instance.collection('etablissements').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Établissement supprimé avec succès")),
      );
    }
  }

  static Color _getPrimaryColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.blue : const Color(0xFF193152);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = _getPrimaryColor(context);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12,right: 12,top: 30, bottom: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher Établissement par nom...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('etablissements').snapshots(),
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
                  final nom = (data['nom'] ?? '').toString().toLowerCase();
                  return nom.contains(_searchText);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text("Aucun établissement trouvé."));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isLargeScreen = constraints.maxWidth > 600;
                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final String id = doc.id;

                        final etab = EtablissementModele(
                          id: id,
                          nom: data['nom'] ?? 'Nom inconnu',
                          type: data['type'] ?? 'Type inconnu',
                          adresse: data['adresse'] ?? '',
                          description: data['description'] ?? '',
                          ville: data['ville'] ?? '',
                          region: data['region'] ?? '',
                          pays: data['pays'] ?? '',
                          codePostal: data['codePostal'] ?? '',
                          email: data['email'] ?? '',
                          telephone: data['telephone'] ?? '',
                        );

                        return isLargeScreen
                            ? _buildLargeCard(context, theme, primaryColor, etab)
                            : _buildSmallCard(context, theme, primaryColor, etab);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, NomsRoutes.ajoutetablissement),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un établissement',
      ),
    );
  }

  Widget _buildLargeCard(BuildContext context, ThemeData theme, Color primaryColor, EtablissementModele etab) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.grey.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.school, size: 48, color: primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etab.nom, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Type : ${etab.type}", style: theme.textTheme.bodyMedium),
                  Text("Adresse : ${etab.adresse}, ${etab.ville}, ${etab.pays}", style: theme.textTheme.bodyMedium),
                  Text("Email : ${etab.email}", style: theme.textTheme.bodyMedium),
                  Text("Téléphone : ${etab.telephone}", style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: "Modifier",
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ModifierEtablissement(etab: etab)));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: "Supprimer",
                  onPressed: () => _supprimerEtablissement(context, etab.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard(BuildContext context, ThemeData theme, Color primaryColor, EtablissementModele etab) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.5),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.school, color: primaryColor),
        ),
        title: Text(etab.nom, style: theme.textTheme.titleMedium),
        subtitle: Text("${etab.type} - ${etab.ville}, ${etab.pays}\n${etab.email}", style: theme.textTheme.bodySmall),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: "Modifier",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ModifierEtablissement(etab: etab)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Supprimer",
              onPressed: () => _supprimerEtablissement(context, etab.id),
            ),
          ],
        ),
      ),
    );
  }
}
