import 'package:flutter/material.dart';

class DashboardParentPage extends StatelessWidget {
  final String etablissementId;
  const DashboardParentPage({Key? key, required this.etablissementId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Tableau de bord Parent\nÉtablissement: $etablissementId",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}
