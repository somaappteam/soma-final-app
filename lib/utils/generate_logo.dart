import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Simple logo generator for Soma
// Run with: dart run lib/utils/generate_logo.dart

void main() async {
  // Generate main logo (1024x1024)
  await generateLogo(
    'assets/icons/soma_logo.png',
    size: 1024,
    backgroundColor: const Color(0xFF6B4EFF),
    foregroundColor: Colors.white,
  );
  
  // Generate foreground (transparent background, white icon)
  await generateLogo(
    'assets/icons/soma_logo_foreground.png',
    size: 1024,
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
  );
  
  print('✅ Logo files generated successfully!');
  print('📁 Files saved to assets/icons/');
  print('🎨 Run: flutter pub run flutter_launcher_icons:main');
}

Future<void> generateLogo(
  String path, {
  required int size,
  required Color backgroundColor,
  required Color foregroundColor,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Draw background
  if (backgroundColor != Colors.transparent) {
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      bgPaint,
    );
  }
  
  // Draw circle background
  final center = Offset(size / 2, size / 2);
  final radius = size * 0.4;
  
  final circlePaint = Paint()
    ..color = foregroundColor.withValues(alpha: backgroundColor == Colors.transparent ? 1.0 : 0.2)
    ..style = PaintingStyle.fill;
  
  canvas.drawCircle(center, radius, circlePaint);
  
  // Draw "S" letter
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'S',
      style: TextStyle(
        color: foregroundColor,
        fontSize: size * 0.5,
        fontWeight: FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      (size - textPainter.height) / 2,
    ),
  );
  
  // Convert to image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  
  if (byteData != null) {
    final buffer = byteData.buffer.asUint8List();
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(buffer);
    print('✓ Generated: $path');
  }
}

