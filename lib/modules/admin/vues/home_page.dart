import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:educonnect/donnees/modeles/EtablissementModele.dart';

class ClasseModele {
  final String id;
  final String nom;
  final String niveau;
  final List<String> matieresIds;
  final List<String> elevesIds;
  final List<String> enseignantsIds;

  ClasseModele({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.matieresIds,
    required this.elevesIds,
    required this.enseignantsIds,
  });

  factory ClasseModele.fromMap(Map<String, dynamic> map, String id) {
    return ClasseModele(
      id: id,
      nom: map['nom'] ?? '',
      niveau: map['niveau'] ?? '',
      matieresIds: List<String>.from(map['matieresIds'] ?? []),
      elevesIds: List<String>.from(map['elevesIds'] ?? []),
      enseignantsIds: List<String>.from(map['enseignantsIds'] ?? []),
    );
  }
}

class HomePage extends StatefulWidget {
  final String etablissementId;
  final String adminId;

  const HomePage({
    super.key,
    required this.etablissementId,
    required this.adminId,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EtablissementModele? etablissement;
  String adminNom = "Administrateur";

  int totalUtilisateurs = 0;
  int nbAdmins = 0;
  int nbEleves = 0;
  int nbParents = 0;
  int nbEnseignants = 0;
  int nbClasses = 0;
  int nbMatieres = 0;
  int nbAnnonces = 0;

  List<ClasseModele> classes = [];
  bool isLoading = true;

  final ScrollController _scrollControllerClasses = ScrollController();

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _scrollControllerClasses.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => isLoading = true);
    final firestore = FirebaseFirestore.instance;

    try {
      final adminDoc = await firestore.collection('utilisateurs').doc(widget.adminId).get();
      if (adminDoc.exists) {
        final data = adminDoc.data()!;
        String prenom = data['prenom'] ?? '';
        String nom = data['nom'] ?? '';
        adminNom = (prenom.isNotEmpty || nom.isNotEmpty) ? "$prenom $nom" : adminNom;
      }

      final etabDoc = await firestore.collection('etablissements').doc(widget.etablissementId).get();
      if (!etabDoc.exists) throw Exception('Établissement introuvable');
      etablissement = EtablissementModele.fromMap(etabDoc.data()!, etabDoc.id);

      final rolesSnap = await firestore.collection('roles').get();
      final Map<String, String> rolesMap = {
        for (var doc in rolesSnap.docs) doc.id: doc['nom'] ?? '',
      };

      final utilisateursSnap = await firestore
          .collection('utilisateurs')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      totalUtilisateurs = utilisateursSnap.docs.length;
      nbAdmins = 0;
      nbParents = 0;
      nbEleves = 0;
      nbEnseignants = 0;

      for (var doc in utilisateursSnap.docs) {
        final roleId = doc.data()['roleId'];
        final roleNom = rolesMap[roleId] ?? '';

        switch (roleNom.toLowerCase()) {
          case 'administrateur':
            nbAdmins++;
            break;
          case 'parent':
            nbParents++;
            break;
          case 'eleve':
            nbEleves++;
            break;
          case 'enseignant':
            nbEnseignants++;
            break;
        }
      }

      final classesSnap = await firestore
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();
      classes = classesSnap.docs.map((doc) => ClasseModele.fromMap(doc.data(), doc.id)).toList();
      nbClasses = classes.length;

      final matieresSnap = await firestore
          .collection('matieres')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();
      nbMatieres = matieresSnap.docs.length;

      final annoncesSnap = await firestore
          .collection('annonces')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();
      nbAnnonces = annoncesSnap.docs.length;
    } catch (e) {
      debugPrint("Erreur chargement données : $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<BarChartGroupData> _buildBarChartData() {
    final data = [
      {'label': 'Admins', 'value': nbAdmins},
      {'label': 'Élèves', 'value': nbEleves},
      {'label': 'Parents', 'value': nbParents},
      {'label': 'Enseignants', 'value': nbEnseignants},
      {'label': 'Classes', 'value': nbClasses},
      {'label': 'Matières', 'value': nbMatieres},
      {'label': 'Annonces', 'value': nbAnnonces},
    ];

    return List.generate(data.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: (data[i]['value'] as num).toDouble(),
            color: Colors.deepPurple,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (etablissement == null) {
      return const Scaffold(body: Center(child: Text("Établissement non trouvé")));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Bienvenue, $adminNom !",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _infoCard("Nom", etablissement!.nom, Icons.school),
                  _infoCard("Description", etablissement!.description, Icons.description),
                  _infoCard("Type", etablissement!.type, Icons.category),
                  _infoCard(
                    "Adresse",
                    "${etablissement!.adresse}, ${etablissement!.ville}, ${etablissement!.region}, ${etablissement!.pays}",
                    Icons.location_on,
                  ),
                  _infoCard("Code Postal", etablissement!.codePostal, Icons.mail_outline),
                  _infoCard("Email", etablissement!.email, Icons.email),
                  _infoCard("Téléphone", etablissement!.telephone, Icons.phone),
                ],
              ),
              const SizedBox(height: 36),
              Text("Statistiques globales", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard("Utilisateurs", totalUtilisateurs, Icons.people),
                  _buildStatCard("Admins", nbAdmins, Icons.admin_panel_settings),
                  _buildStatCard("Élèves", nbEleves, Icons.school),
                  _buildStatCard("Parents", nbParents, Icons.family_restroom),
                  _buildStatCard("Enseignants", nbEnseignants, Icons.badge),
                  _buildStatCard("Classes", nbClasses, Icons.class_),
                  _buildStatCard("Matières", nbMatieres, Icons.menu_book),
                  _buildStatCard("Annonces", nbAnnonces, Icons.campaign),
                ],
              ),
              const SizedBox(height: 40),
              Text("Détails par classe", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Container(
                height: 270,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: classes.isEmpty
                    ? const Center(child: Text("Aucune donnée disponible"))
                    : Scrollbar(
                        controller: _scrollControllerClasses,
                        thumbVisibility: true,
                        child: ListView.builder(
                          controller: _scrollControllerClasses,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final classe = classes[index];
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              title: Text(classe.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                "Élèves : ${classe.elevesIds.length} | Enseignants : ${classe.enseignantsIds.length} | Matières : ${classe.matieresIds.length}",
                                style: const TextStyle(color: Colors.black87),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 40),
              Text("Répartition globale", style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: [
                      nbAdmins,
                      nbParents,
                      nbEleves,
                      nbEnseignants,
                      nbClasses,
                      nbMatieres,
                      nbAnnonces,
                    ].reduce((a, b) => a > b ? a : b).toDouble() + 5,
                    barGroups: _buildBarChartData(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final labels = [
                              'Admins',
                              'Élèves',
                              'Parents',
                              'Enseignants',
                              'Classes',
                              'Matières',
                              'Annonces',
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                labels[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true),
                    
                    // ✅ Affichage des valeurs en blanc lors du survol
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        // Pas de tooltipBgColor défini ici
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.toInt().toString(),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        elevation: 2,
        shadowColor: Colors.deepPurple.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.deepPurple, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Text(value,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon) {
    return SizedBox(
      width: 140,
      height: 120,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: Colors.deepPurple),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value.toString(),
                style: const TextStyle(fontSize: 18, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
