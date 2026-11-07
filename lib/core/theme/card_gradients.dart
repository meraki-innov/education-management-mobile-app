// lib/core/theme/card_gradients.dart
//
// Gradient colors used on banner-style cards (Classrooms, and later any other
// card that needs a colored header). Change a color here once and every
// screen that uses it updates.

import 'package:flutter/material.dart';

class CardGradients {
  CardGradients._();

  static const purple = [Color(0xFF6D5BFF), Color(0xFF8E80FF)];
  static const indigo = [Color(0xFF5568D8), Color(0xFF7F8FEA)];
  static const green = [Color(0xFF2FA574), Color(0xFF66C49E)];
  static const blue = [Color(0xFF3F8FD8), Color(0xFF7DB4E8)];
  static const orange = [Color(0xFFF1A12F), Color(0xFFF5BC63)];

  // Used in this order, repeating, when a list of cards needs different colors.
  static const banners = <List<Color>>[purple, indigo, green, blue, orange];

  // Pick the banner for the nth card.
  static List<Color> bannerAt(int index) => banners[index % banners.length];
}
