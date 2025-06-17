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
import 'package:educonnect/modules/admin/vues/utilisateur_page.dart';

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

  @override
  void initState() {
    super.initState();

    pageTitles = const [
      "Tableau de bord",
      "Matières",
      "Classes",
      "Éleve", 
      "Parent",
      "Utilisateurs",
      "Agendas",
      "Événements",
      "Rôles",
      "Annonces",
      "Paramètres",
    ];

    fabIcons = const [
      Icons.home,
      Icons.menu_book,
      Icons.class_,
      Icons.person,
      Icons.family_restroom,
      Icons.people,
      Icons.calendar_month,
      Icons.event,
      Icons.verified_user,
      Icons.campaign,
      Icons.settings,
    ];

    pages = [
      HomePage(),
      MatieresPage(monIdEtablissement: widget.monIdEtablissement),
      ClassesPage(monIdEtablissement: widget.monIdEtablissement),
      ListeEleves(etablissementId: widget.monIdEtablissement),
      ListeParents(etablissementId: widget.monIdEtablissement),
      UtilisateursPage(),
      AgendasPage(),
      EvenementsPage(),
      RolesPage(),
      AnnoncesPage(),
      ParametresPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
Widget build(BuildContext context) {
  final bool isWideScreen = MediaQuery.of(context).size.width >= 600;
  final visibleIndices = [0, 1, 2, 3, 4]; // Indices visibles dans la nav inférieure et NavigationRail

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
              NavigationRail(
                selectedIndex: visibleIndices.indexOf(_selectedIndex),
                onDestinationSelected: (index) {
                  _onItemTapped(visibleIndices[index]);
                },
                labelType: NavigationRailLabelType.all, // Labels toujours visibles
                useIndicator: true, // Active l'indicateur de sélection intégré (Flutter 3.7+)
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                backgroundColor: Theme.of(context).colorScheme.surface,
                minWidth: 180,
                groupAlignment: -0.9, // Positionne un peu vers le haut
                destinations: visibleIndices.map((i) {
                  final selected = i == _selectedIndex;
                  return NavigationRailDestination(
                    icon: Icon(
                      fabIcons[i],
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade600,
                      size: selected ? 30 : 24,
                    ),
                    selectedIcon: Icon(
                      fabIcons[i],
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                    label: Text(
                      pageTitles[i],
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade600,
                        fontSize: selected ? 16 : 14,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const VerticalDivider(thickness: 1, width: 1),
              // Le contenu principal qui prend tout le reste de la largeur
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 12),
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
            currentIndex: visibleIndices.indexOf(_selectedIndex),
            onTap: (index) => _onItemTapped(visibleIndices[index]),
          ),
  );
}
}