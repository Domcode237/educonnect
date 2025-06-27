import 'package:flutter/material.dart';

// Importe tes pages spécifiques pour élève à créer
import 'dashboard_eleve_page.dart';
import 'notes_eleve_page.dart';
import 'notifications_page.dart';
import 'parametres_eleve_page.dart';

class HomeEleve extends StatefulWidget {
  const HomeEleve({Key? key}) : super(key: key);

  @override
  State<HomeEleve> createState() => _HomeEleveState();
}

class _HomeEleveState extends State<HomeEleve> {
  int _selectedIndex = 0;

  late final List<String> pageTitles;
  late final List<IconData> pageIcons;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pageTitles = const [
      "Tableau de bord",
      "Mes notes",
      "Notifications",
      "Paramètres",
    ];

    pageIcons = const [
      Icons.dashboard,
      Icons.school,
      Icons.notifications,
      Icons.settings,
    ];

    pages = const [
      DashboardElevePage(),
      NotesElevePage(),
      NotificationsPage(),
      ParametresElevePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    // TODO: Implémenter la déconnexion (ex: FirebaseAuth.instance.signOut())
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;
    int currentIndex = _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _onItemTapped(2),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // TODO: Ouvrir profil élève
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _logout,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Text(
                'Menu Élève',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            for (int i = 0; i < pageTitles.length; i++)
              ListTile(
                leading: Icon(pageIcons[i]),
                title: Text(pageTitles[i]),
                selected: _selectedIndex == i,
                onTap: () {
                  Navigator.pop(context); // Fermer drawer
                  _onItemTapped(i);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: isWideScreen
          ? Row(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: NavigationRail(
                    selectedIndex: currentIndex,
                    onDestinationSelected: _onItemTapped,
                    labelType: NavigationRailLabelType.all,
                    useIndicator: true,
                    indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    minWidth: 180,
                    groupAlignment: -0.5,
                    destinations: List.generate(pageTitles.length, (i) {
                      final selected = i == _selectedIndex;
                      return NavigationRailDestination(
                        icon: Icon(pageIcons[i], color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
                        selectedIcon: Icon(pageIcons[i], color: Theme.of(context).colorScheme.primary),
                        label: Text(
                          pageTitles[i],
                          style: TextStyle(
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
                            fontSize: selected ? 14 : 12,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: pages[_selectedIndex],
                  ),
                ),
              ],
            )
          : pages[_selectedIndex],
      bottomNavigationBar: isWideScreen
          ? null
          : BottomNavigationBar(
              items: List.generate(
                pageTitles.length,
                (i) => BottomNavigationBarItem(icon: Icon(pageIcons[i]), label: pageTitles[i]),
              ),
              currentIndex: currentIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
            ),
    );
  }
}
