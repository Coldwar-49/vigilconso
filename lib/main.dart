import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/screens/main_screen.dart';
import 'package:vigiconso/services/subscribe_to_newsletter.dart' show NotificationService;

const String _oneSignalAppId = 'eb3fd80e-1a70-468f-ab2e-e1d2eb9592ab';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sur mobile : initialise OneSignal. Sur web : ne fait rien.
  NotificationService.initialize(_oneSignalAppId);

  // Au 1er lancement : demande automatiquement la permission de notifications
  final prefs = await SharedPreferences.getInstance();
  final alreadyRequested = prefs.getBool('notifications_requested') ?? false;
  if (!alreadyRequested) {
    await NotificationService.subscribe();
    await prefs.setBool('notifications_requested', true);
  }

  runApp(const RappelConsoApp());
}

class RappelConsoApp extends StatelessWidget {
  const RappelConsoApp({super.key});

  // Couleur primaire : rouge sécurité, identitaire pour une app d'alertes
  static const Color _brandRed = Color(0xFFCC1421);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VigilConso',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // Thème clair
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandRed,
          brightness: Brightness.light,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          shadowColor: Colors.black26,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),

      // Thème sombre
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandRed,
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          elevation: 8,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),

      home: const MainScreen(),
    );
  }
}

