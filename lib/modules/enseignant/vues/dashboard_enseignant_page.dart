import 'package:flutter/material.dart';

class DashboardEnseignantPage extends StatelessWidget {
  const DashboardEnseignantPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenue dans votre tableau de bord enseignant',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text(
                'Consultez vos classes, vos notifications et gérez vos paramètres.'),
          ],
        ),
      ),
    );
  }
}
