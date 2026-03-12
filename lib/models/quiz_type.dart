import 'package:flutter/material.dart';

class QuizType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int questionCount;
  
  QuizType(this.id, this.name, this.description, this.icon, this.color, 
      {this.questionCount = 10});
}
