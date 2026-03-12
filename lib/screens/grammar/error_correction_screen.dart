import 'package:flutter/material.dart';

class ErrorCorrectionScreen extends StatefulWidget {
  const ErrorCorrectionScreen({super.key});

  @override
  State<ErrorCorrectionScreen> createState() => _ErrorCorrectionScreenState();
}

class _ErrorCorrectionScreenState extends State<ErrorCorrectionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Correction'),
      ),
      body: const Center(
        child: Text('Error Correction Screen'),
      ),
    );
  }
}
