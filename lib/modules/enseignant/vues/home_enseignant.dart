import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/main.dart';

import 'dashboard_enseignant_page.dart';
import 'appel.dart';
import 'notifications_page.dart';
import 'messagerie_enseignant_page.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';
import 'package:educonnect/modules/enseignant/vues/devoir_page.dart';
import 'profil.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'note.dart';

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
  UtilisateurModele? utilisateurModele;

  int nbMessagesNonLus = 0;
  int nbNotifsNonLues = 0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> pageTitles = [
    "Accueil",
    "Appel",
    "Annonces",
    "Messagerie",
    "Devoirs",
    'notes',
  ];

  final List<IconData> pageIcons = [
    Icons.home,
    Icons.group,
    Icons.notifications,
    Icons.message_rounded,
    Icons.assignment,
    Icons.bar_chart,
  ];

  List<Widget> pages = List.filled(5, const SizedBox());

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _annoncesSubscription;

  int _nbNotifsClassiques = 0;
  int _nbAnnoncesNonLues = 0;

  @override
  void initState() {
    super.initState();
    print("initState: lancement _loadUserData");
    _loadUserData();
  }

  @override
  void dispose() {
    print("dispose: annulation des subscriptions");
    _messagesSubscription?.cancel();
    _notificationsSubscription?.cancel();
    _annoncesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    print("Chargement de l'utilisateur ${widget.utilisateurId}");
    final utilisateurDoc = await _firestore
        .collection('utilisateurs')
        .doc(widget.utilisateurId)
        .get();

    if (utilisateurDoc.exists) {
      print("Utilisateur trouvé");
      utilisateurModele =
          UtilisateurModele.fromMap(utilisateurDoc.data()!, utilisateurDoc.id);
    } else {
      print("Utilisateur NON trouvé");
      return;
    }

    final enseignantSnap = await _firestore
        .collection('enseignants')
        .where('utilisateurId', isEqualTo: widget.utilisateurId)
        .limit(1)
        .get();

    if (enseignantSnap.docs.isNotEmpty) {
      enseignantId = enseignantSnap.docs.first.id;
      print("Enseignant trouvé avec ID $enseignantId");
    } else {
      print("Enseignant non trouvé");
    }

    await _chargerPhotoUtilisateur();

    if (enseignantId != null) {
      print("Abonnement messages non lus pour enseignant $enseignantId");
      _messagesSubscription = _firestore
          .collection('messages')
          .where('recepteurId', isEqualTo: enseignantId)
          .where('lu', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        print("Messages non lus: ${snapshot.docs.length}");
        setState(() {
          nbMessagesNonLus = snapshot.docs.length;
        });
      });
    }

    print("Abonnement notifications classiques pour utilisateur ${widget.utilisateurId}");
    _notificationsSubscription = _firestore
        .collection('notifications')
        .where('recepteurId', isEqualTo: widget.utilisateurId)
        .where('lu', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      int nbNotifsClassiques = snapshot.docs.length;
      print("Notifications classiques non lues: $nbNotifsClassiques");
      _nbNotifsClassiques = nbNotifsClassiques;
      _mettreAJourNombreNotifications();
    });

    print("Abonnement annonces pour utilisateur ${widget.utilisateurId}");
    _annoncesSubscription = _firestore
        .collection('annonces')
        .where('utilisateursConcernees', arrayContains: widget.utilisateurId)
        .snapshots()
        .listen((snapshot) {
      int nbAnnoncesNonLues = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        List<dynamic> luePar = data['luePar'] ?? [];
        if (!luePar.contains(widget.utilisateurId)) {
          nbAnnoncesNonLues++;
          print("Annonce non lue trouvée: id=${doc.id} titre=${data['titre'] ?? 'sans titre'}");
        }
      }

      print("Nombre d'annonces non lues: $nbAnnoncesNonLues");
      _nbAnnoncesNonLues = nbAnnoncesNonLues;

      _mettreAJourNombreNotifications();
    });

    pages = [
      DashboardEnseignantPage(enseignant: utilisateurModele!),
      AppelPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
      ),
      ListeAnnoncesEnseignantPage(
        etablissementId: widget.etablissementId,
        enseignantId: widget.utilisateurId,
      ),
      MessagerieEnseignantPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
      ),
      CreationDevoirPage(
        etablissementId: widget.etablissementId,
        enseignantUtilisateurId: widget.utilisateurId,
      ),
      NotesPage(
        etablissementId: widget.etablissementId,
        utilisateurId: widget.utilisateurId,
      ),
    ];

    setState(() {
      print("Pages initialisées");
    });
  }

  void _mettreAJourNombreNotifications() {
    print("Mise à jour total notifications: class=$_nbNotifsClassiques + annonces=$_nbAnnoncesNonLues");
    setState(() {
      nbNotifsNonLues = _nbNotifsClassiques + _nbAnnoncesNonLues;
    });
  }

  Future<void> _chargerPhotoUtilisateur() async {
    try {
      final doc = await _firestore
          .collection('utilisateurs')
          .doc(widget.utilisateurId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('photoFileId')) {
          utilisateurPhotoFileId = data['photoFileId'] as String?;
          print("Photo utilisateur chargée: $utilisateurPhotoFileId");
        } else {
          print("Aucune photo utilisateur");
        }
      } else {
        print("Doc utilisateur inexistant");
      }
    } catch (e) {
      print("Erreur lors du chargement photo utilisateur: $e");
    }
  }

  String? _getPhotoUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  void _onItemTapped(int index) {
    print("Changement page: index $index");
    setState(() => _selectedIndex = index);
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
    final photoUrl = _getPhotoUrl(utilisateurPhotoFileId);

    if (utilisateurModele == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProfilUtilisateurPage(utilisateurId: widget.utilisateurId),
                ),
              );
            },
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
                          i == 2 ? nbNotifsNonLues : i == 3 ? nbMessagesNonLus : 0,
                        ),
                        label: Text(pageTitles[i]),
                      );
                    }),
                    leading: const SizedBox(height: 25), // ✅ espace haut
                    trailing: const SizedBox(height: 200), // ✅ espace bas
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
                    i == 2 ? nbNotifsNonLues : i == 3 ? nbMessagesNonLus : 0,
                  ),
                  label: pageTitles[i],
                );
              }),
            ),
    );
  }
}
