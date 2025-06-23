import 'package:flutter/foundation.dart';
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
      throw ArgumentError(
        'Les champs "nom" et "description" sont obligatoires.',
      );
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
  String toString() => 'RoleModele(id: $id, nom: $nom)';
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

  /// Connexion
  Future<bool> connecter(String email, String motDePasse) async {
    statut = StatutConnexion.enCours;
    messageErreur = null;
    notifyListeners();

    try {
      final user = await _serviceAuth.connecter(email, motDePasse);

      if (user == null) {
        messageErreur = "Échec de la connexion. Vérifie tes identifiants.";
        statut = StatutConnexion.erreur;
        notifyListeners();
        return false;
      }

      utilisateurFirebase = user;

      // Met à jour le statut à true dans Firestore (similaire à logoutUser)
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .update({'statut': true});

      // Récupère le rôle
      final userDoc = await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("Utilisateur introuvable dans Firestore");
      }

      final data = userDoc.data()!;
      final roleId = data['roleId'];
      if (roleId == null) throw Exception("Le champ 'roleId' est manquant.");

      final roleDoc = await FirebaseFirestore.instance
          .collection('roles')
          .doc(roleId)
          .get();

      if (!roleDoc.exists) throw Exception("Rôle introuvable pour l'id: $roleId");

      final roleData = roleDoc.data()!;
      role = RoleModele(
        id: roleDoc.id,
        nom: roleData['nom'],
        description: roleData['description'] ?? '',
      );

      statut = StatutConnexion.connecte;
      notifyListeners();
      return true;
    } catch (e) {
      messageErreur = e.toString();
      statut = StatutConnexion.erreur;
      utilisateurFirebase = null;
      role = null;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> deconnecter() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .update({'statut': false});
      }

      await _serviceAuth.deconnecter();

      utilisateurFirebase = null;
      role = null;
      statut = StatutConnexion.deconnecte;
      messageErreur = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur de déconnexion dans ControleurAuth : $e');
      messageErreur = "Erreur pendant la déconnexion : $e";
      notifyListeners();
    }
  }
}
