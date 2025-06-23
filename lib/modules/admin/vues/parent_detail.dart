import 'package:flutter/material.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/main.dart';
import 'package:educonnect/modules/admin/vues/lier_parent_enfant.dart';
class DetailsParentVue extends StatelessWidget {
  final ParentModele parent;
  final UtilisateurModele utilisateur;

  const DetailsParentVue({
    Key? key,
    required this.parent,
    required this.utilisateur,
  }) : super(key: key);

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _getAppwriteImageUrl(utilisateur.photo);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du parent"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shadowColor: Colors.grey.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "${utilisateur.nom} ${utilisateur.prenom}",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(utilisateur.statut ? "En ligne" : "Hors ligne"),
                      backgroundColor: utilisateur.statut ? Colors.green[100] : Colors.red[100],
                      avatar: Icon(
                        utilisateur.statut ? Icons.check_circle : Icons.cancel,
                        color: utilisateur.statut ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shadowColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Informations du parent",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    _buildInfoTile(Icons.email, "Email", utilisateur.email),
                    _buildInfoTile(Icons.phone, "Téléphone", utilisateur.numeroTelephone),
                    if (utilisateur.adresse.isNotEmpty)
                      _buildInfoTile(Icons.location_on, "Adresse", utilisateur.adresse),
                    _buildInfoTile(Icons.badge, "ID du parent", parent.id),
                    _buildInfoTile(Icons.account_box, "ID utilisateur", utilisateur.id),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              elevation: 3,
              shadowColor: Colors.grey.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Enfant(s) lié(s)",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20, thickness: 1),
                    // if (parent.enfants.isEmpty)
                    //   const Text("Aucun enfant lié.",
                    //       style: TextStyle(fontSize: 16, color: Colors.grey)),
                    // ...parent.enfants.map((enfantId) => Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 4),
                    //       child: Row(
                    //         children: [
                    //           const Icon(Icons.child_care, color: Colors.blueAccent),
                    //           const SizedBox(width: 8),
                    //           Text("ID enfant : $enfantId",
                    //               style: const TextStyle(fontSize: 16)),
                    //         ],
                    //       ),
                    //     )),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                       Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LierParentEnfantVue(parentId: parent.id),
                              ),
                            );
                         },
                      icon: const Icon(Icons.link),
                      label: const Text("Lier à un enfant"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size.fromHeight(45),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
