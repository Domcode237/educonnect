import 'package:flutter/material.dart';
import 'package:educonnect/vues/commun/carousel.dart';
import 'package:educonnect/routes/noms_routes.dart';
import 'package:educonnect/vues/commun/login.dart';
import 'package:educonnect/vues/inscription/inscription.dart';
import 'package:educonnect/vues/commun/forgotPassword.dart';
import 'package:educonnect/modules/superadmin/vues/home_super_admin.dart';
import 'package:educonnect/modules/parent/vues/home_parent.dart';
import 'package:educonnect/modules/enseignant/vues/home_enseignant.dart';
import 'package:educonnect/modules/eleve/vues/home_eleve.dart';
import 'package:educonnect/modules/superadmin/vues/roles_page.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_role_vue.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_atablissement.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_administrateur_vue.dart';
import 'package:educonnect/modules/admin/vues/ajouter_matiere.dart';
import 'package:educonnect/modules/admin/vues/ajouter_classe.dart';
import 'package:educonnect/modules/admin/vues/calsse_detail.dart';
import 'package:educonnect/modules/admin/vues/home_admin.dart';
import 'package:educonnect/modules/admin/vues/ajout_eleve.dart';
import 'package:educonnect/modules/admin/vues/ajouter_eleve.dart';
import 'package:educonnect/modules/admin/vues/ajouter_parent.dart';
import 'package:educonnect/modules/admin/vues/ajouter_enseignant.dart';
import 'package:educonnect/modules/enseignant/vues/devoir_page.dart';
  import 'package:firebase_auth/firebase_auth.dart';




final Map<String, WidgetBuilder> routes = {
  NomsRoutes.carousel: (context) =>  Carousel(),
  NomsRoutes.connexion: (context) => const LoginPage(),
  NomsRoutes.inscription: (context) => const Inscription(),
  NomsRoutes.accueil: (context) => const HomeSuperAdmin(),
  NomsRoutes.forgotPasseword: (context) => Forgotpassword(),

  NomsRoutes.homeAdmin: (context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        body: Center(child: Text("Aucun identifiant d'établissement fourni")),
      );
    }
    final args = route.settings.arguments as Map<String, dynamic>;
    final etablissementId = args['etablissementId'] as String;

    // Récupérer l'utilisateur connecté
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final utilisateurId = user.uid;

    return HomeAdmin(monIdEtablissement: etablissementId, utilisateurId: utilisateurId);
  },




  NomsRoutes.homeEnseignant: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final etablissementId = args['etablissementId'] as String;
    final utilisateurId = args['utilisateurId'] as String; // Ajouté ici
    return HomeEnseignant(
      etablissementId: etablissementId,
      utilisateurId: utilisateurId,
    );
  },
  
  NomsRoutes.homeParent: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final etablissementId = args['etablissementId'] as String;
    final utilisateurId = args['utilisateurId'] as String; // Ajouté ici
    return HomeParent(
      etablissementId: etablissementId,
      utilisateurId: utilisateurId,
    );
  },
  

  NomsRoutes.homeEleve: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final etablissementId = args['etablissementId'] as String;
    final utilisateurId = args['utilisateurId'] as String; // Ajouté ici
    return HomeEleve(
      etablissementId: etablissementId,
      utilisateurId: utilisateurId,
    );
  },
  NomsRoutes.homeSuperAdmin: (context) => HomeSuperAdmin(),
  NomsRoutes.rolesPage: (context) => RolesPage(),
  NomsRoutes.ajoutRole : (context) => AjoutRoleVue(),
  NomsRoutes.ajoutetablissement : (context) => AjoutEtablissementVue(),
  NomsRoutes.ajoutadministrateur : (context) => const AjoutAdministrateurVue(),
  NomsRoutes.ajoutenseignant: (context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      // Gérer le cas où il n'y a pas d'arguments, par ex. retourner une page d'erreur ou une page par défaut
      return Scaffold(
        body: Center(child: Text("Aucun identifiant d'établissement fourni")),
      );
    }
    final args = route.settings.arguments as Map<String, dynamic>;
    final etablissementId = args['etablissementId'] as String;
    return AjoutEnseignantVue(etablissementId: etablissementId);
  },


  NomsRoutes.ajoutereleve: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final etablissementId = args != null ? args['etablissementId'] as String : null;

    if (etablissementId == null) {
      // Tu peux afficher une page d'erreur ou retourner une page vide
      return Scaffold(
        body: Center(child: Text('Établissement non spécifié')),
      );
    }

    return AjoutEleveVue(etablissementId: etablissementId);
  },

  //route pour ajouter un parent
  NomsRoutes.ajouterparent: (context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        body: Center(child: Text("Aucun identifiant d'établissement fourni")),
      );
    }
    final idEtab = route.settings.arguments as String;
    return AjoutParentVue(etablissementId: idEtab);
  },

  //route pour ajouter une matiere
  NomsRoutes.ajoutmatiere: (context) {
  final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        body: Center(child: Text("Aucun identifiant d'établissement fourni")),
      );
    }
    final idEtab = route.settings.arguments as String;
    return AjoutMatiereVue(etablissementId: idEtab);
  },

  NomsRoutes.ajoutclasse: (context) {
    final route = ModalRoute.of(context);
    if (route == null || route.settings.arguments == null) {
      return Scaffold(
        body: Center(child: Text("Aucun identifiant d'établissement fourni")),
      );
    }
    final idEtab = route.settings.arguments as String;
    return AjouterClassePage(etablissementId: idEtab);
  },
  NomsRoutes.classedetail : (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = args['id'] as String;
    return ClasseDetailPage(classeId: id);
  },

  NomsRoutes.ajouteleve: (context) {
  final route = ModalRoute.of(context);
  if (route == null || route.settings.arguments == null) {
    return const Scaffold(
      body: Center(child: Text("Aucun identifiant de classe fourni")),
    );
  }

  final args = route.settings.arguments as Map<String, dynamic>;

  // Vérifions qu'on a bien les deux identifiants
  final classeId = args['classeId'] as String?;
  final etablissementId = args['etablissementId'] as String?;

  if (classeId == null || etablissementId == null) {
    return const Scaffold(
      body: Center(child: Text("Identifiants manquants")),
    );
  }

  return AjouterElevesClassePage(
    classeId: classeId,

  );
},


};
