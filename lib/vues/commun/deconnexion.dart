import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> logoutUser(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Met à jour le champ statut dans Firestore
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(user.uid)
          .update({'statut': false});
    }

    // Déconnexion Firebase Auth
    await FirebaseAuth.instance.signOut();

    // Redirection vers la page de connexion
    Navigator.of(context).pushReplacementNamed("/connexion");
  } catch (e) {
    debugPrint('Erreur de déconnexion : $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Échec de la déconnexion : $e")),
    );
  }
}
