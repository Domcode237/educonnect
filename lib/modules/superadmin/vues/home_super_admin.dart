import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:educonnect/modules/superadmin/vues/roles_page.dart';
import 'package:educonnect/modules/superadmin/vues/etablissements_page.dart';
import 'package:educonnect/modules/superadmin/vues/page_administrateur.dart';
import 'package:educonnect/modules/superadmin/vues/page_utilisateur.dart';
import 'package:educonnect/modules/superadmin/vues/page_paramettre.dart';
import 'package:educonnect/vues/commun/deconnexion.dart';
class HomeSuperAdmin extends StatefulWidget {
  const HomeSuperAdmin({super.key});

  @override
  State<HomeSuperAdmin> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<HomeSuperAdmin> {
  int _selectedIndex = 0;
  bool _isLoading = true;

  final List<String> _pageTitles = [
    "Accueil",
    "Écoles",
    "Utilisateurs",
    "Rôles",
    "Administrateurs",
  ];

  final List<IconData> _fabIcons = [
    Icons.home,
    Icons.school,
    Icons.people,
    Icons.verified_user,
    Icons.admin_panel_settings,
  ];

  final Map<String, int> stats = {
    'etablissements': 0,
    'utilisateurs': 0,
    'roles': 0,
    'administrateurs': 0,
  };

  List<Map<String, dynamic>> usageStats = [];

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    setState(() {
      _isLoading = true;
    });

    final firestore = FirebaseFirestore.instance;

    try {
      // On lance les requêtes en parallèle pour optimiser
      final futures = await Future.wait([
        firestore.collection('etablissements').get(),
        firestore.collection('roles').get(),
        firestore.collection('administrateurs').get(),
        firestore.collection('utilisateurs').get(),
      ]);

      final etablissementsSnapshot = futures[0];
      final rolesSnapshot = futures[1];
      final adminSnapshot = futures[2];
      final utilisateursSnapshot = futures[3];

      final int adminCount = adminSnapshot.size;
      final int totalUtilisateurs = utilisateursSnapshot.size + adminCount;

      // Comptage par établissement
      Map<String, int> etablissementUsageMap = {};
      for (var doc in utilisateursSnapshot.docs) {
        final data = doc.data();
        final etab = data['etablissement']?.toString() ?? 'Inconnu';
        etablissementUsageMap[etab] = (etablissementUsageMap[etab] ?? 0) + 1;
      }

      setState(() {
        stats['etablissements'] = etablissementsSnapshot.size;
        stats['roles'] = rolesSnapshot.size;
        stats['administrateurs'] = adminCount;
        stats['utilisateurs'] = totalUtilisateurs;

        usageStats = etablissementUsageMap.entries
            .map((entry) => {
                  'etablissement': entry.key,
                  'utilisateurs': entry.value,
                })
            .toList();

        _isLoading = false;
      });
    } catch (e, st) {
      // Affiche un message d'erreur dans la console, utile pour debug
      debugPrint('Erreur fetchStats: $e');
      debugPrintStack(stackTrace: st);

      setState(() {
        _isLoading = false;
        // Tu peux aussi réinitialiser les stats ou laisser les anciennes
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildPage(int index) {
    switch (_pageTitles[index]) {
      case "Accueil":
        return _buildHomePage();
      case "Écoles":
        return const EtablissementsPage();
      case "Rôles":
        return const RolesPage();
      case "Administrateurs":
        return const ListeAdministrateurs();
      case "Utilisateurs":
        return const ListeUtilisateurs();
      default:
        return Center(
          child: Text(
            _pageTitles[index],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  Widget _buildHomePage() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossCount = screenWidth > 800 ? 4 : screenWidth > 600 ? 3 : 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                GridView.count(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _DashboardCard(
                      icon: Icons.people,
                      label: 'Utilisateurs',
                      count: stats['utilisateurs'] ?? 0,
                      onTap: () => _onItemTapped(_pageTitles.indexOf("Utilisateurs")),
                    ),
                    _DashboardCard(
                      icon: Icons.school,
                      label: 'Établissements',
                      count: stats['etablissements'] ?? 0,
                      onTap: () => _onItemTapped(_pageTitles.indexOf("Écoles")),
                    ),
                    _DashboardCard(
                      icon: Icons.verified_user,
                      label: 'Rôles',
                      count: stats['roles'] ?? 0,
                      onTap: () => _onItemTapped(_pageTitles.indexOf("Rôles")),
                    ),
                    _DashboardCard(
                      icon: Icons.admin_panel_settings,
                      label: 'Administrateurs',
                      count: stats['administrateurs'] ?? 0,
                      onTap: () => _onItemTapped(_pageTitles.indexOf("Administrateurs")),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Performance par établissement',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                usageStats.isEmpty
                    ? const Center(child: Text("Aucune donnée disponible"))
                    : AspectRatio(
                        aspectRatio: 1.6,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index >= 0 && index < usageStats.length) {
                                      return Text(
                                        usageStats[index]['etablissement']
                                            .toString()
                                            .split(' ')
                                            .last,
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: usageStats.asMap().entries.map((entry) {
                              int i = entry.key;
                              int value = entry.value['utilisateurs'];
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: value.toDouble(),
                                    color: Theme.of(context).primaryColor,
                                    width: 22,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ],
            ),
    );
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

  Widget _buildNavigation(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final destinations = List.generate(
      _pageTitles.length,
      (index) => NavigationRailDestination(
        icon: Icon(_fabIcons[index], color: Colors.grey),
        selectedIcon: Icon(_fabIcons[index], color: Colors.white),
        label: Text(_pageTitles[index]),
      ),
    );

    if (isWideScreen) {
      return NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelType: NavigationRailLabelType.all,
        leading: const SizedBox(height: 24),
        destinations: destinations,
      );
    } else {
      return BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: List.generate(
          _pageTitles.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_fabIcons[index]),
            label: _pageTitles[index],
          ),
        ),
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParametresPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              logoutUser(context); // Appelle ta fonction en lui passant le context
            },
          ),
        ],
      ),
      drawer: Drawer(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: ListView(
          children: [
            _buildThemedDrawerHeader(context),
            for (int i = 0; i < _pageTitles.length; i++)
              ListTile(
                leading: Icon(_fabIcons[i]),
                title: Text(_pageTitles[i]),
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
              onTap: () {
                logoutUser(context); // Appel de la fonction de déconnexion avec le context
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
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Center(
            key: ValueKey(count),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: Theme.of(context).primaryColor),
                const SizedBox(height: 6),
                Text('$count', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
