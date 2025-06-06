// service_auth.dart
import 'package:firebase_auth/firebase_auth.dart';

class ServiceAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Connexion avec email et mot de passe
  Future<User?> connecter(String email, String motDePasse) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(email: email, password: motDePasse);
      return result.user;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  // Connexion avec Google (exemple)
  Future<User?> connecterAvecGoogle() async {
    // Implémentation Google Sign-In (à compléter selon votre projet)
    // Pour l’exemple, on retourne null
    return null;
  }

  // Récupérer le rôle de l’utilisateur (simulateur / mock)
  Future<String?> recupererRoleUtilisateur(String uid) async {
    // Exemple: faire appel à Firestore ou autre pour récupérer le rôle
    // Ici un mock pour l’exemple:
    await Future.delayed(const Duration(milliseconds: 500));
    // Exemple de rôle : 'administrateur', 'enseignant', 'parent', 'eleve', 'super_admin'
    // A remplacer par une vraie lecture dans la base
    if (uid.isNotEmpty) return 'administrateur';
    return null;
  }

  Future<void> deconnecter() async {
    await _auth.signOut();
  }
}
