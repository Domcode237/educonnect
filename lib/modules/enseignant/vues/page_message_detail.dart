import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/message_model.dart';
import 'package:intl/intl.dart';
import 'package:educonnect/main.dart';

class PageMessageDetail extends StatefulWidget {
  final String enseignantId;
  final String parentId;
  final String parentNom;
  final String? parentPhotoFileId;

  const PageMessageDetail({
    super.key,
    required this.enseignantId,
    required this.parentId,
    required this.parentNom,
    this.parentPhotoFileId,
  });

  @override
  State<PageMessageDetail> createState() => _PageMessageDetailState();
}

class _PageMessageDetailState extends State<PageMessageDetail> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Stream<List<MessageModele>> getMessagesStream() {
    return _firestore
        .collection('messages')
        .where('participants', arrayContainsAny: [widget.enseignantId, widget.parentId])
        .orderBy('dateEnvoi')
        .snapshots()
        .map((snapshot) {
      final allMessages = snapshot.docs
          .map((doc) => MessageModele.fromMap(doc.id, doc.data()))
          .where((msg) =>
              (msg.emetteurId == widget.enseignantId && msg.recepteurId == widget.parentId) ||
              (msg.emetteurId == widget.parentId && msg.recepteurId == widget.enseignantId))
          .toList();

      // Debug print à la réception des messages
      for (var msg in allMessages) {
        print("[Stream] Message id=${msg.id}, emetteur=${msg.emetteurId}, recepteur=${msg.recepteurId}");
      }

      return allMessages;
    });
  }

  Future<void> _envoyerMessage() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;

    final docRef = _firestore.collection('messages').doc();
    final message = MessageModele(
        id: docRef.id,
        contenu: texte,
        emetteurId: widget.enseignantId,
        recepteurId: widget.parentId,
        dateEnvoi: DateTime.now(),
        lu: false,
        participants: [widget.enseignantId, widget.parentId],  // <-- ajouté
      );


    print("[Envoi] Envoi message id=${message.id} de ${message.emetteurId} à ${message.recepteurId}: '${message.contenu}'");

    await docRef.set({
      ...message.toMap(),
      'participants': [widget.enseignantId, widget.parentId],
    });

    _controller.clear();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _marquerMessagesCommeLus(List<MessageModele> messages) async {
    final batch = _firestore.batch();
    int updatedCount = 0;
    for (var msg in messages) {
      if (msg.recepteurId == widget.enseignantId && !msg.lu) {
        final docRef = _firestore.collection('messages').doc(msg.id);
        batch.update(docRef, {'lu': true});
        updatedCount++;
      }
    }
    if (updatedCount > 0) {
      await batch.commit();
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return "Hier";
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);

  @override
  Widget build(BuildContext context) {
    final photoUrl = _getAppwriteImageUrl(widget.parentPhotoFileId);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: Colors.grey.shade200,
              child: photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.parentNom,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModele>>(
              stream: getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de chargement des messages'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _marquerMessagesCommeLus(messages);
                });

                if (messages.isEmpty) {
                  return const Center(child: Text("Aucun message"));
                }

                final grouped = <String, List<MessageModele>>{};
                for (var msg in messages) {
                  final dayKey = DateFormat('yyyy-MM-dd').format(msg.dateEnvoi);
                  grouped.putIfAbsent(dayKey, () => []).add(msg);
                }

                final sortedDays = grouped.keys.toList()..sort();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  itemCount: sortedDays.length,
                  itemBuilder: (context, index) {
                    final day = sortedDays[index];
                    final dayMessages = grouped[day]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatDayLabel(dayMessages.first.dateEnvoi),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        ...dayMessages.map((msg) {
                          final isSender = msg.emetteurId == widget.enseignantId;
                          return Align(
                            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: isSender ? Colors.blueAccent : Colors.grey.shade300,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isSender ? 12 : 0),
                                  bottomRight: Radius.circular(isSender ? 0 : 12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg.contenu,
                                    style: TextStyle(
                                      color: isSender ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(msg.dateEnvoi),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSender ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Écrire un message...',
                    ),
                    onSubmitted: (_) => _envoyerMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: _envoyerMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
