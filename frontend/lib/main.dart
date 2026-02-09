import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'styles/app_theme.dart';

void main() {
  runApp(const FinShieldApp());
}

class FinShieldApp extends StatelessWidget {
  const FinShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
