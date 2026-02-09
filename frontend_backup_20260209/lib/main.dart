import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/ingestion_provider.dart';
import 'core/providers/navigation_provider.dart';
import 'features/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinShieldApp());
}

class FinShieldApp extends StatelessWidget {
  const FinShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => IngestionProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: MaterialApp(
        title: 'Finsight: Autonomous Auditor',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0a0e17),
          primaryColor: const Color(0xFF00f2ea),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
