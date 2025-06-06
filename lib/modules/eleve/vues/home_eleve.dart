import 'package:flutter/material.dart';

class HomeEleve extends StatelessWidget {
  const HomeEleve({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("home eleve"),
      ),
      body: Center(
        child: Text('home eleve'),
      ),
    );
  }
}