import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';

import 'dashboard_enseignant_page.dart';
import 'appel.dart';
import 'notifications_page.dart';
import 'messagerie_enseignant_page.dart';
import 'parametres_enseignant_page.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';

class HomeEnseignant extends StatefulWidget {
  final String etablissementId;
  final String utilisateurId;

  const HomeEnseignant({
    Key? key,
    required this.etablissementId,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<HomeEnseignant> createState() => _HomeEnseignantState();
}

class _HomeEnseignantState extends State<HomeEnseignant> {
  int _selectedIndex = 0;

  String? utilisateurPhotoFileId;
  String? enseignantId;

  int nbMessagesNonLus = 0;
  int nbNotifsNonLues = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> pageTitles = [
    "Tableau de bord",
    "Liste des élèves",
    "Notifications",
    "Messagerie",
    "Paramètres",
  ];

  final List<IconData> pageIcons = [
    Icons.dashboard,
    Icons.group,
    Icons.notifications,
    Icons.message_rounded,
    Icons.settings,
  ];

  late List<Widget> pages;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    pages = List.filled(5, const SizedBox());
    _loadUserData();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final enseignantSnap = await _firestore
        .collection('enseignants')
        .where('utilisateurId', isEqualTo: widget.utilisateurId)
        .limit(1)
        .get();

    if (enseignantSnap.docs.isNotEmpty) {
      enseignantId = enseignantSnap.docs.first.id;
    }

    await _chargerPhotoUtilisateur();

    if (enseignantId != null) {
      _messagesSubscription = _firestore
          .collection('messages')
          .where('recepteurId', isEqualTo: enseignantId)
          .where('lu', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          nbMessagesNonLus = snapshot.docs.length;
        });
      });
    }

    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('recepteurId', isEqualTo: widget.utilisateurId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        nbNotifsNonLues = snapshot.docs.length;
      });
    });

    pages = [
      DashboardEnseignantPage(),
      AppelPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
      ),
      NotificationsPage(),
      MessagerieEnseignantPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
      ),
      const ParametresEnseignantPage(),
    ];

    setState(() {});
  }

  Future<void> _chargerPhotoUtilisateur() async {
    try {
      final doc = await _firestore
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('photo')) {
          utilisateurPhotoFileId = data['photo'] as String?;
        }
      }
    } catch (_) {}
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
    final photoUrl = _getAppwriteImageUrl(utilisateurPhotoFileId);

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
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: Colors.white,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 32, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Enseignant',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
            for (int i = 0; i < pageTitles.length; i++)
              ListTile(
                leading: _iconWithBadge(
                  pageIcons[i],
                  i == 2 ? nbNotifsNonLues : i == 3 ? nbMessagesNonLus : 0,
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
            icon: photoUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(photoUrl),
                  )
                : const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () => _onItemTapped(pageTitles.indexOf("Paramètres")),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => logoutUser(context),
          ),
        ],
      ),
      body: isWideScreen
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: List.generate(pageTitles.length, (i) {
                    return NavigationRailDestination(
                      icon: _iconWithBadge(
                        pageIcons[i],
                        i == 2 ? nbNotifsNonLues : i == 3 ? nbMessagesNonLus : 0,
                      ),
                      label: Text(pageTitles[i]),
                    );
                  }),
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
                    i == 2 ? nbNotifsNonLues : i == 3 ? nbMessagesNonLus : 0,
                  ),
                  label: pageTitles[i],
                );
              }),
            ),
    );
  }
}
