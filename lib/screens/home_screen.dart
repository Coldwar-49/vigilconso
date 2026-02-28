import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:vigiconso/screens/barcode_scanner.dart';
import 'package:vigiconso/screens/categories_screen.dart';
import 'package:vigiconso/screens/rappel_screen.dart';
import 'package:vigiconso/widgets/app_menu.dart';
import 'package:vigiconso/services/subscribe_to_newsletter.dart' show NotificationService;
import 'package:vigiconso/services/rappel_service.dart';
import 'package:vigiconso/screens/rappel_details_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;
  List<dynamic> _latestRappels = [];
  bool _isLoadingLatest = true;
  String? _latestError;
  bool _notificationsEnabled = false;
  bool _isTogglingNotification = false;
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
    _notificationsEnabled = NotificationService.isSubscribed();
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
        actions: const [AppMenu()],
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(mini: true, onPressed: _scrollToTop, backgroundColor: primaryColor, child: const Icon(Icons.arrow_upward))
          : null,
      body: RefreshIndicator(
        onRefresh: () => _loadLatestRappels(forceRefresh: true),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildMainContent(context),
            ],
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
        if (_latestError != null)
          Center(child: Text(_latestError!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
        else if (!_isLoadingLatest && _latestRappels.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucune alerte disponible.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              // Chaque carte occupe ~58% de l'écran → on voit qu'il y en a d'autres
              final cardWidth = constraints.maxWidth * 0.58;
              final imageHeight = cardWidth / 1.1;
              final cardHeight = imageHeight + 118;
              final items = _isLoadingLatest
                  ? List.generate(5, (_) => _AlertCardShimmer(width: cardWidth, height: cardHeight))
                  : List.generate(_latestRappels.length, (i) => _buildLatestRappelCard(_latestRappels[i], context, cardWidth: cardWidth));
              return SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => SizedBox(width: cardWidth, child: items[i]),
                ),
              );
            },
          ),
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
  /// Extrait la première URL d'image valide depuis le champ liens_vers_les_images
  String? _extractFirstImageUrl(dynamic imagesData) {
    if (imagesData is String && imagesData.isNotEmpty) {
      final parts = imagesData.split(RegExp(r'[,;\s]+'));
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('http')) return trimmed;
      }
    } else if (imagesData is List) {
      for (final item in imagesData) {
        if (item is String && item.startsWith('http')) return item;
      }
    }
    return null;
  }

  /// Retourne l'URL proxiée via wsrv.nl sur Web pour contourner le CORS
  String _proxiedUrl(String url) {
    if (!kIsWeb) return url;
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }

  /// Placeholder élégant : icône de catégorie sur fond dégradé
  Widget _categoryPlaceholder(String? categorie, ColorScheme cs) {
    final cat = (categorie ?? '').toLowerCase();
    IconData icon;
    if (cat.contains('vêtement') || cat.contains('mode') || cat.contains('habillement') || cat.contains('epi')) {
      icon = Icons.checkroom_outlined;
    } else if (cat.contains('aliment') || cat.contains('denrée') || cat.contains('boisson') || cat.contains('épicerie') || cat.contains('viande') || cat.contains('poisson')) {
      icon = Icons.lunch_dining_outlined;
    } else if (cat.contains('automobile') || cat.contains('véhicule') || cat.contains('transport') || cat.contains('moto')) {
      icon = Icons.directions_car_outlined;
    } else if (cat.contains('électrique') || cat.contains('électronique') || cat.contains('appareil') || cat.contains('outil')) {
      icon = Icons.electrical_services_outlined;
    } else if (cat.contains('jouet') || cat.contains('enfant') || cat.contains('bébé') || cat.contains('puéricult')) {
      icon = Icons.toys_outlined;
    } else if (cat.contains('cosmétique') || cat.contains('hygiène') || cat.contains('beauté') || cat.contains('soin')) {
      icon = Icons.face_retouching_natural_outlined;
    } else if (cat.contains('médicament') || cat.contains('santé') || cat.contains('pharma')) {
      icon = Icons.medication_outlined;
    } else if (cat.contains('jardin') || cat.contains('bricolage')) {
      icon = Icons.handyman_outlined;
    } else if (cat.contains('animal') || cat.contains('animaux')) {
      icon = Icons.pets_outlined;
    } else {
      icon = Icons.inventory_2_outlined;
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primaryContainer, cs.secondaryContainer],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 28, color: cs.primary.withOpacity(0.75)),
      ),
    );
  }

  Widget _buildLatestRappelCard(dynamic rappel, BuildContext context, {double? cardWidth}) {
    final title = rappel['libelle'] ?? rappel['libelle_produit'] ?? 'Produit sans nom';
    final brand = rappel['marque_produit'] ?? rappel['nom_marque'] ?? '';
    final dateStr = rappel['date_publication'] ?? '';
    final categorie = rappel['categorie_de_produit'] as String?;
    final cs = Theme.of(context).colorScheme;
    String formattedDate = '';
    bool isNew = false;
    if (dateStr.isNotEmpty) {
      try {
        final parsed = DateTime.parse(dateStr);
        formattedDate = DateFormat('dd/MM/yyyy').format(parsed);
        isNew = DateTime.now().difference(parsed).inDays <= 7;
      } catch (_) { formattedDate = dateStr; }
    }
    final rawImageUrl = _extractFirstImageUrl(rappel['liens_vers_les_images']);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RappelDetailsPage(rappel: rappel))),
        child: Column(children: [
          // Image responsive (s'adapte à la largeur de la carte)
          Stack(children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: rawImageUrl != null
                  ? Image.network(
                      _proxiedUrl(rawImageUrl),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: cs.primaryContainer,
                          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))),
                        );
                      },
                      errorBuilder: (_, __, ___) => _categoryPlaceholder(categorie, cs),
                    )
                  : _categoryPlaceholder(categorie, cs),
            ),
            if (isNew)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(8)),
                  child: Text('NOUVEAU', style: TextStyle(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          // Description centrée
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.35),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (brand.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      brand,
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(formattedDate, style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ]),
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
    Widget featureCard(Map<String, dynamic> f) {
      final color = f['color'] as Color;
      return Expanded(
        child: Card(
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
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle('Fonctionnalites', Colors.purple),
      const SizedBox(height: 14),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          featureCard(features[0]),
          const SizedBox(width: 12),
          featureCard(features[1]),
        ]),
      ),
      const SizedBox(height: 12),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          featureCard(features[2]),
          const SizedBox(width: 12),
          featureCard(features[3]),
        ]),
      ),
    ]);
  }
  Widget _buildNewsletterCard() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.notifications_active_outlined, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Alertes instantanees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Text(
            _notificationsEnabled
                ? 'Vous recevrez une notification des qu\'un nouveau rappel est publie.'
                : 'Activez les notifications pour etre alerte des nouveaux rappels de produits.',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _notificationsEnabled
                ? OutlinedButton.icon(
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: const Text('Desactiver les notifications'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isTogglingNotification ? null : _toggleNotifications,
                  )
                : ElevatedButton.icon(
                    icon: _isTogglingNotification
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.notifications_active),
                    label: Text(_isTogglingNotification ? 'Activation...' : 'Activer les notifications'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isTogglingNotification ? null : _toggleNotifications,
                  ),
          ),
        ]),
      ),
    );
  }

  Future<void> _toggleNotifications() async {
    setState(() => _isTogglingNotification = true);
    if (_notificationsEnabled) {
      await NotificationService.unsubscribe();
      setState(() { _notificationsEnabled = false; _isTogglingNotification = false; });
    } else {
      final granted = await NotificationService.subscribe();
      setState(() { _notificationsEnabled = granted; _isTogglingNotification = false; });
    }
  }
}

/// Shimmer placeholder pour une card du carousel d'alertes
class _AlertCardShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  const _AlertCardShimmer({this.width, this.height});
  @override
  State<_AlertCardShimmer> createState() => _AlertCardShimmerState();
}

class _AlertCardShimmerState extends State<_AlertCardShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Card(
        margin: EdgeInsets.zero,
        child: Column(children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Container(color: cs.primaryContainer.withValues(alpha: _anim.value)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: _anim.value), borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(height: 12, width: 80, decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: _anim.value), borderRadius: BorderRadius.circular(6))),
                const Spacer(),
                Container(height: 10, width: 70, decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: _anim.value), borderRadius: BorderRadius.circular(6))),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}