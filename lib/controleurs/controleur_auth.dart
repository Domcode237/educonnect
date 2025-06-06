// controleur_auth.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:educonnect/coeur/services/service_auth.dart';

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
      throw ArgumentError('Les champs "nom" et "description" doivent être non nuls dans les données.');
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

class ControleurAuth extends ChangeNotifier {
  final ServiceAuth _serviceAuth = ServiceAuth();

  User? utilisateurFirebase;
  RoleModele? role;

  Future<bool> connecter(String email, String motDePasse) async {
    final user = await _serviceAuth.connecter(email, motDePasse);
    if (user != null) {
      utilisateurFirebase = user;

      // Récupérer le rôle via le service
      final roleNom = await _serviceAuth.recupererRoleUtilisateur(user.uid);
      if (roleNom != null) {
        role = RoleModele(
          id: user.uid,
          nom: roleNom,
          description: 'Description pour $roleNom',
        );
      } else {
        role = null;
      }

      notifyListeners();
      return true;
    } else {
      utilisateurFirebase = null;
      role = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> deconnecter() async {
    await _serviceAuth.deconnecter();
    utilisateurFirebase = null;
    role = null;
    notifyListeners();
  }
}
