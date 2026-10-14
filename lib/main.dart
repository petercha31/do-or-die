import 'package:flutter/material.dart';

import 'home_screen.dart';

void main() {
  runApp(const DoOrDieApp());
}

class DoOrDieApp extends StatelessWidget {
  const DoOrDieApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF101218);
    const surface = Color(0xFF1B1E27);
    const red = Color(0xFFE23B3B);

    return MaterialApp(
      title: 'TO DO OR DIE',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: red,
          onPrimary: Colors.white,
          surface: surface,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: Colors.white38),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: red,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF3A2A2A),
            disabledForegroundColor: Colors.white38,
            minimumSize: const Size.fromHeight(52),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return red;
            }
            return Colors.transparent;
          }),
          checkColor: const WidgetStatePropertyAll(Colors.white),
          side: const BorderSide(color: Colors.white54, width: 1.5),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
