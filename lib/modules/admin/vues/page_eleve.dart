import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/admin/vues/modifer_eleve.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';

class ListeEleves extends StatefulWidget {
  final String etablissementId;

  const ListeEleves({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String searchQuery = '';
  String? roleEleveId;
  String? selectedClasseId;
  List<Map<String, String>> classes = [];
  bool isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _chargerRoleEleve();
    await _chargerClasses();
  }

  Future<void> _chargerRoleEleve() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('roles')
          .where('nom', isEqualTo: 'eleve')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          roleEleveId = snapshot.docs.first.id;
        });
      }
    } catch (e) {
      debugPrint("Erreur role eleve: $e");
    }
  }

  Future<void> _chargerClasses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      List<Map<String, String>> loadedClasses = [];

      for (var doc in snapshot.docs) {
        final classe = ClasseModele.fromMap(doc.data(), doc.id);
        loadedClasses.add({'id': classe.id, 'nom': classe.nom});
      }

      setState(() {
        classes = loadedClasses;
        isLoadingClasses = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement classes: $e");
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  Future<void> _supprimerUtilisateur(BuildContext context, String docId) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Voulez-vous vraiment supprimer cet élève ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance.collection('utilisateurs').doc(docId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Élève supprimé avec succès')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
      }
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    if (roleEleveId == null) {
      return const Stream.empty();
    }

    final ref = FirebaseFirestore.instance
        .collection('utilisateurs')
        .where('roleId', isEqualTo: roleEleveId)
        .where('etablissementId', isEqualTo: widget.etablissementId);

    if (selectedClasseId != null) {
      return ref.where('classeId', isEqualTo: selectedClasseId).snapshots();
    } else {
      return ref.snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20), // un peu moins de padding
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterBar(),
              const SizedBox(height: 12),
              Expanded(
                child: roleEleveId == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                        stream: _buildStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text("Erreur : ${snapshot.error}"));
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final eleves = docs
                              .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final utilisateur = UtilisateurModele.fromMap(data, doc.id);
                                final classeId = data['classeId'] ?? '';
                                return EleveModele(utilisateur: utilisateur, classeId: classeId, notes: []);
                              })
                              .where((eleve) =>
                                  eleve.utilisateur.nom.toLowerCase().contains(searchQuery) ||
                                  eleve.utilisateur.prenom.toLowerCase().contains(searchQuery) ||
                                  eleve.utilisateur.email.toLowerCase().contains(searchQuery))
                              .toList();

                          if (eleves.isEmpty) {
                            return const Center(child: Text("Aucun élève trouvé."));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: eleves.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('classes').doc(eleves[index].classeId).get(),
                                  builder: (context, classeSnapshot) {
                                    String classeNom = 'Classe inconnue';
                                    if (classeSnapshot.hasData && classeSnapshot.data!.exists) {
                                      final dataClasse = classeSnapshot.data!.data() as Map<String, dynamic>;
                                      classeNom = dataClasse['nom'] ?? 'Classe inconnue';
                                    }
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/elevedetail',
                                          arguments: eleves[index].utilisateur.id,
                                        );
                                      },
                                      child: _buildUtilisateurCard(context, eleves[index], classeNom, isLargeScreen, isTablet),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/ajouteleve'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        hintText: 'Rechercher un élève...',
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value.toLowerCase();
        });
      },
    );
  }

  Widget _buildFilterBar() {
    return isLoadingClasses
        ? const Center(child: CircularProgressIndicator())
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nombre d'élèves chargés", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              DropdownButton<String?>(
                value: selectedClasseId,
                hint: const Text("Filtrer par classe"),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Toutes les classes")),
                  ...classes.map(
                    (classe) => DropdownMenuItem(
                      value: classe['id'],
                      child: Text(classe['nom']!, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedClasseId = value),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          );
  }

  Widget _buildUtilisateurCard(BuildContext context, EleveModele eleve, String classeNom, bool isLargeScreen, bool isTablet) {
  double avatarRadius = isLargeScreen ? 25 : (isTablet ? 22 : 18);
  double fontSize = isLargeScreen ? 16 : (isTablet ? 14 : 12);
  double infoFontSize = isLargeScreen ? 14 : (isTablet ? 12 : 10);

  final utilisateur = eleve.utilisateur;
  final primaryColor = Colors.blueAccent;
  final secondaryColor = Colors.blue.shade100;
  final deleteColor = Colors.redAccent;
  final textColor = Colors.black87;
  final subTextColor = Colors.grey[700];

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EleveDetailCard(eleve: eleve, classeNom: classeNom),
        ),
      );
    },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: secondaryColor,
                child: Icon(Icons.person, size: avatarRadius, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${utilisateur.nom} ${utilisateur.prenom}",
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 2),
                    Text(utilisateur.email, style: TextStyle(fontSize: infoFontSize, color: subTextColor)),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: primaryColor, size: infoFontSize + 6),
                    tooltip: "Modifier",
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ModificationEleveVue(eleveId: utilisateur.id)),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: deleteColor, size: infoFontSize + 6),
                    tooltip: "Supprimer",
                    onPressed: () => _supprimerUtilisateur(context, utilisateur.id),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, color: subTextColor, size: infoFontSize),
              const SizedBox(width: 6),
              Expanded(
                child: Text(utilisateur.numeroTelephone ?? '-', style: TextStyle(fontSize: infoFontSize, color: textColor)),
              ),
              Icon(Icons.home, color: subTextColor, size: infoFontSize),
              const SizedBox(width: 6),
              Expanded(
                child: Text(utilisateur.adresse ?? '-', style: TextStyle(fontSize: infoFontSize, color: textColor)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.class_, color: primaryColor, size: infoFontSize),
                    const SizedBox(width: 4),
                    Text(
                      classeNom,
                      style: TextStyle(
                        fontSize: infoFontSize,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}


class EleveDetailCard extends StatelessWidget {
  final EleveModele eleve;
  final String classeNom;

  const EleveDetailCard({Key? key, required this.eleve, required this.classeNom}) : super(key: key);

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Color.fromARGB(255, 19, 51, 76)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[700],
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey[900],
          letterSpacing: 1.2,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(14),
        // boxShadow: [
        //   BoxShadow(
        //     color: const Color.fromARGB(66, 6, 171, 253).withOpacity(0.1),
        //     blurRadius: 6,
        //     offset: const Offset(0, 3),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final utilisateur = eleve.utilisateur;

    return Scaffold(
      appBar: AppBar(
        title: Text('${utilisateur.nom} ${utilisateur.prenom}'),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 19, 51, 76),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Color.fromARGB(255, 19, 51, 76),
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '${utilisateur.nom} ${utilisateur.prenom}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 19, 51, 76),
                  ),
                ),
                const SizedBox(height: 32),

                // Identité
                _buildSection('Identité', [
                  _infoRow(Icons.badge, 'Nom complet:', '${utilisateur.nom} ${utilisateur.prenom}'),
                ]),

                // Contact
                _buildSection('Contact', [
                  _infoRow(Icons.email, 'Email:', utilisateur.email),
                  _infoRow(Icons.phone, 'Téléphone:', utilisateur.numeroTelephone.isNotEmpty ? utilisateur.numeroTelephone : '-'),
                  _infoRow(Icons.home, 'Adresse:', utilisateur.adresse.isNotEmpty ? utilisateur.adresse : '-'),
                ]),

                // Classe
                _buildSection('Classe', [
                  _infoRow(Icons.class_, 'Nom:', classeNom),
                ]),

                // Statut
                _buildSection('Statut', [
                  _infoRow(Icons.check_circle_outline, 'État:', utilisateur.statut ? 'En ligne' : 'Hors ligne'),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
