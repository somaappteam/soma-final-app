import 'package:flutter/material.dart';

class ConjugationDrillScreen extends StatefulWidget {
  const ConjugationDrillScreen({super.key});

  @override
  State<ConjugationDrillScreen> createState() => _ConjugationDrillScreenState();
}

class _ConjugationDrillScreenState extends State<ConjugationDrillScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conjugation Drill'),
      ),
      body: const Center(
        child: Text('Conjugation Drill Screen'),
      ),
    );
  }
}
