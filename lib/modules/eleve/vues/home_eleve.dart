import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';

import 'dashboard_eleve_page.dart';
import 'notes_eleve_page.dart';
import 'notifications_page.dart';
import 'parametres_eleve_page.dart';
import 'messagerie_eleve_page.dart'; // 🔸 à créer comme messagerie parent

import 'package:educonnect/vues/commun/deconnexion.dart';

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

  late List<String> pageTitles;
  late List<IconData> pageIcons;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _loadEleveData();

    pageTitles = const [
      "Tableau de bord",
      "Mes notes",
      "Notifications",
      "Messagerie",
      "Paramètres",
    ];

    pageIcons = const [
      Icons.dashboard,
      Icons.school,
      Icons.notifications,
      Icons.message_rounded,
      Icons.settings,
    ];

    pages = [
      DashboardElevePage(),
      NotesElevePage(),
      const SizedBox(),
      const SizedBox(),
      ParametresElevePage(),
    ];
  }

  Future<void> _loadEleveData() async {
  try {
    final eleveSnap = await FirebaseFirestore.instance
        .collection('eleves')
        .where('utilisateurId', isEqualTo: widget.utilisateurId)
        .limit(1)
        .get();

    if (eleveSnap.docs.isNotEmpty) {
      _eleveId = eleveSnap.docs.first.id;

      // 👇 On configure la page de messagerie SEULEMENT si _eleveId n’est pas null
      pages[3] = MessagerieElevePage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
        eleveId: _eleveId!, // ici on peut forcer car on est dans le if
      );
    }

    final userSnap = await FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(widget.utilisateurId)
        .get();

    if (userSnap.exists) {
      final data = userSnap.data();
      if (data != null && data.containsKey('photo')) {
        final fileId = data['photo'] as String?;
        if (fileId != null && fileId.isNotEmpty) {
          _photoUrl = _getAppwriteImageUrl(fileId);
        }
      }
    }

    await _chargerNombreMessagesNonLus();
    await _chargerNombreNotifsNonLues();

    pages[2] = NotificationsPage();

    setState(() {});
  } catch (e) {
    debugPrint("Erreur de chargement élève: $e");
  }
}


  Future<void> _chargerNombreMessagesNonLus() async {
    if (_eleveId == null) return;
    final query = await FirebaseFirestore.instance
        .collection('messages')
        .where('recepteurId', isEqualTo: _eleveId)
        .where('lu', isEqualTo: false)
        .get();
    nbMessagesNonLus = query.docs.length;
  }

  Future<void> _chargerNombreNotifsNonLues() async {
    if (_eleveId == null) return;
    final query = await FirebaseFirestore.instance
        .collection('notifications')
        .where('eleveId', isEqualTo: _eleveId)
        .where('lu', isEqualTo: false)
        .get();
    nbNotifsNonLues = query.docs.length;
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  void _onItemTapped(int index) async {
    setState(() => _selectedIndex = index);

    if (index == 2 || index == 3) {
      await _chargerNombreMessagesNonLus();
      await _chargerNombreNotifsNonLues();
      setState(() {});
    }
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
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _iconWithBadge(IconData icon, int count) {
    return Stack(
      clipBehavior: Clip.none,
      children: [Icon(icon), if (count > 0) _buildBadge(count)],
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
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
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
            onPressed: () => _onItemTapped(4),
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
