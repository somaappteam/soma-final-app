import 'package:flutter/material.dart';

class AnimationConfig {
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 300);
  static const Duration medium = Duration(milliseconds: 600);
  static const Duration slow = Duration(milliseconds: 800);
  static const Duration page = Duration(milliseconds: 1000);
  
  static const Curve elastic = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutCubic;
  static const Curve bounce = Curves.bounceOut;
  static const Curve decelerate = Curves.decelerate;
}
