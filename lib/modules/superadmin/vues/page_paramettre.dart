import 'package:flutter/material.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_super_admin.dart'; // 👉 à créer

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Paramètres généraux", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text("Activer les notifications"),
            value: true,
            onChanged: (val) {
              // logique à intégrer pour les paramètres globaux
            },
          ),
          const Divider(),

          const Text("Compte", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Changer le mot de passe"),
            onTap: () {
              // Navigation ou modal pour changer le mot de passe
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("Modifier l'adresse e-mail"),
            onTap: () {
              // Navigation ou modal pour modifier l'email
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add_alt_1),
            title: const Text("Ajouter un super administrateur"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AjoutSuperAdministrateurVue()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text("Supprimer le compte"),
            onTap: () {
              // Confirmation de suppression
            },
          ),

          const Divider(),

          const Text("Apparence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text("Changer le thème"),
            onTap: () {
              // logique pour changer de thème
            },
          ),
        ],
      ),
    );
  }
}
