import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/donnees/modeles/utilisateur_modele.dart';
import 'package:educonnect/donnees/modeles/ParentModele.dart';
import 'package:educonnect/donnees/modeles/EleveModele.dart';
import 'page_message_detail.dart';
import 'package:educonnect/main.dart'; // appwriteClient global

enum TypeUtilisateur { parent, eleve }

class MessagerieEnseignantPage extends StatefulWidget {
  final String utilisateurId; // ID enseignant utilisateur
  final String etablissementId;

  const MessagerieEnseignantPage({
    Key? key,
    required this.utilisateurId,
    required this.etablissementId,
  }) : super(key: key);

  @override
  State<MessagerieEnseignantPage> createState() => _MessagerieEnseignantPageState();
}

class _MessagerieEnseignantPageState extends State<MessagerieEnseignantPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? enseignantDocId;

  // Données à afficher
  List<ParentModele> parents = [];
  Map<String, UtilisateurModele> utilisateursParents = {};
  Map<String, int> nbMessagesNonLusParents = {};

  List<EleveModele> eleves = [];
  Map<String, UtilisateurModele> utilisateursEleves = {};
  Map<String, int> nbMessagesNonLusEleves = {};

  // Classes établissement avec leurs noms
  Map<String, String> classesEtablissement = {};
  String? classeSelectionnee;

  TypeUtilisateur typeSelectionne = TypeUtilisateur.parent;

  bool isLoading = true;
  String? error;

  int _nbMessagesNonLusTotal = 0;

  // Pour la recherche
  String rechercheTexte = '';

  // Enfants groupés par parent
  Map<String, List<Map<String, dynamic>>> _enfantsParParent = {};

  @override
  void initState() {
    super.initState();
    _initialiser();
  }

  Future<void> _initialiser() async {
    setState(() {
      isLoading = true;
      error = null;
      classeSelectionnee = null;
      rechercheTexte = '';
    });

    try {
      await _chargerEnseignantDocId();
      await _chargerClassesEtablissement();
      await _chargerDonnees();
      await _chargerNbMessagesNonLusTotal();
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _chargerEnseignantDocId() async {
    final query = await _firestore
        .collection('enseignants')
        .where('utilisateurId', isEqualTo: widget.utilisateurId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      enseignantDocId = query.docs.first.id;
    } else {
      throw Exception("Aucun document enseignant trouvé pour cet utilisateur.");
    }
  }

  Future<void> _chargerClassesEtablissement() async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .where('etablissementId', isEqualTo: widget.etablissementId)
          .orderBy('nom')
          .get();

      classesEtablissement = {
        for (var doc in snapshot.docs) doc.id: (doc.data()['nom'] ?? 'Classe inconnue')
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _chargerDonnees() async {
    if (enseignantDocId == null) return;

    if (typeSelectionne == TypeUtilisateur.parent) {
      await _chargerParentsAvecEnfants();
    } else {
      await _chargerElevesParClasse();
    }
  }

 Future<void> _chargerParentsAvecEnfants() async {

  // 1. Récupérer tous les documents "parents"
  final parentsSnapshot = await _firestore.collection('parents').get();

  // 2. Extraire tous les utilisateurIds depuis les parents
  final utilisateurIdsParents = parentsSnapshot.docs
      .map((d) => d.data()['utilisateurId'] as String)
      .toSet()
      .toList();

  if (utilisateurIdsParents.isEmpty) {
    parents = [];
    utilisateursParents = {};
    nbMessagesNonLusParents = {};
    _enfantsParParent = {};
    return;
  }

  // 3. Récupérer uniquement les utilisateurs parents de l’établissement
  final utilisateursSnapshot = await _firestore
      .collection('utilisateurs')
      .where(FieldPath.documentId, whereIn: utilisateurIdsParents)
      .where('etablissementId', isEqualTo: widget.etablissementId)
      .get();

  // 4. Construire la map des utilisateurs parents
  utilisateursParents = {
    for (var doc in utilisateursSnapshot.docs)
      doc.id: UtilisateurModele.fromMap(doc.data(), doc.id)
  };

  // 5. Récupérer les parents correspondant à ces utilisateurs
  parents = parentsSnapshot.docs
      .map((doc) => ParentModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
      .where((p) => utilisateursParents.containsKey(p.utilisateurId))
      .toList();

  // 6. Extraire les IDs des documents parents
  final parentIds = parents.map((p) => p.id).toList();

  // 7. Récupérer les liens familles (parentId => eleveId)
  final familleSnapshot = await _firestore
      .collection('famille')
      .where('parentId', whereIn: parentIds)
      .get();

  final eleveIds = familleSnapshot.docs
      .map((doc) => doc.data()['eleveId'] as String)
      .toSet()
      .toList();

  if (eleveIds.isEmpty) {
    _enfantsParParent = {};
    await _chargerNbMessagesNonLusParExpediteur(utilisateursParents.keys.toList(), isParent: true);
    return;
  }

  // 8. Récupérer les documents élèves
  final elevesSnapshot = await _firestore
      .collection('eleves')
      .where(FieldPath.documentId, whereIn: eleveIds)
      .get();

  final elevesMap = {
    for (var doc in elevesSnapshot.docs)
      doc.id: EleveModele.fromMap(doc.data(), doc.id)
  };

  // 9. Extraire les utilisateurIds des élèves
  final utilisateurIdsEleves = elevesMap.values
      .map((e) => e.utilisateurId)
      .toSet()
      .toList();

  if (utilisateurIdsEleves.isEmpty) {
    _enfantsParParent = {};
    await _chargerNbMessagesNonLusParExpediteur(utilisateursParents.keys.toList(), isParent: true);
    return;
  }

  // 10. Récupérer les utilisateurs élèves de l’établissement
  final utilisateursElevesSnapshot = await _firestore
      .collection('utilisateurs')
      .where(FieldPath.documentId, whereIn: utilisateurIdsEleves)
      .where('etablissementId', isEqualTo: widget.etablissementId)
      .get();

  final utilisateursElevesMap = {
    for (var doc in utilisateursElevesSnapshot.docs)
      doc.id: UtilisateurModele.fromMap(doc.data(), doc.id)
  };

  // 11. Construire la map _enfantsParParent
  Map<String, List<Map<String, dynamic>>> enfantsParParent = {};
  for (var docFamille in familleSnapshot.docs) {
    final parentId = docFamille.data()['parentId'] as String;
    final eleveId = docFamille.data()['eleveId'] as String;

    final eleve = elevesMap[eleveId];
    if (eleve == null) continue;

    final utilisateurEleve = utilisateursElevesMap[eleve.utilisateurId];
    if (utilisateurEleve == null) continue;

    final classeNom = classesEtablissement[eleve.classeId] ?? 'Classe inconnue';

    enfantsParParent.putIfAbsent(parentId, () => []);
    enfantsParParent[parentId]!.add({
      'nomComplet': '${utilisateurEleve.prenom} ${utilisateurEleve.nom}',
      'classeNom': classeNom,
    });
  }

  // 12. Mise à jour de l'état
  setState(() {
    _enfantsParParent = enfantsParParent;
  });


  // 13. Charger le nombre de messages non lus
  await _chargerNbMessagesNonLusParExpediteur(utilisateursParents.keys.toList(), isParent: true);
}






  Future<void> _chargerElevesParClasse() async {
  try {

    Query query = _firestore.collection('eleves');

    if (classeSelectionnee != null) {
      query = query.where('classeId', isEqualTo: classeSelectionnee);
    }

    final elevesSnapshot = await query.get();

    final tousLesEleves = elevesSnapshot.docs
        .map((doc) => EleveModele.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final utilisateurIdsEleves = tousLesEleves.map((e) => e.utilisateurId).toSet().toList();

    if (utilisateurIdsEleves.isEmpty) {
      setState(() {
        eleves = [];
        utilisateursEleves = {};
        nbMessagesNonLusEleves = {};
      });
      return;
    }

    List<UtilisateurModele> utilisateursTrouves = [];
    const batchSize = 10;

    for (int i = 0; i < utilisateurIdsEleves.length; i += batchSize) {
      final batchIds = utilisateurIdsEleves.sublist(
        i,
        i + batchSize > utilisateurIdsEleves.length ? utilisateurIdsEleves.length : i + batchSize,
      );

      final utilisateursSnapshot = await _firestore
          .collection('utilisateurs')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      final filteredUtilisateurs = utilisateursSnapshot.docs
          .where((doc) => doc.data()['etablissementId'] == widget.etablissementId)
          .map((doc) => UtilisateurModele.fromMap(doc.data(), doc.id))
          .toList();


      utilisateursTrouves.addAll(filteredUtilisateurs);
    }


    final utilisateursMap = {
      for (var utilisateur in utilisateursTrouves) utilisateur.id: utilisateur
    };

    final elevesFiltres = tousLesEleves
        .where((e) => utilisateursMap.containsKey(e.utilisateurId))
        .toList();


    setState(() {
      eleves = elevesFiltres;
      utilisateursEleves = utilisateursMap;
    });

    await _chargerNbMessagesNonLusParExpediteur(utilisateursMap.keys.toList(), isParent: false);
  } catch (e) {
    setState(() {
      eleves = [];
      utilisateursEleves = {};
      nbMessagesNonLusEleves = {};
    });
  }
}






  Future<void> _chargerNbMessagesNonLusParExpediteur(List<String> expediteurIds, {required bool isParent}) async {
  if (enseignantDocId == null || expediteurIds.isEmpty) return;

  Map<String, int> nbNonLusMap = {};
  const batchSize = 10;

  for (int i = 0; i < expediteurIds.length; i += batchSize) {
    final batchIds = expediteurIds.sublist(
      i,
      i + batchSize > expediteurIds.length ? expediteurIds.length : i + batchSize,
    );

    // Firestore ne supporte pas whereIn sur un champ tableau, donc on récupère messages non lus 
    // pour enseignant et on filtre localement par expediteurId dans participants.
    final querySnapshot = await _firestore
        .collection('messages')
        .where('recepteurId', isEqualTo: enseignantDocId)
        .where('lu', isEqualTo: false)
        // .where('participants', arrayContainsAny: batchIds)  <-- Si supporté dans ta version, sinon retire et filtre localement
        .get();

    for (var expediteurId in batchIds) {
      // On compte les messages non lus dont l'expéditeur est dans participants (par émetteurId ici)
      // ou dans participants, selon ta logique d’expéditeur
      final count = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final List<dynamic> participants = data['participants'] ?? [];
        final emetteurId = data['emetteurId'] ?? '';
        return !data['lu'] && participants.contains(expediteurId) && emetteurId == expediteurId;
      }).length;

      nbNonLusMap[expediteurId] = (nbNonLusMap[expediteurId] ?? 0) + count;
    }
  }

  setState(() {
    if (isParent) {
      nbMessagesNonLusParents = nbNonLusMap;
    } else {
      nbMessagesNonLusEleves = nbNonLusMap;
    }
  });
}


  Future<void> _chargerNbMessagesNonLusTotal() async {
    if (enseignantDocId == null) return;

    final querySnapshot = await _firestore
        .collection('notifications')
        .where('recepteurId', isEqualTo: enseignantDocId)
        .where('lu', isEqualTo: false)
        .where('type', isEqualTo: 'message')
        .get();

    setState(() {
      _nbMessagesNonLusTotal = querySnapshot.size;
    });
  }

  String? _getAppwriteImageUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) return null;
    const bucketId = '6854df330032c7be516c';
    return '${appwriteClient.endPoint}/storage/buckets/$bucketId/files/$fileId/view?project=${appwriteClient.config['project']}';
  }

  // Filtrer la liste selon la recherche
  bool _filtrerParent(ParentModele parent, UtilisateurModele utilisateur) {
    final texteRecherche = rechercheTexte.toLowerCase();
    final nomComplet = '${utilisateur.prenom} ${utilisateur.nom}'.toLowerCase();
    if (nomComplet.contains(texteRecherche)) return true;

    // Chercher aussi dans les enfants
    final enfants = _enfantsParParent[parent.id] ?? [];
    for (var enfant in enfants) {
      final nomEnfant = (enfant['nomComplet'] as String).toLowerCase();
      final classeEnfant = (enfant['classeNom'] as String).toLowerCase();
      if (nomEnfant.contains(texteRecherche) || classeEnfant.contains(texteRecherche)) return true;
    }
    return false;
  }

  bool _filtrerEleve(EleveModele eleve, UtilisateurModele utilisateur) {
    final texteRecherche = rechercheTexte.toLowerCase();
    final nomComplet = '${utilisateur.prenom} ${utilisateur.nom}'.toLowerCase();
    final classeNom = classesEtablissement[eleve.classeId]?.toLowerCase() ?? '';
    return nomComplet.contains(texteRecherche) || classeNom.contains(texteRecherche);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur : $error'))
              : Column(
                  children: [
                    // Barre de recherche
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Rechercher par nom, enfant, classe...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            rechercheTexte = val.trim();
                          });
                        },
                      ),
                    ),

                    // Filtres sous forme de boutons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: ToggleButtons(
                              isSelected: [
                                typeSelectionne == TypeUtilisateur.parent,
                                typeSelectionne == TypeUtilisateur.eleve
                              ],
                              onPressed: (index) async {
                                if (index == 0) {
                                  if (typeSelectionne != TypeUtilisateur.parent) {
                                    setState(() {
                                      typeSelectionne = TypeUtilisateur.parent;
                                      classeSelectionnee = null;
                                      rechercheTexte = '';
                                      isLoading = true;
                                      error = null;
                                    });
                                    await _chargerDonnees();
                                    await _chargerNbMessagesNonLusTotal();
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                } else {
                                  if (typeSelectionne != TypeUtilisateur.eleve) {
                                    setState(() {
                                      typeSelectionne = TypeUtilisateur.eleve;
                                      classeSelectionnee = null;
                                      rechercheTexte = '';
                                      isLoading = true;
                                      error = null;
                                    });
                                    await _chargerDonnees();
                                    await _chargerNbMessagesNonLusTotal();
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints(
                                minWidth: 60,  // largeur minimale par bouton
                                minHeight: 30, // hauteur minimale
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('Parents'),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('Élèves'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Boutons filtre classes (uniquement si élèves)
                          if (typeSelectionne == TypeUtilisateur.eleve)
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    ChoiceChip(
                                      label: const Text('Toutes classes'),
                                      selected: classeSelectionnee == null,
                                      onSelected: (selected) async {
                                        if (selected) {
                                          setState(() {
                                            classeSelectionnee = null;
                                            isLoading = true;
                                            error = null;
                                            rechercheTexte = '';
                                          });
                                          await _chargerDonnees();
                                          await _chargerNbMessagesNonLusTotal();
                                          setState(() {
                                            isLoading = false;
                                          });
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    ...classesEtablissement.entries.map((e) {
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: ChoiceChip(
                                          label: Text(e.value),
                                          selected: classeSelectionnee == e.key,
                                          onSelected: (selected) async {
                                            if (selected) {
                                              setState(() {
                                                classeSelectionnee = e.key;
                                                isLoading = true;
                                                error = null;
                                                rechercheTexte = '';
                                              });
                                              await _chargerDonnees();
                                              await _chargerNbMessagesNonLusTotal();
                                              setState(() {
                                                isLoading = false;
                                              });
                                            }
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          setState(() {
                            isLoading = true;
                            error = null;
                          });
                          await _chargerDonnees();
                          await _chargerNbMessagesNonLusTotal();
                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: _buildListeUtilisateurs(),
                      ),
                    ),
                  ],
                ),
      
    );
  }

  Widget _buildListeUtilisateurs() {
    if (typeSelectionne == TypeUtilisateur.parent) {
      final filteredParents = parents.where((parent) {
        final utilisateur = utilisateursParents[parent.utilisateurId];
        if (utilisateur == null) return false;
        return _filtrerParent(parent, utilisateur);
      }).toList();

      if (filteredParents.isEmpty) {
        return const Center(child: Text("Aucun parent trouvé."));
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: filteredParents.length,
        separatorBuilder: (_, __) => const Divider(height: 10),
        itemBuilder: (context, index) {
          final parent = filteredParents[index];
          final utilisateur = utilisateursParents[parent.utilisateurId]!;
          final photoUrl = _getAppwriteImageUrl(utilisateur.photo);
          final statutColor = utilisateur.statut ? Colors.green : Colors.grey;
          final nbNonLus = nbMessagesNonLusParents[parent.utilisateurId] ?? 0;

          final enfants = _enfantsParParent[parent.id] ?? [];

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PageMessageDetail(
                    enseignantId: enseignantDocId!,
                    parentId: parent.utilisateurId,
                    parentNom: '${utilisateur.prenom} ${utilisateur.nom}',
                    parentPhotoFileId: utilisateur.photo,
                  ),
                ),
              );
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 28, color: Colors.blueAccent)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statutColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              '${utilisateur.prenom} ${utilisateur.nom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: enfants.isEmpty
                  ? [const Text('Aucun enfant associé')]
                  : enfants.map((enfant) {
                      return Text('${enfant['nomComplet']} - ${enfant['classeNom']}');
                    }).toList(),
            ),
            trailing: nbNonLus > 0
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$nbNonLus',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  )
                : const Icon(Icons.chat_bubble_outline),
          );
        },
      );
    } else {
      // Élèves filtrés par recherche
      final filteredEleves = eleves.where((eleve) {
        final utilisateur = utilisateursEleves[eleve.utilisateurId];
        if (utilisateur == null) return false;
        return _filtrerEleve(eleve, utilisateur);
      }).toList();

      if (filteredEleves.isEmpty) {
        return const Center(child: Text('Aucun élève trouvé.'));
      }


      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        itemCount: filteredEleves.length,
        separatorBuilder: (_, __) => const Divider(height: 10),
        itemBuilder: (context, index) {
          final eleve = filteredEleves[index];
          final utilisateur = utilisateursEleves[eleve.utilisateurId]!;
          final photoUrl = _getAppwriteImageUrl(utilisateur.photo);
          final statutColor = utilisateur.statut ? Colors.green : Colors.grey;
          final nbNonLus = nbMessagesNonLusEleves[eleve.utilisateurId] ?? 0;

          final classeNom = classesEtablissement[eleve.classeId] ?? 'Classe inconnue';

          return ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PageMessageDetail(
                    enseignantId: enseignantDocId!,
                    eleveId: eleve.utilisateurId,
                    eleveNom: '${utilisateur.prenom} ${utilisateur.nom}',
                    elevePhotoFileId: utilisateur.photo,
                  ),
                ),
              );
            },
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 28, color: Colors.blueAccent)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statutColor,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              '${utilisateur.prenom} ${utilisateur.nom}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Classe : $classeNom'),
            trailing: nbNonLus > 0
                ? CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$nbNonLus',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  )
                : const Icon(Icons.chat_bubble_outline),
          );
        },
      );
    }
  }
}
