import 'package:flutter/material.dart';
import 'package:educonnect/modules/superadmin/vues/roles_page.dart';
import 'package:educonnect/modules/admin/vues/home_page.dart';
import 'package:educonnect/modules/admin/vues/parent_page.dart';
import 'package:educonnect/modules/admin/vues/annonce_page.dart';
import 'package:educonnect/modules/admin/vues/argenda_page.dart';
import 'package:educonnect/modules/admin/vues/classe_page.dart';
import 'package:educonnect/modules/admin/vues/page_eleve.dart';
import 'package:educonnect/modules/admin/vues/evernement_page.dart';
import 'package:educonnect/modules/admin/vues/matiere_page.dart';
import 'package:educonnect/modules/admin/vues/parametre_page.dart';
import 'package:educonnect/modules/admin/vues/page_enseigant.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';

class HomeAdmin extends StatefulWidget {
  final String monIdEtablissement;

  const HomeAdmin({super.key, required this.monIdEtablissement});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  int _selectedIndex = 0;

  late final List<String> pageTitles;
  late final List<IconData> fabIcons;
  late final List<Widget> pages;

  late final List<int> visibleIndices;

  @override
  void initState() {
    super.initState();

    pageTitles = const [
      "Tableau de bord",
      "Enseignant",
      "Classes",
      "Éleve",
      "Parent",
      "Matières",
      "Agendas",
      "Événements",
      "Rôles",
      "Annonces",
      "Paramètres",
    ];

    fabIcons = const [
      Icons.home,
      Icons.badge,
      Icons.class_,
      Icons.person,
      Icons.family_restroom,
      Icons.menu_book,
      Icons.event,
      Icons.event_note,
      Icons.verified_user,
      Icons.campaign,
      Icons.settings,
    ];

    pages = [
      HomePage(),
      ListeEnseignants(etablissementId: widget.monIdEtablissement),
      ClassesPage(monIdEtablissement: widget.monIdEtablissement),
      ListeEleves(etablissementId: widget.monIdEtablissement),
      ListeParents(etablissementId: widget.monIdEtablissement),
      MatieresPage(monIdEtablissement: widget.monIdEtablissement),
      AgendasPage(),
      EvenementsPage(),
      RolesPage(),
      AnnoncesPage(),
      ParametresPage(),
    ];

    visibleIndices = List.generate(pageTitles.length, (index) => index);
  }

  void _onItemTapped(int index) {
    if (index >= 0 && index < pages.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    int currentIndex = visibleIndices.indexOf(_selectedIndex);
    if (currentIndex == -1) {
      currentIndex = 0;
      _selectedIndex = visibleIndices[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {},
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
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Menu Admin',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (int i = 0; i < pageTitles.length; i++)
              ListTile(
                leading: Icon(fabIcons[i]),
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
              title: const Text('Déconnexion'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: isWideScreen
          ? Row(
              children: [
                // On donne une hauteur fixe égale à la hauteur de l'écran
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      _onItemTapped(visibleIndices[index]);
                    },
                    labelType: NavigationRailLabelType.all,
                    useIndicator: true,
                    indicatorShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    minWidth: 180,
                    groupAlignment: -0.5,
                    destinations: visibleIndices.map((i) {
                      final selected = i == _selectedIndex;
                      return NavigationRailDestination(
                        icon: Icon(
                          fabIcons[i],
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                          size: selected ? 24 : 20,
                        ),
                        selectedIcon: Icon(
                          fabIcons[i],
                          color: Theme.of(context).colorScheme.primary,
                          size: 26,
                        ),
                        label: Text(
                          pageTitles[i],
                          style: TextStyle(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade600,
                            fontSize: selected ? 14 : 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                    child: pages[_selectedIndex],
                  ),
                ),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              items: visibleIndices
                  .map((i) => BottomNavigationBarItem(
                        icon: Icon(fabIcons[i]),
                        label: pageTitles[i],
                      ))
                  .toList(),
              currentIndex: currentIndex,
              onTap: (index) => _onItemTapped(visibleIndices[index]),
            ),
    );
  }
}
