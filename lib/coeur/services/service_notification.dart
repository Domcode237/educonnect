import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ServiceAuth {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupérer rôle complet depuis l'UID de l'utilisateur
  Future<Map<String, dynamic>?> getRoleByUserId(String uid) async {
    try {
      final userDoc = await _db.collection('utilisateurs').doc(uid).get();
      if (!userDoc.exists || userDoc.data() == null) return null;

      final userData = userDoc.data()!;
      if (!userData.containsKey('roleId') || userData['roleId'] == null) return null;

      final String roleId = userData['roleId'].toString();
      final roleDoc = await _db.collection('roles').doc(roleId).get();
      if (!roleDoc.exists || roleDoc.data() == null) return null;

      return {
        'id': roleDoc.id,
        ...roleDoc.data()!,
      };
    } catch (e) {
      debugPrint('Erreur getRoleByUserId: $e');
      return null;
    }
  }

  /// Connexion avec Google
  Future<Map<String, dynamic>?> connecterAvecGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut(); // Forcer une nouvelle session propre

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw 'Connexion Google annulée';

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userId = userCredential.user?.uid;
      if (userId == null) throw 'Utilisateur Google sans UID';

      final snapshot = await _db.collection('utilisateurs').doc(userId).get();

      if (!snapshot.exists || snapshot.data() == null) {
        final newUser = {
          'nom': googleUser.displayName ?? '',
          'email': googleUser.email,
          'roleId': 'eleve', // Rôle par défaut
        };

        await _db.collection('utilisateurs').doc(userId).set(newUser);

        return {
          'role': {
            'id': 'eleve',
            'nom': 'Élève',
          }
        };
      }

      final userData = snapshot.data()!;
      if (!userData.containsKey('roleId') || userData['roleId'] == null) {
        throw 'Utilisateur sans rôle';
      }

      final roleId = userData['roleId'].toString();
      final roleDoc = await _db.collection('roles').doc(roleId).get();
      if (!roleDoc.exists || roleDoc.data() == null) {
        throw 'Rôle "$roleId" inexistant';
      }

      final roleData = roleDoc.data()!;
      return {
        'role': {
          'id': roleDoc.id,
          ...roleData,
        }
      };
    } catch (e, stack) {
      debugPrint('Erreur lors de la connexion Google : $e');
      debugPrint('Stacktrace : $stack');
      return null;
    }
  }

  /// Connexion avec email et mot de passe
  Future<Map<String, dynamic>?> connecterAvecEmailEtMotDePasse(String email, String motDePasse) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      final uid = userCredential.user?.uid;
      if (uid == null) throw 'Utilisateur sans UID';

      final roleData = await getRoleByUserId(uid);
      if (roleData == null) throw 'Aucun rôle trouvé pour l\'utilisateur';

      return {
        'role': roleData,
      };
    } catch (e, stack) {
      debugPrint('Erreur connexion email/mot de passe : $e');
      debugPrint('Stack : $stack');
      return null;
    }
  }
}
