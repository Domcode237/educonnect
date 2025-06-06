import 'package:flutter/material.dart';
import 'package:educonnect/routes/noms_routes.dart';
import 'package:educonnect/vues/commun/login.dart';
import 'package:educonnect/vues/inscription/inscription.dart';
import 'package:educonnect/vues/commun/forgotPassword.dart';
import 'package:educonnect/modules/superadmin/vues/home_super_admin.dart';
import 'package:educonnect/modules/parent/vues/home_parent.dart';
import 'package:educonnect/modules/enseignant/vues/home_enseignant.dart';
import 'package:educonnect/modules/eleve/vues/home_eleve.dart';
import 'package:educonnect/modules/admin/vues/home_admin.dart';
import 'package:educonnect/modules/superadmin/vues/roles_page.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_role_vue.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_atablissement.dart';
import 'package:educonnect/modules/superadmin/vues/ajout_administrateur_vue.dart';




final Map<String, WidgetBuilder> routes = {
  NomsRoutes.connexion: (context) => const LoginPage(),
  NomsRoutes.inscription: (context) => const Inscription(),
  NomsRoutes.accueil: (context) => const HomeSuperAdmin(),
  NomsRoutes.forgotPasseword: (context) => Forgotpassword(),
  NomsRoutes.homeAdmin: (context) => HomeSuperAdmin(),
  NomsRoutes.homeEnseignant: (context) => HomeEnseignant(),
  NomsRoutes.homeParent: (context) => HomeParent(),
  NomsRoutes.homeEleve: (context) => HomeEleve(),
  NomsRoutes.homeSuperAdmin: (context) => HomeSuperAdmin(),
  NomsRoutes.rolesPage: (context) => RolesPage(),
  NomsRoutes.ajoutRole : (context) => AjoutRoleVue(),
  NomsRoutes.ajoutetablissement : (context) => AjoutEtablissementVue(),
  NomsRoutes.ajoutadministrateur : (context) => AjoutAdministrateurVue(roleAdministrateurId: "admin"),
  
};
