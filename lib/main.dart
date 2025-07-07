import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:educonnect/controleurs/controleur_auth.dart';
import 'application.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ Pour intl/fr_FR

// ➕ Import Appwrite
import 'package:appwrite/appwrite.dart';

// ➕ Configuration Appwrite
const String appwriteProjectId = "6853190c0001df11877c";
const String appwriteEndpoint = "https://cloud.appwrite.io/v1";

// ➕ Création des clients Appwrite
final Client appwriteClient = Client()
  ..setEndpoint(appwriteEndpoint) // Endpoint Appwrite
  ..setProject(appwriteProjectId) // ID du projet
  ..setSelfSigned(status: true);     // À false en production

// ➕ Services Appwrite
final Storage appwriteStorage = Storage(appwriteClient);
final Account appwriteAccount = Account(appwriteClient);
final Databases appwriteDatabases = Databases(appwriteClient);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialisation Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Initialisation des formats de date pour le français
  await initializeDateFormatting('fr_FR', null);

  // ✅ Lancement de l’application avec Provider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ControleurAuth(),
      child: const Application(),
    ),
  );
}
