import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:educonnect/vues/commun/forgotPassword.dart';
import 'package:educonnect/coeur/constantes/images.dart';
import 'package:educonnect/controleurs/controleur_auth.dart';
import 'package:educonnect/coeur/services/service_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool isLoading = false;
  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      emailController.text = prefs.getString('email') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _handleLogin() async {
    setState(() => isLoading = true);

    final email = emailController.text.trim();
    final motDePasse = passwordController.text.trim();

    final controleur = Provider.of<ControleurAuth>(context, listen: false);
    final success = await controleur.connecter(email, motDePasse);

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('email', email);
      await prefs.setString('password', motDePasse);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // ✅ Mise à jour du statut à true
        await FirebaseFirestore.instance
            .collection('utilisateurs')
            .doc(user.uid)
            .update({'statut': true});
      }

      // 🎯 Redirection par rôle
      final role = controleur.role;
      if (role != null) {
        final roleNom = role.nom.toLowerCase();

        if (roleNom == 'superadmin') {
          Navigator.pushReplacementNamed(context, "/home_super_admin");
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('utilisateurs')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

          if (userDoc.exists) {
            final etablissementId = userDoc.data()?['etablissementId'] as String?;
            if (etablissementId == null || etablissementId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        "Aucun établissement associé à cet utilisateur.")),
              );
              return;
            }

            if (roleNom == 'administrateur') {
              Navigator.pushReplacementNamed(
                context,
                "/home_admin",
                arguments: {'etablissementId': etablissementId},
              );
            } else if (roleNom == 'enseignant') {
              Navigator.pushReplacementNamed(
                context,
                "/home_enseignant",
                arguments: {'etablissementId': etablissementId},
              );
            } else if (roleNom == 'parent') {
              Navigator.pushReplacementNamed(
                context,
                "/home_Parent",
                arguments: {'etablissementId': etablissementId},
              );
            } else if (roleNom == 'eleve') {
              Navigator.pushReplacementNamed(
                context,
                "/home_eleve",
                arguments: {'etablissementId': etablissementId},
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      "Rôle inconnu. Veuillez contacter l'administrateur."),
                  backgroundColor: Colors.redAccent,
                ),
              );
              Navigator.pushReplacementNamed(context, "/login");
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Utilisateur non trouvé dans la base."),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Rôle inconnu. Veuillez contacter l'administrateur."),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pushReplacementNamed(context, "/login");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Échec de la connexion")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoPath =
        isDark ? ImagesApp.logoAppSombre : ImagesApp.logoAppClaire;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(logoPath, height: 160),
                const SizedBox(height: 4),
                const _LoginTitle(),
                const SizedBox(height: 32),
                Column(
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => obscurePassword = !obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (value) =>
                              setState(() => rememberMe = value ?? false),
                        ),
                        const Text('Se souvenir de moi'),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Forgotpassword(),
                        ),
                      ),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.blue : const Color(0xFF193152),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text(
                            'Se connecter',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                const _LoginSocialSeparator(),
                const SizedBox(height: 20),
                _LoginSocialButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginTitle extends StatelessWidget {
  const _LoginTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Bienvenue !',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connecte-toi pour continuer',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _LoginSocialSeparator extends StatelessWidget {
  const _LoginSocialSeparator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou se connecter avec'),
        ),
        Expanded(child: Divider(thickness: 1)),
      ],
    );
  }
}

class _LoginSocialButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : const Color(0xFF193152);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          icon: FontAwesomeIcons.google,
          color: Colors.red,
          borderColor: borderColor,
          onPressed: () async {
            final utilisateur = await ServiceAuth().connecterAvecGoogle();
            if (utilisateur != null) {
              Navigator.pushReplacementNamed(context, '/accueil');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Échec de connexion avec Google')),
              );
            }
          },
        ),
        const SizedBox(width: 24),
        _buildSocialButton(
          icon: FontAwesomeIcons.facebookF,
          color: Colors.blue,
          borderColor: borderColor,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Connexion Facebook non implémentée')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required Color borderColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2),
        ),
        child: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          radius: 20,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
