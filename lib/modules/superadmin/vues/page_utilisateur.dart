import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/depots/depot_role.dart';

class ListeUtilisateurs extends StatefulWidget {
  const ListeUtilisateurs({Key? key}) : super(key: key);

  @override
  State<ListeUtilisateurs> createState() => _ListeUtilisateursState();
}

class _ListeUtilisateursState extends State<ListeUtilisateurs> {
  String searchQuery = '';
  final _db = FirebaseFirestore.instance;

  // Cache pour les rôles
  final Map<String, String> _rolesCache = {};

  // 🔁 Récupérer le nom du rôle à partir de son ID
  Future<String> _getRoleName(String roleId) async {
    if (roleId.isEmpty) return 'Rôle inconnu';

    // Si le rôle est déjà en cache
    if (_rolesCache.containsKey(roleId)) {
      return _rolesCache[roleId]!;
    }

    try {
      final role = await DepotRole().getRoleParId(roleId);
      final roleNom = role?.nom ?? 'Rôle inconnu';
      _rolesCache[roleId] = roleNom; // Cacher le résultat
      return roleNom;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du rôle : $e');
      return 'Rôle inconnu';
    }
  }

  static Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  Future<void> _supprimerUtilisateur(BuildContext context, String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer cet utilisateur ?"),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('utilisateurs').doc(userId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor(context);
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

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
                setState(() => searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('utilisateurs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                final utilisateurs = snapshot.data?.docs.map((doc) {
                  return UtilisateurModele.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                }).where((user) {
                  return user.nom.toLowerCase().contains(searchQuery) ||
                      user.prenom.toLowerCase().contains(searchQuery) ||
                      user.email.toLowerCase().contains(searchQuery);
                }).toList() ?? [];

                if (utilisateurs.isEmpty) {
                  return const Center(child: Text("Aucun utilisateur trouvé."));
                }

                return ListView.builder(
                  itemCount: utilisateurs.length,
                  itemBuilder: (context, index) {
                    final utilisateur = utilisateurs[index];

                    return FutureBuilder<String>(
                      future: _getRoleName(utilisateur.roleId),
                      builder: (context, snapshotRole) {
                        final roleNom = snapshotRole.connectionState == ConnectionState.waiting
                            ? "Chargement..."
                            : (snapshotRole.data ?? "Rôle inconnu");

                        return isLargeScreen
                            ? _buildUtilisateurCardLarge(context, utilisateur, roleNom, primaryColor)
                            : _buildUtilisateurCardSmall(context, utilisateur, roleNom, primaryColor);
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
        backgroundColor: primaryColor,
        tooltip: "Ajouter un utilisateur",
        onPressed: () => Navigator.pushNamed(context, '/ajoututilisateur'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildUtilisateurCardLarge(BuildContext context, UtilisateurModele utilisateur, String roleNom, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Text("Rôle : $roleNom"),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/modifierutilisateur',
                      arguments: utilisateur,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _supprimerUtilisateur(context, utilisateur.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilisateurCardSmall(BuildContext context, UtilisateurModele utilisateur, String roleNom, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.person, color: primaryColor),
        title: Text("${utilisateur.nom} ${utilisateur.prenom}"),
        subtitle: Text("Rôle : $roleNom\nEmail : ${utilisateur.email}"),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'modifier') {
              Navigator.pushNamed(context, '/modifierutilisateur', arguments: utilisateur);
            } else if (value == 'supprimer') {
              _supprimerUtilisateur(context, utilisateur.id);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'modifier', child: Text('Modifier')),
            const PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }
}
