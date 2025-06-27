import 'package:flutter/material.dart';

class ParametresElevePage extends StatelessWidget {
  const ParametresElevePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Profil'),
            subtitle: Text('Modifier vos informations personnelles'),
          ),
          const Divider(),
          SwitchListTile(
            value: true,
            onChanged: (val) {
              // Ici tu peux gérer le changement
            },
            title: const Text('Notifications activées'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Changer le mot de passe'),
            onTap: () {
              // Naviguer vers la page de changement de mot de passe
            },
          ),
        ],
      ),
    );
  }
}
