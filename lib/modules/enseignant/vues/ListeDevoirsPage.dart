import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ListeDevoirsPage extends StatelessWidget {
  final String enseignantId;

  const ListeDevoirsPage({super.key, required this.enseignantId});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> devoirsStream = FirebaseFirestore.instance
        .collection('devoirs')
        .where('enseignantId', isEqualTo: enseignantId)
        .orderBy('dateCreation', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devoirs soumis'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: devoirsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            String? message;
            if (error is FirebaseException) {
              message = error.message;
            } else if (error is Exception) {
              message = error.toString();
            } else {
              message = 'Erreur inconnue';
            }

            // Extraction lien index Firestore si erreur index manquant
            final regex = RegExp(r'https://console\.firebase\.google\.com/[^ ]+');
            final match = regex.firstMatch(message ?? '');
            if (match != null) {
              final indexUrl = match.group(0);
              print('Lien création index Firestore: $indexUrl');
            } else {
              print('Erreur Firestore sans lien index : $message');
            }

            return Center(child: Text('Erreur: $message'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun devoir soumis pour le moment'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String titre = data['titre'] ?? 'Sans titre';
              final String description = data['description'] ?? '';
              final Timestamp? dateRemiseTs = data['dateRemise'] as Timestamp?;
              final DateTime? dateRemise = dateRemiseTs?.toDate();
              final dateRemiseStr = dateRemise != null
                  ? DateFormat('dd/MM/yyyy').format(dateRemise)
                  : 'Date non précisée';

              return ListTile(
                title: Text(titre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description.isNotEmpty)
                      Text(
                        description.length > 80
                            ? '${description.substring(0, 80)}...'
                            : description,
                      ),
                    const SizedBox(height: 4),
                    Text('Date de remise : $dateRemiseStr',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DetailDevoirPage(devoirDoc: doc, devoirData: data),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class DetailDevoirPage extends StatelessWidget {
  final QueryDocumentSnapshot devoirDoc;
  final Map<String, dynamic> devoirData;

  const DetailDevoirPage({
    super.key,
    required this.devoirDoc,
    required this.devoirData,
  });

  // Exemple basique d'URL de fichier Appwrite (adapter selon ta config)
  String? getFichierUrl() {
    final fichierId = devoirData['fichierUrl'] as String?;
    if (fichierId == null || fichierId.isEmpty) return null;

    // Exemple : URL publique ou route d'accès Appwrite
    // Remplacer par ta vraie URL ou méthode d'accès
    return 'https://cloud.appwrite.io/v1/storage/buckets/6854df330032c7be516c/files/$fichierId/view?project=6853190c0001df11877c';
  }

  Future<void> _ouvrirFichier(BuildContext context) async {
    final url = getFichierUrl();
    if (url == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Aucun fichier lié')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('URL fichier invalide')));
      return;
    }

    if (!await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir le fichier')));
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final String titre = devoirData['titre'] ?? 'Sans titre';
    final String description = devoirData['description'] ?? '';
    final Timestamp? dateRemiseTs = devoirData['dateRemise'] as Timestamp?;
    final DateTime? dateRemise = dateRemiseTs?.toDate();
    final dateRemiseStr = dateRemise != null
        ? DateFormat('dd/MM/yyyy').format(dateRemise)
        : 'Date non précisée';

    final Timestamp? dateCreationTs = devoirData['dateCreation'] as Timestamp?;
    final DateTime? dateCreation = dateCreationTs?.toDate();
    final dateCreationStr = dateCreation != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateCreation)
        : 'Date non précisée';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du devoir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(titre,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (description.isNotEmpty)
              Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            Text('Date de remise : $dateRemiseStr',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Date de création : $dateCreationStr',
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),
            if (getFichierUrl() != null)
              ElevatedButton.icon(
                onPressed: () => _ouvrirFichier(context),
                icon: const Icon(Icons.attach_file),
                label: const Text('Ouvrir le fichier lié'),
              ),
            if (getFichierUrl() == null)
              const Text(
                'Aucun fichier joint à ce devoir.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
}
