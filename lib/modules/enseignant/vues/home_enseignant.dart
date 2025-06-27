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
  const HomeEnseignant({Key? key}) : super(key: key);

  @override
  State<HomeEnseignant> createState() => _HomeEnseignantState();
}

class _HomeEnseignantState extends State<HomeEnseignant> {
  int _selectedIndex = 0;
  String? etablissementId;
  String? utilisateurId;
  String? utilisateurPhotoFileId;
  int nbMessagesNonLus = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Widget> pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      final newEtablissementId = args['etablissementId'] as String?;
      final newUtilisateurId = args['utilisateurId'] as String?;

      if (newEtablissementId != etablissementId || newUtilisateurId != utilisateurId) {
        etablissementId = newEtablissementId;
        utilisateurId = newUtilisateurId;

        _chargerPhotoUtilisateur();
        _chargerNombreMessagesNonLus();

        pages = [
          DashboardEnseignantPage(),
          AppelPage(
            etablissementId: etablissementId ?? '',
            utilisateurId: utilisateurId ?? '',
          ),
          NotificationsPage(),
          MessagerieEnseignantPage(
            etablissementId: etablissementId ?? '',
            utilisateurId: utilisateurId ?? '',
          ),
          ParametresEnseignantPage(),
        ];

        setState(() {});
      }
    }
  }

  Future<void> _chargerPhotoUtilisateur() async {
    if (utilisateurId == null || utilisateurId!.isEmpty) return;

    try {
      final doc = await _firestore.collection('utilisateurs').doc(utilisateurId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('photo')) {
          setState(() {
            utilisateurPhotoFileId = data['photo'] as String?;
          });
        }
      }
    } catch (_) {
      // ignorer erreur
    }
  }

  Future<void> _chargerNombreMessagesNonLus() async {
    if (utilisateurId == null || utilisateurId!.isEmpty) return;

    final query = await _firestore
        .collection('messages')
        .where('recepteurId', isEqualTo: utilisateurId)
        .where('lu', isEqualTo: false)
        .get();

    setState(() {
      nbMessagesNonLus = query.docs.length;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) {
      _chargerNombreMessagesNonLus();
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      pages = [
        DashboardEnseignantPage(),
        AppelPage(
          etablissementId: etablissementId ?? '',
          utilisateurId: utilisateurId ?? '',
        ),
        NotificationsPage(),
        MessagerieEnseignantPage(
          etablissementId: etablissementId ?? '',
          utilisateurId: utilisateurId ?? '',
        ),
        ParametresEnseignantPage(),
      ];
    }

    final photoUrl = _getAppwriteImageUrl(utilisateurPhotoFileId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${pageTitles[_selectedIndex]}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () => _onItemTapped(2),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.sms),
                tooltip: 'Messagerie',
                onPressed: () => _onItemTapped(3),
              ),
              if (nbMessagesNonLus > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$nbMessagesNonLus',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: photoUrl != null
                ? CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(photoUrl),
                    backgroundColor: Colors.transparent,
                  )
                : const Icon(Icons.account_circle),
            tooltip: 'Profil',
            onPressed: () {
              _onItemTapped(pageTitles.indexOf("Paramètres"));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () {
              logoutUser(context);
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(
          pageTitles.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(pageIcons[index]),
            label: pageTitles[index],
          ),
        ),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

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
  Icons.sms,
  Icons.settings,
];
