import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The sun/moon button in the top bar flips this. MaterialApp watches it,
// so the whole app re-themes instantly.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
