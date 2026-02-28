import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vigiconso/screens/main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _ctrl = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.shield_outlined,
      color: Color(0xFFCC1421),
      title: 'Bienvenue sur VigilConso',
      description: 'Restez informé en temps réel des rappels de produits publiés par les autorités françaises. Votre sécurité est notre priorité.',
    ),
    _OnboardingPage(
      icon: Icons.qr_code_scanner,
      color: Color(0xFF1565C0),
      title: 'Scannez vos produits',
      description: 'Utilisez le scanner de code-barres pour vérifier instantanément si un produit que vous possédez fait l\'objet d\'un rappel.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      color: Color(0xFF2E7D32),
      title: 'Alertes instantanées',
      description: 'Activez les notifications pour être alerté dès qu\'un nouveau rappel est publié — sans avoir à ouvrir l\'application.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_shown', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          // Bouton passer
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _finish,
              child: Text('Passer', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          ),
          // Pages
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _buildPage(_pages[i]),
            ),
          ),
          // Indicateurs de page
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == i ? cs.primary : cs.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
          const SizedBox(height: 32),
          // Bouton suivant / commencer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLast
                    ? _finish
                    : () => _ctrl.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(isLast ? 'Commencer' : 'Suivant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            color: page.color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(page.icon, size: 60, color: page.color),
        ),
        const SizedBox(height: 40),
        Text(
          page.title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          page.description,
          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _OnboardingPage({required this.icon, required this.color, required this.title, required this.description});
}
