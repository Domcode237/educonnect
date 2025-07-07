import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';

import 'notes_eleve_page.dart';
import 'notifications_page.dart';
import 'messagerie_eleve_page.dart';
import 'liste_devoir.dart';
import 'annonces.dart';  // <-- à créer / adapter

import 'package:educonnect/vues/commun/deconnexion.dart';
import 'profil.dart';

class HomeEleve extends StatefulWidget {
  final String etablissementId;
  final String utilisateurId;

  const HomeEleve({
    Key? key,
    required this.etablissementId,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<HomeEleve> createState() => _HomeEleveState();
}

class _HomeEleveState extends State<HomeEleve> {
  int _selectedIndex = 0;
  String? _eleveId;
  String? _photoUrl;

  int nbMessagesNonLus = 0;
  int nbNotifsNonLues = 0;
  int nbDevoirsNonLus = 0;
  int nbAnnoncesNonLues = 0;

  StreamSubscription? _messagesSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _devoirsSub;
  StreamSubscription? _annoncesSub;

  final List<String> pageTitles = [
    "Mes notes",
    "Notifications",
    "Messagerie",
    "Devoirs",
    "Annonces",
  ];

  final List<IconData> pageIcons = [
    Icons.school,
    Icons.notifications,
    Icons.message_rounded,
    Icons.assignment_turned_in_outlined,
    Icons.campaign,
  ];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      NotesElevePage(utilisateurId: widget.utilisateurId),
      ListeNotificationsElevePage(utilisateurId: widget.utilisateurId),
      const SizedBox(),  // placeholder, sera remplacé dans _initEleveData
      const SizedBox(),
      const SizedBox(),
    ];

    _initEleveData();
  }

  Future<void> _initEleveData() async {
    try {
      final eleveSnap = await FirebaseFirestore.instance
          .collection('eleves')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (eleveSnap.docs.isNotEmpty) {
        _eleveId = eleveSnap.docs.first.id;

        pages[2] = MessagerieElevePage(
          etablissementId: widget.etablissementId,
          utilisateurId: widget.utilisateurId,
          eleveId: _eleveId!,
        );
        pages[3] = DevoirElevePage(eleveId: _eleveId!);
        pages[4] = ListeAnnoncesElevePage(
          utilisateurId: widget.utilisateurId,
          etablissementId: widget.etablissementId,
        );
      }

      final userSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (userSnap.exists) {
        final data = userSnap.data();
        final fileId = data?['photoFileId'] as String?;
        if (fileId != null && fileId.isNotEmpty) {
          _photoUrl = _getAppwriteImageUrl(fileId);
        } else {
          _photoUrl = null;
        }
      }

      setState(() {});

      _listenToRealtimeData();
    } catch (e) {
      debugPrint("Erreur chargement élève : $e");
    }
  }

  void _listenToRealtimeData() {
    if (_eleveId == null) return;

    _messagesSub?.cancel();
    _notificationsSub?.cancel();
    _devoirsSub?.cancel();
    _annoncesSub?.cancel();

    _messagesSub = FirebaseFirestore.instance
        .collection('messages')
        .where('recepteurId', isEqualTo: _eleveId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() {
        nbMessagesNonLus = snap.docs.length;
      });
    });

    _notificationsSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('eleveId', isEqualTo: _eleveId)
        .where('destinataireId', isEqualTo: _eleveId)
        .where('vu', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      setState(() {
        nbNotifsNonLues = snap.docs.length;
      });
    });

    _devoirsSub = FirebaseFirestore.instance
        .collection('devoirs')
        .where('eleveIds', arrayContains: _eleveId)
        .snapshots()
        .listen((snap) {
      int nonLus = 0;
      for (var doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lus = List<String>.from(data['lu'] ?? []);
        if (!lus.contains(_eleveId)) nonLus++;
      }
      setState(() {
        nbDevoirsNonLus = nonLus;
      });
    });

    _annoncesSub = FirebaseFirestore.instance
        .collection('annonces')
        .where('utilisateursConcernees', arrayContains: widget.utilisateurId)
        .snapshots()
        .listen((snap) {
      int nonLues = 0;
      for (var doc in snap.docs) {
        final data = doc.data();
        final luePar = List<String>.from(data['luePar'] ?? []);
        if (!luePar.contains(widget.utilisateurId)) nonLues++;
      }
      setState(() {
        nbAnnoncesNonLues = nonLues;
      });
    });
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _notificationsSub?.cancel();
    _devoirsSub?.cancel();
    _annoncesSub?.cancel();
    super.dispose();
  }

  String? _getAppwriteImageUrl(String fileId) {
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: -9,
      top: -9,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconWithBadge(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0) _buildBadge(count),
      ],
    );
  }

  void _logout() => logoutUser(context);

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                    backgroundColor: Colors.white,
                    child: _photoUrl == null
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Élève',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < pageTitles.length; i++)
              ListTile(
                leading: _iconWithBadge(
                  pageIcons[i],
                  i == 1
                      ? nbNotifsNonLues
                      : i == 2
                          ? nbMessagesNonLus
                          : i == 3
                              ? nbDevoirsNonLus
                              : i == 4
                                  ? nbAnnoncesNonLues
                                  : 0,
                ),
                title: Text(pageTitles[i]),
                onTap: () {
                  Navigator.pop(context);
                  _onItemTapped(i);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Déconnexion"),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: _photoUrl != null
                ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(_photoUrl!))
                : const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfilUtilisateurPage(utilisateurId: widget.utilisateurId),
                ),
              );

              await _initEleveData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                SizedBox(
                  height: double.infinity,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 300),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _onItemTapped,
                          labelType: NavigationRailLabelType.all,
                          destinations: List.generate(pageTitles.length, (i) {
                            return NavigationRailDestination(
                              icon: _iconWithBadge(
                                pageIcons[i],
                                i == 1
                                    ? nbNotifsNonLues
                                    : i == 2
                                        ? nbMessagesNonLus
                                        : i == 3
                                            ? nbDevoirsNonLus
                                            : i == 4
                                                ? nbAnnoncesNonLues
                                                : 0,
                              ),
                              label: Text(pageTitles[i]),
                            );
                          }),
                          leading: const SizedBox(height: 25),
                          trailing: const SizedBox(height: 250),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_selectedIndex]),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              items: List.generate(pageTitles.length, (i) {
                return BottomNavigationBarItem(
                  icon: _iconWithBadge(
                    pageIcons[i],
                    i == 1
                        ? nbNotifsNonLues
                        : i == 2
                            ? nbMessagesNonLus
                            : i == 3
                                ? nbDevoirsNonLus
                                : i == 4
                                    ? nbAnnoncesNonLues
                                    : 0,
                  ),
                  label: pageTitles[i],
                );
              }),
            ),
    );
  }
}
