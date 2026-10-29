import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BasicUserApp());
}

/// Root widget of the application.
class BasicUserApp extends StatelessWidget {
  const BasicUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BasicUserApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
