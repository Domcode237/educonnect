import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:educonnect/coeur/services/service_auth.dart';

/// Modèle de rôle utilisateur
class RoleModele {
  final String id;
  final String nom;
  final String description;

  RoleModele({
    required this.id,
    required this.nom,
    required this.description,
  });

  factory RoleModele.fromMap(Map<String, dynamic> data, String documentId) {
    final nom = data['nom'] as String?;
    final description = data['description'] as String?;

    if (nom == null || description == null) {
      throw ArgumentError('Les champs "nom" et "description" sont obligatoires.');
    }

    return RoleModele(
      id: documentId,
      nom: nom,
      description: description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'RoleModele(id: $id, nom: $nom, description: $description)';
  }
}

/// Enumération pour suivre l'état de l'authentification
enum StatutConnexion {
  deconnecte,
  enCours,
  connecte,
  erreur,
}

/// Contrôleur d'authentification
class ControleurAuth extends ChangeNotifier {
  final ServiceAuth _serviceAuth = ServiceAuth();

  User? utilisateurFirebase;
  RoleModele? role;
  StatutConnexion statut = StatutConnexion.deconnecte;
  String? messageErreur;

  /// Connexion de l'utilisateur
  Future<bool> connecter(String email, String motDePasse) async {
    statut = StatutConnexion.enCours;
    messageErreur = null;
    notifyListeners();

    final user = await _serviceAuth.connecter(email, motDePasse);

    if (user != null) {
      utilisateurFirebase = user;

      try {
        // 🔍 Étape 1 : Récupérer le document utilisateur
        final userDoc = await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .get();

        if (!userDoc.exists) {
          throw Exception("Utilisateur introuvable dans Firestore.");
        }

        final data = userDoc.data();
        final roleId = data?['roleId'];

        if (roleId == null) {
          throw Exception("Le champ 'roleId' est manquant.");
        }

        // 📂 Étape 2 : Récupérer le document du rôle
        final roleDoc = await FirebaseFirestore.instance
            .collection('roles')
            .doc(roleId)
            .get();

        if (!roleDoc.exists) {
          throw Exception("Rôle introuvable pour l'id : $roleId");
        }

        final roleData = roleDoc.data();
        final nomRole = roleData?['nom'];
        final description = roleData?['description'] ?? '';

        if (nomRole == null) {
          throw Exception("Le champ 'nom' du rôle est manquant.");
        }

        // 🧠 Étape 3 : Stocker les infos du rôle
        role = RoleModele(
          id: roleId,
          nom: nomRole,
          description: description,
        );

        // ✅ Étape 4 : Mettre l'utilisateur en ligne
        await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .update({'statut': true});

        statut = StatutConnexion.connecte;
        notifyListeners();
        return true;
      } catch (e) {
        messageErreur = e.toString();
      }
    } else {
      messageErreur = 'Échec de la connexion. Vérifie tes identifiants.';
    }

    utilisateurFirebase = null;
    role = null;
    statut = StatutConnexion.erreur;
    notifyListeners();
    return false;
  }

  /// Déconnexion
  Future<void> deconnecter() async {
    if (utilisateurFirebase != null) {
      // ✅ Mettre statut = false (utilisateur hors ligne)
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(utilisateurFirebase!.uid)
          .update({'statut': false});
    }

    await _serviceAuth.deconnecter();
    utilisateurFirebase = null;
    role = null;
    statut = StatutConnexion.deconnecte;
    messageErreur = null;
    notifyListeners();
  }
}
