import 'package:flutter/material.dart';

class SentenceStructureScreen extends StatefulWidget {
  const SentenceStructureScreen({super.key});

  @override
  State<SentenceStructureScreen> createState() => _SentenceStructureScreenState();
}

class _SentenceStructureScreenState extends State<SentenceStructureScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Structure'),
      ),
      body: const Center(
        child: Text('Sentence Structure Screen'),
      ),
    );
  }
}
