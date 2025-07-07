import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/admin/vues/modifer_eleve.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';
import 'package:educonnect/modules/admin/vues/ajouter_eleve.dart';
import 'package:educonnect/main.dart';

class ListeEleves extends StatefulWidget {
  final String etablissementId;

  const ListeEleves({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeEleves> createState() => _ListeElevesState();
}

class _ListeElevesState extends State<ListeEleves> {
  String searchQuery = '';
  String? selectedClasseId;

  List<ClasseModele> classes = [];
  Map<String, UtilisateurModele> utilisateursMap = {};
  Map<String, ClasseModele> classesMap = {};
  List<EleveModele> eleves = [];

  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Charger les classes
      final classesSnap = await FirebaseFirestore.instance
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      classes = classesSnap.docs
          .map((doc) => ClasseModele.fromMap(doc.data(), doc.id))
          .toList();

      classesMap = {for (var c in classes) c.id: c};

      // Charger les utilisateurs de l'établissement
      final usersSnap = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .get();

      utilisateursMap = {
        for (var doc in usersSnap.docs)
        doc.id: UtilisateurModele.fromMap(doc.data(), doc.id),
      };

      // Charger les élèves liés aux utilisateurs chargés
      // Attention: Firestore whereIn max 10 items => batcher par 10
      List<EleveModele> loadedEleves = [];
      final userIds = utilisateursMap.keys.toList();

      for (int i = 0; i < userIds.length; i += 10) {
        final batchIds = userIds.sublist(
          i,
          i + 10 > userIds.length ? userIds.length : i + 10,
        );

        Query query = FirebaseFirestore.instance.collection('eleves')
            .where('utilisateurId', whereIn: batchIds);

        if (selectedClasseId != null && selectedClasseId!.isNotEmpty) {
          query = query.where('classeId', isEqualTo: selectedClasseId);
        }

        final elevesSnap = await query.get();

        loadedEleves.addAll(
          elevesSnap.docs
              .map((doc) => EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
        );
      }

      eleves = loadedEleves;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<EleveModele> _filtrerEleves() {
    final query = searchQuery.toLowerCase();

    return eleves.where((eleve) {
      final utilisateur = utilisateursMap[eleve.utilisateurId];
      if (utilisateur == null) return false;

      // Filtre recherche
      if (query.isNotEmpty) {
        final fullName = '${utilisateur.nom} ${utilisateur.prenom}'.toLowerCase();
        if (!fullName.contains(query)) return false;
      }

      // Filtre classe
      if (selectedClasseId != null && selectedClasseId!.isNotEmpty) {
        if (eleve.classeId != selectedClasseId) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _supprimerUtilisateur(BuildContext context, String utilisateurId, String eleveId) async {
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
        await FirebaseFirestore.instance.collection('eleves').doc(eleveId).delete();
        await FirebaseFirestore.instance.collection('utilisateurs').doc(utilisateurId).delete();
        await _chargerDonnees();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Élève supprimé avec succès')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
      }
    }
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    return '${appwriteClient.endPoint}/storage/buckets/6854df330032c7be516c/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final filteredEleves = _filtrerEleves();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterBar(),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text("Erreur : $error"))
                        : filteredEleves.isEmpty
                            ? const Center(child: Text("Aucun élève trouvé."))
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: filteredEleves.length,
                                itemBuilder: (context, index) {
                                  final eleve = filteredEleves[index];
                                  final utilisateur = utilisateursMap[eleve.utilisateurId];
                                  final classe = classesMap[eleve.classeId];
                                  if (utilisateur == null) {
                                    return const ListTile(title: Text('Utilisateur non trouvé'));
                                  }
                                  return _buildUtilisateurCard(
                                    context,
                                    eleve,
                                    utilisateur,
                                    classe?.nom ?? 'Classe inconnue',
                                    isLargeScreen,
                                    isTablet,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AjoutEleveVue(etablissementId: widget.etablissementId),
            ),
          );
          await _chargerDonnees();
        },
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
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Nombre d'élèves chargés : ${eleves.length}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              DropdownButton<String?>(
                value: selectedClasseId,
                hint: const Text("Filtrer par classe"),
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: null, child: Text("Toutes les classes")),
                  ...classes.map(
                    (classe) => DropdownMenuItem(
                      value: classe.id,
                      child: Text(classe.nom, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ],
                onChanged: (value) async {
                  setState(() {
                    selectedClasseId = value;
                  });
                  await _chargerDonnees();
                },
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          );
  }

  Widget _buildUtilisateurCard(BuildContext context, EleveModele eleve, UtilisateurModele utilisateur, String classeNom, bool isLargeScreen, bool isTablet) {
    double avatarRadius = isLargeScreen ? 25 : (isTablet ? 22 : 18);
    double fontSize = isLargeScreen ? 16 : (isTablet ? 14 : 12);
    double infoFontSize = isLargeScreen ? 14 : (isTablet ? 12 : 10);

    final primaryColor = Colors.blueAccent;
    final secondaryColor = Colors.blue.shade100;
    final deleteColor = Colors.redAccent;
    final textColor = Colors.black87;
    final subTextColor = Colors.grey[700];

    final photoUrl = _getAppwriteImageUrl(utilisateur.photo);

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
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? Icon(Icons.person, size: avatarRadius, color: primaryColor) : null,
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
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ModificationEleveVue(eleveId: eleve.id)),
                        );
                        await _chargerDonnees();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: deleteColor, size: infoFontSize + 6),
                      tooltip: "Supprimer",
                      onPressed: () => _supprimerUtilisateur(context, utilisateur.id, eleve.id),
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
                  child: Text(
                    utilisateur.numeroTelephone.isNotEmpty ? utilisateur.numeroTelephone : '-',
                    style: TextStyle(fontSize: infoFontSize, color: textColor),
                  ),
                ),
                Icon(Icons.home, color: subTextColor, size: infoFontSize),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    utilisateur.adresse.isNotEmpty ? utilisateur.adresse : '-',
                    style: TextStyle(fontSize: infoFontSize, color: textColor),
                  ),
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
          Icon(icon, size: 22, color: const Color.fromARGB(255, 19, 51, 76)),
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
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('utilisateurs').doc(eleve.utilisateurId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Utilisateur non trouvé')),
          );
        }

        final utilisateur = UtilisateurModele.fromMap(
          snapshot.data!.data()! as Map<String, dynamic>,
          snapshot.data!.id,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text('${utilisateur.nom} ${utilisateur.prenom}'),
            centerTitle: true,
            backgroundColor: const Color.fromARGB(255, 19, 51, 76),
            elevation: 1,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSection('INFORMATIONS PERSONNELLES', [
                  _infoRow(Icons.person, 'Nom complet', '${utilisateur.nom} ${utilisateur.prenom}'),
                  _infoRow(Icons.email, 'Email', utilisateur.email),
                  _infoRow(Icons.phone, 'Téléphone', utilisateur.numeroTelephone.isNotEmpty ? utilisateur.numeroTelephone : '-'),
                  _infoRow(Icons.home, 'Adresse', utilisateur.adresse.isNotEmpty ? utilisateur.adresse : '-'),
                  _infoRow(Icons.class_, 'Classe', classeNom),
                ]),
                // Ajoute ici d'autres sections si besoin
              ],
            ),
          ),
        );
      },
    );
  }
}
