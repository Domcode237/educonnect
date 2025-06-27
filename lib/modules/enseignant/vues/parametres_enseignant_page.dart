import 'package:flutter/material.dart';

class ParametresEnseignantPage extends StatelessWidget {
  const ParametresEnseignantPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
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
          onChanged: (value) {
            // Gérer la modification
          },
          title: const Text('Activer notifications'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.lock),
          title: const Text('Changer le mot de passe'),
          onTap: () {
            // Naviguer vers changement mot de passe
          },
        ),
      ],
    );
  }
}
