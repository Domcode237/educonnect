import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'application.dart';
import 'package:provider/provider.dart';
import 'package:educonnect/controleurs/controleur_auth.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Important pour les appels async avant runApp

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
      ChangeNotifierProvider(
        create: (_) => ControleurAuth(),
        child: const Application(),
      ),
    );
}
