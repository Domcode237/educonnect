import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';

import 'liste_enfants_page.dart';
import 'NotificationsParentPage.dart';
import 'messagerie_parent_page.dart';
import 'devoir_page.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';
import 'annonce.dart';
import 'profil.dart';

class HomeParent extends StatefulWidget {
  final String etablissementId;
  final String utilisateurId;

  const HomeParent({
    Key? key,
    required this.etablissementId,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<HomeParent> createState() => _HomeParentState();
}

class _HomeParentState extends State<HomeParent> {
  int _selectedIndex = 0;
  String? _parentId;
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
    "Mes enfants",
    "Notifications",
    "Messagerie",
    "Devoirs",
    "Annonces",
  ];

  final List<IconData> pageIcons = [
    Icons.child_care,
    Icons.notifications,
    Icons.message_rounded,
    Icons.assignment,
    Icons.campaign,
  ];

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      ListeEnfantsPage(etablissementId: widget.etablissementId,parentId: widget.utilisateurId),
      const SizedBox(),
      const SizedBox(),
      ListeDevoirsParentPage(utilisateurId: widget.utilisateurId),
      const SizedBox(),
    ];
    _loadParentData();
  }

  Future<void> _loadParentData() async {
    try {
      final parentSnap = await FirebaseFirestore.instance
          .collection('parents')
          .where('utilisateurId', isEqualTo: widget.utilisateurId)
          .limit(1)
          .get();

      if (parentSnap.docs.isNotEmpty) {
        _parentId = parentSnap.docs.first.id;
      }

      final userSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (userSnap.exists) {
        final data = userSnap.data();
        if (data != null && data.containsKey('photo')) {
          final fileId = data['photoFileId'] as String?;
          if (fileId != null && fileId.isNotEmpty) {
            _photoUrl = _getAppwriteImageUrl(fileId);
          }
        }
      }

      pages[1] = NotificationsParentPage(parentId: _parentId ?? '');
      pages[2] = MessagerieParentPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
        parentId: _parentId ?? '',
      );
      pages[4] = ListeAnnoncesParentPage(
        utilisateurId: _parentId ?? '',
        etablissementId: widget.etablissementId,
      );

      setState(() {});
      _listenToRealtimeData();
    } catch (e) {
      debugPrint("Erreur chargement parent: $e");
    }
  }

  void _listenToRealtimeData() {
    if (_parentId == null) return;

    _messagesSub = FirebaseFirestore.instance
        .collection('messages')
        .where('recepteurId', isEqualTo: _parentId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        nbMessagesNonLus = snapshot.docs.length;
      });
    });

    _notificationsSub = FirebaseFirestore.instance
        .collection('notifications')
        .where('parentId', isEqualTo: _parentId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        nbNotifsNonLues = snapshot.docs.length;
      });
    });

    _devoirsSub = FirebaseFirestore.instance
        .collection('devoirs')
        .where('parentIds', arrayContains: _parentId)
        .snapshots()
        .listen((snapshot) {
      int nonLus = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lus = List<String>.from(data['lu'] ?? []);
        if (!lus.contains(_parentId)) nonLus++;
      }
      setState(() {
        nbDevoirsNonLus = nonLus;
      });
    });

    _annoncesSub = FirebaseFirestore.instance
        .collection('annonces')
        .where('utilisateursConcernees', arrayContains: widget.utilisateurId)
        .snapshots()
        .listen((snapshot) {
      int nonLues = 0;
      for (var doc in snapshot.docs) {
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: -9,
      top: -9,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
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
                    'Parent',
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
              title: const Text("Se déconnecter"),
              onTap: () => logoutUser(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
                icon: _photoUrl != null
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(_photoUrl!),
                      )
                    : const Icon(Icons.account_circle),
                tooltip: 'Profil',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfilUtilisateurPage(utilisateurId: widget.utilisateurId),
                    ),
                  );

                  // ✅ Recharger les données utilisateur (ex: photoFileId mise à jour)
                  await _loadParentData();
                },
              ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logoutUser(context),
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
                    leading: const SizedBox(height: 25), // ✅ Espace en haut
                    trailing: const SizedBox(height: 250), // ✅ Espace en bas
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
