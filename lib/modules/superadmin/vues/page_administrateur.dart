import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/superadmin/vues/modifier_administrateur.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';

/// Modèle représentant un administrateur.
class AdministrateurModele {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String numeroTelephone;
  final String adresse;
  final String roleId;
  final String etablissementId;
  final String etablissementNom;
  final bool statut;
  final String motDePasse;

  AdministrateurModele({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.numeroTelephone,
    required this.adresse,
    required this.roleId,
    required this.etablissementId,
    required this.etablissementNom,
    required this.statut,
    required this.motDePasse,
  });

  factory AdministrateurModele.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final etablissementData = data['etablissement'] ?? {};

    return AdministrateurModele(
      id: doc.id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      numeroTelephone: data['numeroTelephone'] ?? '',
      adresse: data['adresse'] ?? '',
      roleId: data['roleId'] ?? '',
      etablissementId: etablissementData['id'] ?? '',
      etablissementNom: etablissementData['nom'] ?? 'Non défini',
      statut: data['statut'] ?? true,
      motDePasse: data['motDePasse'] ?? '',
    );
  }
}


/// Widget affichant la liste des administrateurs.
class ListeAdministrateurs extends StatefulWidget {
  const ListeAdministrateurs({Key? key}) : super(key: key);

  @override
  State<ListeAdministrateurs> createState() => _ListeAdministrateursState();
}

class _ListeAdministrateursState extends State<ListeAdministrateurs> {
  String searchQuery = '';

  /// Retourne la couleur principale selon le thème (clair/sombre).
  static Color _getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.blue
        : const Color.fromARGB(255, 25, 49, 82);
  }

  /// Supprime un administrateur après confirmation.
  Future<void> _supprimerAdministrateur(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet administrateur ?"),
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
      await FirebaseFirestore.instance.collection('administrateurs').doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Administrateur supprimé avec succès')),
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
                labelText: 'Rechercher un administrateur',
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
              stream: FirebaseFirestore.instance.collection('administrateurs').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                final docs = snapshot.data?.docs ?? [];

                final admins = docs
                    .map((doc) => AdministrateurModele.fromFirestore(doc))
                    .where((admin) =>
                        admin.nom.toLowerCase().contains(searchQuery) ||
                        admin.prenom.toLowerCase().contains(searchQuery) ||
                        admin.email.toLowerCase().contains(searchQuery))
                    .toList();

                if (admins.isEmpty) {
                  return const Center(child: Text("Aucun administrateur trouvé."));
                }

                return ListView.builder(
                  itemCount: admins.length,
                  itemBuilder: (context, index) {
                    final admin = admins[index];

                    return isLargeScreen
                        ? _buildAdminCardLarge(context, admin, primaryColor)
                        : _buildAdminCardSmall(context, admin, primaryColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/ajoutadministrateur');
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un administrateur',
      ),
    );
  }

  Widget _buildAdminCardLarge(BuildContext context, AdministrateurModele admin, Color primaryColor) {
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
                  Text("${admin.nom} ${admin.prenom}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Email : ${admin.email}"),
                  Text("Téléphone : ${admin.numeroTelephone}"),
                  Text("Adresse : ${admin.adresse}"),
                  Text("Établissement : ${admin.etablissementNom}"),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: primaryColor),
                  tooltip: "Modifier",
                  onPressed: () {
                    final utilisateur = UtilisateurModele(
                      id: admin.id,
                      nom: admin.nom,
                      prenom: admin.prenom,
                      email: admin.email,
                      numeroTelephone: admin.numeroTelephone,
                      adresse: admin.adresse,
                      motDePasse: admin.motDePasse,
                      statut: admin.statut,
                      roleId: admin.roleId,
                      etablissementId: admin.etablissementId,
                    );


                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ModifierAdministrateur(administrateur: utilisateur),
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
          ],
        ),
      ),
    );
  }

  Widget _buildAdminCardSmall(BuildContext context, AdministrateurModele admin, Color primaryColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: primaryColor),
        ),
        title: Text("${admin.nom} ${admin.prenom}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Email : ${admin.email}"),
            Text("Tél : ${admin.numeroTelephone}"),
            Text("Étab. : ${admin.etablissementNom}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: "Modifier",
              onPressed: () {
              final utilisateur = UtilisateurModele(
                id: admin.id,
                nom: admin.nom,
                prenom: admin.prenom,
                email: admin.email,
                numeroTelephone: admin.numeroTelephone,
                adresse: admin.adresse,
                motDePasse: admin.motDePasse,
                statut: admin.statut,
                roleId: admin.roleId,
                etablissementId: admin.etablissementId,
              );


              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ModifierAdministrateur(administrateur: utilisateur),
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
      ),
    );
  }
}
