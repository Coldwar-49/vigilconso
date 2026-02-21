import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vigiconso/screens/barcode_scanner.dart';
import 'package:vigiconso/screens/categories_screen.dart';
import 'package:vigiconso/screens/favorites_screen.dart';
import 'package:vigiconso/screens/rappel_screen.dart';
import 'package:vigiconso/widgets/app_menu.dart';
import 'package:vigiconso/services/subscribe_to_newsletter.dart';
import 'package:vigiconso/services/rappel_service.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSubscribing = false;
  String? _subscriptionMessage;
  bool _isError = false;
  bool _showScrollToTopButton = false;
  List<dynamic> _latestRappels = [];
  bool _isLoadingLatest = true;
  String? _latestError;
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTopButton) {
        setState(() => _showScrollToTopButton = true);
      } else if (_scrollController.offset <= 300 && _showScrollToTopButton) {
        setState(() => _showScrollToTopButton = false);
      }
    });
    _loadLatestRappels();
  }

  Future<void> _loadLatestRappels({bool forceRefresh = false}) async {
    setState(() { _isLoadingLatest = true; _latestError = null; });
    try {
      final results = await RappelService.fetchLatestRappels(limit: 5);
      if (mounted) setState(() { _latestRappels = results; _isLoadingLatest = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoadingLatest = false; _latestError = 'Impossible de charger les alertes.'; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.white),
            tooltip: 'Mes favoris',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
          ),
          const AppMenu(),
        ],
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(mini: true, onPressed: _scrollToTop, backgroundColor: primaryColor, child: const Icon(Icons.arrow_upward))
          : null,
      body: RefreshIndicator(
        onRefresh: () => _loadLatestRappels(forceRefresh: true),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_buildHeader(context), Expanded(child: _buildMainContent(context))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildSectionTitle(String title, Color color) {
    return Row(children: [
      Container(width: 4, height: 22, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.shield, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                const Text('VigilConso', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: const Text('v1.1.0', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Protegez-vous contre les produits rappeles', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 20),
              Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarcodeScannerPage())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text('Scanner un produit', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLatestAlertsSection(context),
          const SizedBox(height: 28),
          _buildCategoriesSection(context),
          const SizedBox(height: 28),
          _buildFeatureGrid(context),
          const SizedBox(height: 28),
          _buildNewsletterCard(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLatestAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildSectionTitle('Dernieres alertes', Colors.red),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Rafraichir'),
            onPressed: () => _loadLatestRappels(forceRefresh: true),
          ),
        ]),
        const SizedBox(height: 12),
        if (_isLoadingLatest)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (_latestError != null)
          Center(child: Text(_latestError!, style: const TextStyle(color: Colors.grey)))
        else if (_latestRappels.isEmpty)
          const Center(child: Text('Aucune alerte disponible.', style: TextStyle(color: Colors.grey)))
        else
          ..._latestRappels.map((r) => _buildLatestRappelCard(r, context)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('Voir tous les rappels'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RappelListScreen(categoryKey: 'all', categoryTitle: 'Tous les rappels'))),
          ),
        ),
      ],
    );
  }
  Widget _buildLatestRappelCard(dynamic rappel, BuildContext context) {
    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand = rappel['marque_produit'] ?? rappel['nom_marque'] ?? '';
    final dateStr = rappel['date_publication'] ?? '';
    String formattedDate = '';
    bool isNew = false;
    if (dateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
        isNew = DateTime.now().difference(parsed).inDays <= 7;
      } catch (_) { formattedDate = dateStr; }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RappelDetailsPage(rappel: rappel))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.warning_amber, color: Colors.red, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (isNew)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                      child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ]),
                if (brand.isNotEmpty) Text(brand, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (formattedDate.isNotEmpty) Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
  Widget _buildCategoriesSection(BuildContext context) {
    final cats = [
      {'icon': Icons.fastfood, 'title': 'Alimentation', 'key': 'alimentation'},
      {'icon': Icons.child_care, 'title': 'Bebe', 'key': 'bebe_enfant'},
      {'icon': Icons.directions_car, 'title': 'Automobile', 'key': 'automobile'},
      {'icon': Icons.devices, 'title': 'High-tech', 'key': 'equipements_communication'},
      {'icon': Icons.home, 'title': 'Maison', 'key': 'maison_habitat'},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Explorer par categories', Theme.of(context).colorScheme.primary),
      const SizedBox(height: 14),
      SizedBox(
        height: 100,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: cats.map((cat) => _buildCategoryItem(context, icon: cat['icon'] as IconData, title: cat['title'] as String, categoryKey: cat['key'] as String)).toList(),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.category),
          label: const Text('Toutes les categories'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
        ),
      ),
    ]);
  }

  Widget _buildCategoryItem(BuildContext context, {required IconData icon, required String title, required String categoryKey}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RappelListScreen(categoryKey: categoryKey, categoryTitle: title))),
        child: Column(children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
  Widget _buildFeatureGrid(BuildContext context) {
    final features = [
      {'icon': Icons.notifications_active, 'title': 'Alertes temps reel', 'description': 'Donnees a jour a chaque connexion.', 'color': Colors.blue},
      {'icon': Icons.qr_code_scanner, 'title': 'Scan produits', 'description': 'Verifiez par scan code-barres.', 'color': Colors.green},
      {'icon': Icons.favorite, 'title': 'Favoris', 'description': 'Sauvegardez les rappels.', 'color': Colors.red},
      {'icon': Icons.search, 'title': 'Recherche', 'description': 'Trouvez par marque ou ref.', 'color': Colors.orange},
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Fonctionnalites', Colors.purple),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 12, mainAxisSpacing: 12),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final f = features[index];
          final color = f['color'] as Color;
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(f['icon'] as IconData, size: 24, color: color),
                ),
                const SizedBox(height: 10),
                Text(f['title'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(f['description'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ]),
            ),
          );
        },
      ),
    ]);
  }
  Widget _buildNewsletterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('Restez informe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            const Text('Recevez les alertes de rappel dans votre boite mail.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Votre adresse email',
                hintText: 'exemple@email.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@') || !value.contains('.')) return 'Adresse email invalide';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _subscriptionMessage != null
                  ? Padding(
                      key: ValueKey<String>(_subscriptionMessage!),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(children: [
                        Icon(_isError ? Icons.error : Icons.check_circle, color: _isError ? Colors.red : Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_subscriptionMessage!, style: TextStyle(color: _isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold))),
                      ]),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubscribing ? null : _subscribeToNewsletter,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isSubscribing
                    ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 10), Text('Envoi en cours...')])
                    : const Text("S'inscrire", style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _subscribeToNewsletter() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    setState(() { _isSubscribing = true; _subscriptionMessage = null; });
    final result = await subscribeToNewsletter(email);
    setState(() {
      _isSubscribing = false;
      _isError = !result['success'];
      _subscriptionMessage = result['message'];
      if (result['success']) _emailController.clear();
    });
  }
}