import 'package:flutter/material.dart';
import 'package:vigiconso/screens/contact_screen.dart';
import 'package:vigiconso/screens/about_screen.dart';

/// Menu contextuel minimaliste — uniquement Contact et À propos.
/// La navigation principale (Accueil, Catégories, Favoris, Scanner)
/// est gérée par la NavigationBar dans MainScreen.
class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'contact':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ContactScreen()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (BuildContext context) {
        return const [
          PopupMenuItem<String>(
            value: 'contact',
            child: Row(
              children: [
                Icon(Icons.contact_mail_outlined),
                SizedBox(width: 12),
                Text('Contact'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'about',
            child: Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 12),
                Text('À propos'),
              ],
            ),
          ),
        ];
      },
    );
  }
}
