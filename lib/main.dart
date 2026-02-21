import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/screens/home_screen.dart' as custom;


void main() {
  runApp(const RappelConsoApp());
}

class RappelConsoApp extends StatelessWidget {
  const RappelConsoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VigilConso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const custom.HomeScreen(),
    );
  }
}
class NewsletterService {
  static Future<bool> subscribeToNewsletter(String email) async {
    // Implémentation simulée - dans une application réelle,
    // vous enverriez cette requête à votre backend
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      return true;
    } catch (e) {
      debugPrint('Erreur d\'enregistrement: $e');
      return false;
    }
  }
}