import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DevoirElevePage extends StatefulWidget {
  final String eleveId;
  const DevoirElevePage({super.key, required this.eleveId});

  @override
  State<DevoirElevePage> createState() => _DevoirElevePageState();
}

class _DevoirElevePageState extends State<DevoirElevePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot> _devoirsStream;

  @override
  void initState() {
    super.initState();
    _devoirsStream = _firestore
        .collection('devoirs')
        .where('eleveIds', arrayContains: widget.eleveId)
        .orderBy('dateCreation', descending: true)
        .snapshots();

    _testerIndexFirestore(); // 👈 Ajoute ceci
  }


  Future<String?> _chargerNomClasse(String classeId) async {
    final doc = await _firestore.collection('classes').doc(classeId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    final nom = data['nom'] ?? '';
    final niveau = data['niveau'] ?? '';
    return '$nom ($niveau)';
  }

  Future<void> _testerIndexFirestore() async {
  try {
    await _firestore
        .collection('devoirs')
        .where('eleveIds', arrayContains: widget.eleveId)
        .orderBy('dateCreation', descending: true)
        .limit(1) // 👈 important pour que Firestore exécute rapidement
        .get();
  } on FirebaseException catch (e) {
    if (e.message != null && e.message!.contains('https://')) {
      final regex = RegExp(r'https:\/\/console\.firebase\.google\.com\/[^ ]+');
      final match = regex.firstMatch(e.message!);
      if (match != null) {
      } else {
      }
    }
  }
}


  Future<String?> _chargerNomMatiere(String matiereId) async {
    final doc = await _firestore.collection('matieres').doc(matiereId).get();
    if (!doc.exists) return null;
    final data = doc.data();
    return data?['nom'] ?? '';
  }

  Future<void> _marquerCommeLu(String devoirDocId, List<dynamic>? lus) async {
    if (lus != null && lus.contains(widget.eleveId)) return;
    final updatedLus = [...?lus, widget.eleveId];
    await _firestore.collection('devoirs').doc(devoirDocId).update({'lu': updatedLus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _devoirsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Erreur lors du chargement des devoirs.'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun devoir trouvé'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final titre = data['titre'] ?? 'Sans titre';
              final description = data['description'] ?? '';
              final classeId = data['classeId'] ?? '';
              final matiereId = data['matiereId'] ?? '';
              final lus = List<String>.from(data['lu'] ?? []);
              final dateRemiseTs = data['dateRemise'] as Timestamp?;
              final dateRemise = dateRemiseTs?.toDate();
              final dateRemiseStr = dateRemise != null
                  ? DateFormat('dd/MM/yyyy').format(dateRemise)
                  : 'Date non précisée';

              final estLu = lus.contains(widget.eleveId);

              return FutureBuilder<String?>(
                future: _chargerNomClasse(classeId),
                builder: (context, snapshotClasse) {
                  final classeStr = snapshotClasse.data ?? 'Classe inconnue';

                  return FutureBuilder<String?>(
                    future: _chargerNomMatiere(matiereId),
                    builder: (context, snapshotMatiere) {
                      final matiereStr = snapshotMatiere.data ?? 'Matière inconnue';

                      return ListTile(
                        tileColor: estLu ? null : Colors.pink.shade50,
                        title: Text(
                          titre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: estLu ? null : const Color.fromARGB(232, 194, 24, 92),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description.isNotEmpty)
                              Text(
                                description.length > 80
                                    ? '${description.substring(0, 80)}...'
                                    : description,
                              ),
                            Text('Date de remise : $dateRemiseStr'),
                            Text('Classe : $classeStr'),
                            Text('Matière : $matiereStr'),
                          ],
                        ),
                        trailing: estLu
                            ? const Icon(Icons.notifications_none_outlined, color: Colors.grey)
                            : const Icon(Icons.notifications_active, color: Colors.red),
                        onTap: () async {
                          await _marquerCommeLu(doc.id, lus);
                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailDevoirElevePage(
                                devoirData: data,
                                classeNom: classeStr,
                                matiereNom: matiereStr,
                              ),
                            ),
                          );
                        },
                      );
                    },
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

class DetailDevoirElevePage extends StatelessWidget {
  final Map<String, dynamic> devoirData;
  final String classeNom;
  final String matiereNom;

  const DetailDevoirElevePage({
    super.key,
    required this.devoirData,
    required this.classeNom,
    required this.matiereNom,
  });

  String? getFichierUrl() {
    final fichierId = devoirData['fichierUrl'] as String?;
    if (fichierId == null || fichierId.isEmpty) return null;
    return 'https://cloud.appwrite.io/v1/storage/buckets/6854df330032c7be516c/files/$fichierId/view?project=6853190c0001df11877c';
  }

  Future<void> _ouvrirFichier(BuildContext context) async {
    final url = getFichierUrl();
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun fichier lié')),
      );
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir le fichier')),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final titre = devoirData['titre'] ?? 'Sans titre';
    final description = devoirData['description'] ?? '';
    final dateRemiseTs = devoirData['dateRemise'] as Timestamp?;
    final dateCreationTs = devoirData['dateCreation'] as Timestamp?;
    final dateRemiseStr = dateRemiseTs != null
        ? DateFormat('dd/MM/yyyy').format(dateRemiseTs.toDate())
        : 'Non précisée';
    final dateCreationStr = dateCreationTs != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(dateCreationTs.toDate())
        : 'Non précisée';

    return Scaffold(
      appBar: AppBar(title: Text("Détail du devoir")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(titre, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (description.isNotEmpty)
              Text(description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Date de remise : $dateRemiseStr'),
            Text('Date de création : $dateCreationStr'),
            const SizedBox(height: 16),
            Text('Classe : $classeNom'),
            Text('Matière : $matiereNom'),
            const SizedBox(height: 16),
            if (getFichierUrl() != null)
              ElevatedButton.icon(
                onPressed: () => _ouvrirFichier(context),
                icon: const Icon(Icons.attach_file),
                label: const Text("Ouvrir le fichier joint"),
              ),
            if (getFichierUrl() == null)
              const Text('Aucun fichier joint.'),
          ],
        ),
      ),
    );
  }
}
