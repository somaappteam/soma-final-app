import 'package:flutter/material.dart';

class GrammarRulesScreen extends StatefulWidget {
  final String? skillId;

  const GrammarRulesScreen({
    super.key,
    this.skillId,
  });

  @override
  State<GrammarRulesScreen> createState() => _GrammarRulesScreenState();
}

class _GrammarRulesScreenState extends State<GrammarRulesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Rules'),
      ),
      body: Center(
        child: Text('Grammar Rules Screen${widget.skillId != null ? ' - Skill: ${widget.skillId}' : ''}'),
      ),
    );
  }
}
