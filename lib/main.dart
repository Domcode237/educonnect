import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:educonnect/controleurs/controleur_auth.dart';
import 'application.dart';

// ➕ Import Appwrite
import 'package:appwrite/appwrite.dart';

// ➕ Configuration Appwrite
const String APPWRITE_PROJECT_ID = "6853190c0001df11877c";
const String APPWRITE_ENDPOINT = "https://cloud.appwrite.io/v1";

// ➕ Création des clients Appwrite
final Client appwriteClient = Client()
  ..setEndpoint(APPWRITE_ENDPOINT) // Endpoint Appwrite
  ..setProject(APPWRITE_PROJECT_ID) // ID du projet
  ..setSelfSigned(status: true);     // À false en production

// ➕ Services Appwrite
final Storage appwriteStorage = Storage(appwriteClient);
final Account appwriteAccount = Account(appwriteClient);    // Pour gérer l'authentification Appwrite
final Databases appwriteDatabases = Databases(appwriteClient); // Pour gérer les bases de données Appwrite
// Tu pourras ajouter d’autres services ici si besoin (Functions, Realtime, etc.)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ➕ Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lance ton app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ControleurAuth(),
      child: const Application(),
    ),
  );
}
