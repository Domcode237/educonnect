import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:educonnect/modules/admin/vues/modifier_parent.dart';
import 'package:educonnect/modules/admin/vues/ajouter_parent.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ClasseModele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';

class ListeParents extends StatefulWidget {
  final String etablissementId;

  const ListeParents({Key? key, required this.etablissementId}) : super(key: key);

  @override
  State<ListeParents> createState() => _ListeParentsState();
}

class _ListeParentsState extends State<ListeParents> {
  String searchQuery = '';
  String? roleParentId;
  String? selectedClasseId;
  List<Map<String, String>> classes = [];
  bool isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _chargerRoleParent();
    await _chargerClasses();
  }

  Future<void> _chargerRoleParent() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('roles')
          .where('nom', isEqualTo: 'parent')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          roleParentId = snapshot.docs.first.id;
        });
      }
    } catch (e) {
      debugPrint("Erreur role parent: $e");
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
        content: const Text("Voulez-vous vraiment supprimer ce parent ?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      try {
        await FirebaseFirestore.instance.collection('utilisateurs').doc(docId).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent supprimé avec succès')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
      }
    }
  }

  Stream<QuerySnapshot> _buildStream() {
    if (roleParentId == null) {
      return const Stream.empty();
    }

    final ref = FirebaseFirestore.instance
        .collection('utilisateurs')
        .where('roleId', isEqualTo: roleParentId)
        .where('etablissementId', isEqualTo: widget.etablissementId);

    if (selectedClasseId != null) {
      return ref.where('enfantsClasseIds', arrayContains: selectedClasseId).snapshots();
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
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20),
          child: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterBar(),
              const SizedBox(height: 12),
              Expanded(
                child: roleParentId == null
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
                          final parents = docs
                              .map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final utilisateur = UtilisateurModele.fromMap(data, doc.id);
                                return ParentModele(
                                  utilisateur: utilisateur,
                                  enfants: List<String>.from(data['enfantsIds'] ?? []),
                                  id: doc.id,
                                );
                              })
                              .where((parent) =>
                                  parent.utilisateur.nom.toLowerCase().contains(searchQuery) ||
                                  parent.utilisateur.prenom.toLowerCase().contains(searchQuery) ||
                                  parent.utilisateur.email.toLowerCase().contains(searchQuery))
                              .toList();

                          if (parents.isEmpty) {
                            return const Center(child: Text("Aucun parent trouvé."));
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: parents.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: _buildUtilisateurCard(context, parents[index], isLargeScreen, isTablet),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AjouterParentPage(etablissementId: widget.etablissementId),
            ),
          );
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
        hintText: 'Rechercher un parent...',
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
              Text(
                "Nombre de parents chargés",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              DropdownButton<String?>(
                value: selectedClasseId,
                hint: const Text("Filtrer par classe enfant"),
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

  Widget _buildUtilisateurCard(BuildContext context, ParentModele parent, bool isLargeScreen, bool isTablet) {
    double avatarRadius = isLargeScreen ? 25 : (isTablet ? 22 : 18);
    double fontSize = isLargeScreen ? 16 : (isTablet ? 14 : 12);
    double infoFontSize = isLargeScreen ? 14 : (isTablet ? 12 : 10);

    final utilisateur = parent.utilisateur;
    final primaryColor = Colors.green;
    final secondaryColor = Colors.green.shade100;
    final deleteColor = Colors.redAccent;
    final textColor = Colors.black87;
    final subTextColor = Colors.grey[700];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParentDetailCard(parent: parent),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: secondaryColor),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: secondaryColor,
              child: Text(
                "${(utilisateur.nom.isNotEmpty ? utilisateur.nom[0].toUpperCase() : '')}${(utilisateur.prenom.isNotEmpty ? utilisateur.prenom[0].toUpperCase() : '')}",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: avatarRadius * 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${utilisateur.nom} ${utilisateur.prenom}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    utilisateur.email,
                    style: TextStyle(fontSize: infoFontSize, color: subTextColor),
                  ),
                  Text(
                    utilisateur.numeroTelephone,
        style: TextStyle(fontSize: infoFontSize, color: subTextColor),
        ),
        ],
        ),
        ),
        IconButton(
        icon: Icon(Icons.edit, color: primaryColor),
        onPressed: () {
        Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) => ModifierParent(parentId: parent.id, etablissementId: widget.etablissementId),
        ),
        );
        },
        ),
        IconButton(
        icon: Icon(Icons.delete, color: deleteColor),
        onPressed: () => _supprimerUtilisateur(context, parent.id),
        ),
        ],
        ),
        ),
        );
        }
        }



class ParentDetailCard extends StatelessWidget {
  final ParentModele parent;

  const ParentDetailCard({Key? key, required this.parent}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    UtilisateurModele utilisateur = parent.utilisateur;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Parent'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      "${(utilisateur.nom.isNotEmpty ? utilisateur.nom[0].toUpperCase() : '')}${(utilisateur.prenom.isNotEmpty ? utilisateur.prenom[0].toUpperCase() : '')}",
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Nom', utilisateur.nom),
                const Divider(),
                _buildDetailRow('Prénom', utilisateur.prenom),
                const Divider(),
                _buildDetailRow('Email', utilisateur.email),
                const Divider(),
                _buildDetailRow('Téléphone', utilisateur.numeroTelephone),
                const Divider(),
                _buildDetailRow('Adresse', utilisateur.adresse ?? 'Non renseignée'),
                const Divider(),
               // _buildDetailRow('Sexe', utilisateur.sexe ?? 'Non renseigné'),
                const Divider(),
                _buildDetailRow('Nombre d\'enfants', parent.enfants.length.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label :', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
