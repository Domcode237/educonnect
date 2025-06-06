import 'package:flutter/material.dart';

class HomeParent extends StatelessWidget {
  const HomeParent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("home parent"),
      ),
      body: Center(
        child: Text('home parent'),
      ),
    );
  }
}