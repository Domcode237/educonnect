import 'package:flutter/material.dart';
import 'package:educonnect/modules/superadmin/vues/roles_page.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<HomeAdmin> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    "Tableau de bord",
    "Écoles",
    "Classes",
    "Matières",
    "Administrateurs",
    "Utilisateurs",
    "Agendas",
    "Événements",
    "Rôles",
    "Annonces",
    "Paramètres",
  ];

  final List<IconData> _fabIcons = [
    Icons.dashboard,
    Icons.school,
    Icons.class_,
    Icons.menu_book,
    Icons.admin_panel_settings,
    Icons.people,
    Icons.calendar_month,
    Icons.event,
    Icons.verified_user,
    Icons.campaign,
    Icons.settings,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Ferme le drawer après sélection
    });
  }

  Widget _buildThemedDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        'Menu Super Admin',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    return Center(
      child: Text(
        _pageTitles[index],
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNavigation(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final visibleIndices = [0, 1, 2, 3, 4];

    final destinations = visibleIndices
        .map(
          (index) => NavigationRailDestination(
            icon: Icon(_fabIcons[index]),
            selectedIcon: Icon(_fabIcons[index], color: Theme.of(context).primaryColor),
            label: Text(_pageTitles[index]),
          ),
        )
        .toList();

    if (isWideScreen) {
      return NavigationRail(
        selectedIndex: visibleIndices.indexOf(_selectedIndex),
        onDestinationSelected: (int selected) => _onItemTapped(visibleIndices[selected]),
        labelType: NavigationRailLabelType.all,
        leading: const SizedBox(height: 24),
        destinations: destinations,
      );
    } else {
      return BottomNavigationBar(
        currentIndex: visibleIndices.indexOf(_selectedIndex),
        onTap: (int selected) => _onItemTapped(visibleIndices[selected]),
        items: visibleIndices
            .map(
              (index) => BottomNavigationBarItem(
                icon: Icon(_fabIcons[index]),
                label: _pageTitles[index],
              ),
            )
            .toList(),
        type: BottomNavigationBarType.fixed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Notification logic
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Profil utilisateur
            },
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: ListView(
          children: [
            _buildThemedDrawerHeader(context),
            for (int i = 0; i < _pageTitles.length; i++)
              ListTile(
                leading: Icon(_fabIcons[i]),
                title: Text(_pageTitles[i]),
                selected: _selectedIndex == i,
                onTap: () {
                if (_pageTitles[i] == "Rôles") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RolesPage()),
                  );
                } else {
                  _onItemTapped(i);
                }
              },

              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () {
                // Déconnexion logic
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          if (isWideScreen) ...[
            _buildNavigation(context),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(child: _buildPage(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : _buildNavigation(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Action pour ${_pageTitles[_selectedIndex]}"),
          ));
        },
        child: Icon(_fabIcons[_selectedIndex]),
      ),
    );
  }
}
