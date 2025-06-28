import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:educonnect/main.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../enseignant/modeles/message_model.dart';

class PageMessageDetailEleve extends StatefulWidget {
  final String eleveId;
  final String enseignantId;
  final String enseignantNom;
  final String? enseignantPhotoFileId;

  const PageMessageDetailEleve({
    Key? key,
    required this.eleveId,
    required this.enseignantId,
    required this.enseignantNom,
    this.enseignantPhotoFileId,
  }) : super(key: key);

  @override
  State<PageMessageDetailEleve> createState() => _PageMessageDetailEleveState();
}

class _PageMessageDetailEleveState extends State<PageMessageDetailEleve> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _showScrollToBottom = false;
  bool _hasScrolled = false;
  bool _emojiVisible = false;

  MessageModele? _messageEnCoursEdition;
  MessageModele? _messageEnReponse;
  bool _isInterlocuteurEnLigne = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final isAtBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 100;
      if (_showScrollToBottom != !isAtBottom) {
        setState(() => _showScrollToBottom = !isAtBottom);
      }
    });
    _chargerStatutEnseignant(); // 👈 nouvelle méthode
  }

  Future<void> _chargerStatutEnseignant() async {
  try {

    // 1. Récupérer le document enseignant
    final enseignantSnap = await _firestore.collection('enseignants').doc(widget.enseignantId).get();

    if (!enseignantSnap.exists) {
      return;
    }

    final enseignantData = enseignantSnap.data();

    final utilisateurId = enseignantData?['utilisateurId'];
    if (utilisateurId == null) {
      return;
    }


    // 2. Récupérer le document utilisateur
    final utilisateurSnap = await _firestore.collection('utilisateurs').doc(utilisateurId).get();

    if (!utilisateurSnap.exists) {
      return;
    }

    final utilisateurData = utilisateurSnap.data();

    if (utilisateurData != null && utilisateurData.containsKey('statut')) {
      final statut = utilisateurData['statut'] == true;

      setState(() {
        _isInterlocuteurEnLigne = statut;
      });
    } else {
    }
  } catch (e) {
  }
}




  Stream<List<MessageModele>> getMessagesStream() {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: widget.eleveId)
        .orderBy('dateEnvoi')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModele.fromMap(doc.id, doc.data()))
            .where((msg) => msg.participants.contains(widget.enseignantId))
            .toList());
  }

  Future<void> _envoyerMessage() async {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;

    if (_messageEnCoursEdition != null) {
      await _firestore.collection('messages').doc(_messageEnCoursEdition!.id).update({'contenu': texte});
      _messageEnCoursEdition = null;
    } else {
      final docRef = _firestore.collection('messages').doc();
      final message = MessageModele(
        id: docRef.id,
        contenu: texte,
        emetteurId: widget.eleveId,
        recepteurId: widget.enseignantId,
        dateEnvoi: DateTime.now(),
        lu: false,
        participants: [widget.eleveId, widget.enseignantId],
      );
      await docRef.set(message.toMap());
    }

    _messageEnReponse = null;
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> _marquerMessagesCommeLus(List<MessageModele> messages) async {
    final batch = _firestore.batch();
    for (var msg in messages) {
      if (msg.recepteurId == widget.eleveId && !msg.lu) {
        batch.update(_firestore.collection('messages').doc(msg.id), {'lu': true});
      }
    }
    await batch.commit();
  }

  Future<void> _supprimerPourMoi(MessageModele msg) async {
    final newParticipants = List<String>.from(msg.participants)..remove(widget.eleveId);
    if (newParticipants.isEmpty) {
      await _firestore.collection('messages').doc(msg.id).delete();
    } else {
      await _firestore.collection('messages').doc(msg.id).update({'participants': newParticipants});
    }
  }

  Future<void> _supprimerPourTous(MessageModele msg) async {
    if (msg.emetteurId != widget.eleveId) return;
    await _firestore.collection('messages').doc(msg.id).delete();
  }

  void _showActions(BuildContext context, MessageModele msg) {
    final isMe = msg.emetteurId == widget.eleveId;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Répondre'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _messageEnReponse = msg);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _messageEnCoursEdition = msg;
                    _controller.text = msg.contenu;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Supprimer pour moi'),
              onTap: () {
                Navigator.pop(context);
                _supprimerPourMoi(msg);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Supprimer pour tous'),
                onTap: () {
                  Navigator.pop(context);
                  _supprimerPourTous(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) => DateFormat('HH:mm').format(date);
  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(DateTime(date.year, date.month, date.day)).inDays;
    if (diff == 0) return "Aujourd'hui";
    if (diff == 1) return "Hier";
    return DateFormat('dd MMM yyyy').format(date);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Widget _buildMessageBubble(MessageModele msg, bool isMe) {
    final bg = isMe ? Colors.blueAccent : Colors.grey.shade300;
    final tc = isMe ? Colors.white : Colors.black87;

    return GestureDetector(
      onLongPress: () => _showActions(context, msg),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg.contenu, style: TextStyle(color: tc, fontSize: 16)),
              const SizedBox(height: 6),
              Text(_formatTime(msg.dateEnvoi),
                  style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _getAppwriteImageUrl(widget.enseignantPhotoFileId);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              backgroundColor: Colors.grey.shade200,
              child: photoUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.enseignantNom,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    _isInterlocuteurEnLigne ? 'En ligne' : 'Hors ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isInterlocuteurEnLigne ? Colors.green : Colors.grey,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModele>>(
              stream: getMessagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _marquerMessagesCommeLus(messages);
                  if (!_hasScrolled && _scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    _hasScrolled = true;
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.emetteurId == widget.eleveId;
                    bool showDate = i == 0 ||
                        DateFormat('yyyyMMdd').format(msg.dateEnvoi) !=
                            DateFormat('yyyyMMdd').format(messages[i - 1].dateEnvoi);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDayLabel(msg.dateEnvoi),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        _buildMessageBubble(msg, isMe),
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
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  onPressed: () => setState(() => _emojiVisible = !_emojiVisible),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration.collapsed(hintText: "Écrire un message..."),
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
          if (_emojiVisible)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                textEditingController: _controller,
                onEmojiSelected: (category, emoji) {
                  _controller.text += emoji.emoji;
                },
                onBackspacePressed: () {
                  if (_controller.text.isNotEmpty) {
                    _controller.text = _controller.text.substring(0, _controller.text.length - 1);
                  }
                },
                config: const Config(
                  emojiViewConfig: EmojiViewConfig(emojiSizeMax: 28, columns: 7),
                  categoryViewConfig: CategoryViewConfig(),
                  bottomActionBarConfig: BottomActionBarConfig(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.keyboard_arrow_down),
              onPressed: _scrollToBottom,
            )
          : null,
    );
  }
}
