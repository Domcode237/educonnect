import 'package:flutter/material.dart';

class NotesElevePage extends StatelessWidget {
  const NotesElevePage({Key? key}) : super(key: key);

  final List<Map<String, dynamic>> notes = const [
    {'matiere': 'Mathématiques', 'note': 15},
    {'matiere': 'Français', 'note': 13},
    {'matiere': 'Histoire', 'note': 16},
    {'matiere': 'Sciences', 'note': 14},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            leading: const Icon(Icons.book),
            title: Text(note['matiere']),
            trailing: Text(
              note['note'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
