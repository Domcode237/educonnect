import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';
import 'package:educonnect/modules/admin/vues/home_page.dart';
import 'parent_page.dart';
import 'classe_page.dart';
import 'page_eleve.dart';
import 'evernement_page.dart';
import 'matiere_page.dart';
import 'page_enseigant.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';
import 'creer_annonce_page.dart';
import 'profil.dart';

class HomeAdmin extends StatefulWidget {
  final String monIdEtablissement;
  final String utilisateurId;

  const HomeAdmin({
    Key? key,
    required this.monIdEtablissement,
    required this.utilisateurId,
  }) : super(key: key);

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;
  String? _photoFileId;

  late final List<String> pageTitles;
  late final List<IconData> pageIcons;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    _chargerPhotoProfil();

    pageTitles = const [
      "Accueil",
      "Enseignant",
      "Classes",
      "Élève",
      "Parent",
      "Matières",
      "Annonces",
    ];

    pageIcons = const [
      Icons.home,
      Icons.badge,
      Icons.class_,
      Icons.person,
      Icons.family_restroom,
      Icons.menu_book,
      Icons.campaign,
    ];

    pages = [
      HomePage(etablissementId: widget.monIdEtablissement, adminId: widget.utilisateurId),
      ListeEnseignants(etablissementId: widget.monIdEtablissement),
      ClassesPage(monIdEtablissement: widget.monIdEtablissement),
      ListeEleves(etablissementId: widget.monIdEtablissement),
      ListeParents(etablissementId: widget.monIdEtablissement),
      MatieresPage(monIdEtablissement: widget.monIdEtablissement),
      CreerAnnoncePage(etablissementId: widget.monIdEtablissement),
    ];
  }

  Future<void> _chargerPhotoProfil() async {
    try {
      final userSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (userSnap.exists) {
        final data = userSnap.data();
        if (data != null && data.containsKey('photoFileId')) {
          final fileId = data['photoFileId'] as String?;
          if (fileId != null && fileId.isNotEmpty) {
            setState(() {
              _photoFileId = fileId;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement photo profil: $e');
    }
  }

  String? _getPhotoUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    logoutUser(context);
  }

  Widget _buildDrawer() {
    final photoUrl = _getPhotoUrl(_photoFileId);

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue.shade700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  backgroundColor: Colors.white,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 32, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Administrateur',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          for (int i = 0; i < pageTitles.length; i++)
            ListTile(
              leading: Icon(pageIcons[i]),
              title: Text(pageTitles[i]),
              selected: _selectedIndex == i,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final photoUrl = _getPhotoUrl(_photoFileId);

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: photoUrl != null
                ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(photoUrl))
                : const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilUtilisateurPage(utilisateurId: widget.utilisateurId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
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
                        icon: Icon(pageIcons[i]),
                        label: Text(pageTitles[i]),
                      );
                    }),
                    leading: const SizedBox(height: 25),
                    trailing: const SizedBox(height: 200), // ✅ espace fixe de 200 pixels
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
                  icon: Icon(pageIcons[i]),
                  label: pageTitles[i],
                );
              }),
            ),
    );
  }
}
