import 'package:flutter/material.dart';
import 'package:vigiconso/screens/categories_screen.dart';
import 'package:vigiconso/screens/home_screen.dart' as custom;
import 'package:vigiconso/screens/rappel_screen.dart';
import 'package:vigiconso/screens/contact_screen.dart';
import 'package:vigiconso/screens/about_screen.dart';

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
       case 'Accueil':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const custom.HomeScreen()),
        );
        break;
      case 'categories':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CategoriesScreen()),
        );
        break;
      case 'all_recalls':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RappelListScreen(
              categoryKey: 'all',
              categoryTitle: 'Tous les rappels',
            ),
          ),
        );
        break;
      case 'contact':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactScreen()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.menu),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (BuildContext context) {
        return const [
          PopupMenuItem<String>(
            value: 'Accueil',
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.blue),
                SizedBox(width: 10),
                Text('Accueil'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'categories',
            child: Row(
              children: [
                Icon(Icons.category, color: Colors.blue),
                SizedBox(width: 10),
                Text('Catégories'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'all_recalls',
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue),
                SizedBox(width: 10),
                Text('Tous les rappels'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'contact',
            child: Row(
              children: [
                Icon(Icons.contact_mail, color: Colors.blue),
                SizedBox(width: 10),
                Text('Contact'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 10),
                Text('À propos'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
