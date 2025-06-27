import 'package:flutter/material.dart';

class DashboardElevePage extends StatelessWidget {
  const DashboardElevePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bienvenue sur votre tableau de bord',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Vous pouvez voir ici un résumé de votre progression et vos dernières activités.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Action simple par exemple
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bouton du tableau de bord pressé')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }
}
