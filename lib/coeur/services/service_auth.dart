import 'package:firebase_auth/firebase_auth.dart';

class ServiceAuth {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Connexion avec email et mot de passe
  Future<User?> connecter(String email, String motDePasse) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      return result.user;
    } catch (e) {
      print('Erreur connexion: $e');
      return null;
    }
  }

  // Connexion avec Google (à implémenter si besoin)
  Future<User?> connecterAvecGoogle() async {
    // Implémenter selon votre projet avec GoogleSignIn
    return null;
  }

  // Récupérer le rôle de l'utilisateur depuis Firestore ou simuler
  Future<String?> recupererRoleUtilisateur(String uid) async {
    // Simuler une requête à une base de données
    await Future.delayed(const Duration(milliseconds: 500));
    if (uid.isNotEmpty) return 'administrateur'; // Simulé
    return null;
  }

  Future<void> deconnecter() async {
    await _auth.signOut();
  }
}
