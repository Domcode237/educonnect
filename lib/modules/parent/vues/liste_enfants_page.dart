import 'package:flutter/material.dart';

class ListeEnfantsPage extends StatelessWidget {
  final String etablissementId;
  const ListeEnfantsPage({Key? key, required this.etablissementId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Liste des enfants\nÉtablissement: $etablissementId",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
