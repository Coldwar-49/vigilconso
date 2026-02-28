import 'package:flutter/material.dart';
import 'package:vigiconso/screens/home_screen.dart' as custom;
import 'package:vigiconso/screens/categories_screen.dart';
import 'package:vigiconso/screens/favorites_screen.dart';
import 'package:vigiconso/screens/barcode_scanner.dart';
import 'package:vigiconso/services/alerts_notifier.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    custom.HomeScreen(),
    CategoriesScreen(),
    FavoritesScreen(),
    BarcodeScannerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: newAlertsNotifier,
        builder: (context, newCount, _) => NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == 0) newAlertsNotifier.value = 0;
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: Badge(
                isLabelVisible: newCount > 0,
                label: Text('$newCount'),
                child: const Icon(Icons.home_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: newCount > 0,
                label: Text('$newCount'),
                child: const Icon(Icons.home),
              ),
              label: 'Accueil',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Catégories',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_outline),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoris',
            ),
            const NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: 'Scanner',
            ),
          ],
        ),
      ),
    );
  }
}
