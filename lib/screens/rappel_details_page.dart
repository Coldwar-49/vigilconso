import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vigiconso/utils/image_utils.dart';
import 'package:vigiconso/widgets/app_menu.dart';
import 'package:vigiconso/services/favorites_service.dart';
import 'package:vigiconso/services/read_status_service.dart';
import 'package:vigiconso/services/subscription_service.dart';

class RappelDetailsPage extends StatefulWidget {
  final dynamic rappel;

  const RappelDetailsPage({super.key, required this.rappel});

  @override
  State<RappelDetailsPage> createState() => _RappelDetailsPageState();
}

class _RappelDetailsPageState extends State<RappelDetailsPage> {
  bool _isFullScreenImage = false;
  String? _fullScreenImageUrl;
  bool _isFavorite = false;
  late final PageController _imagePageController;
  int _currentImagePage = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _checkFavoriteStatus();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final id = ReadStatusService.getRappelId(widget.rappel);
    if (id.isNotEmpty) {
      await ReadStatusService.markAsRead(id);
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final id = widget.rappel['reference_fiche'] ?? widget.rappel['libelle'] ?? '';
    final fav = await FavoritesService.isFavorite(id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggleFavorite(Map<String, dynamic>.from(widget.rappel));
    final id = widget.rappel['reference_fiche'] ?? widget.rappel['libelle'] ?? '';
    final fav = await FavoritesService.isFavorite(id);
    if (mounted) {
      setState(() => _isFavorite = fav);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _followBrand() async {
    // Dynamic map access: widget.rappel is dynamic, not a typed Rappel.
    final brand = widget.rappel['marque_produit']?.toString() ?? '';
    if (brand.isEmpty) return;
    await SubscriptionService.addBrand(brand);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marque "$brand" suivie'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareRappel() {
    final title = widget.rappel['libelle'] ?? 'Produit rappelé';
    final brand = widget.rappel['marque_produit'] ?? widget.rappel['nom_marque'] ?? '';
    final officialUrl = widget.rappel['lien_vers_la_fiche_rappel']?.toString() ?? '';
    final rawRisques = widget.rappel['risques_encourus'];
    String risques = '';
    if (rawRisques is String) risques = rawRisques.split(RegExp(r'[|,]')).first.trim();

    final buffer = StringBuffer();
    buffer.writeln('🚨 Rappel produit : $title');
    if (brand.isNotEmpty) buffer.writeln('Marque : $brand');
    if (risques.isNotEmpty) buffer.writeln('Risque : $risques');
    if (officialUrl.isNotEmpty) buffer.writeln('\nFiche officielle :');
    if (officialUrl.isNotEmpty) buffer.writeln(officialUrl);
    buffer.writeln('\nVia VigilConso');

    Share.share(buffer.toString(), subject: title);
  }

  /// Opens the official recall page using the full URL from lien_vers_la_fiche_rappel.
  /// (reference_fiche is null/absent in v2 API — do NOT use it to construct a URL)
  Future<void> _openOfficialPage() async {
    final officialUrl = widget.rappel['lien_vers_la_fiche_rappel']?.toString() ?? '';
    if (officialUrl.isEmpty) return;
    final uri = Uri.parse(officialUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> imageUrls = _extractImageUrls();

    return Scaffold(
      appBar: _isFullScreenImage
          ? null
          : AppBar(
              title: Text(widget.rappel['libelle'] ?? 'Détails du rappel'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Partager',
                  onPressed: _shareRappel,
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  onPressed: _toggleFavorite,
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_outlined),
                  tooltip: 'Suivre cette marque',
                  onPressed: _followBrand,
                ),
                const AppMenu(),
              ],
            ),
      bottomNavigationBar: _isFullScreenImage ? null : _buildStickyActionBar(),
      body: _isFullScreenImage
          ? _buildFullScreenImage()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagesSection(imageUrls),
                  const SizedBox(height: 20),
                  _buildHeaderSection(),
                  const SizedBox(height: 20),
                  _buildProductInfoSection(),
                  const SizedBox(height: 20),
                  _buildRiskSection(),
                  const SizedBox(height: 20),
                  _buildConsumerActions(),
                  const SizedBox(height: 20),
                  _buildDatesSection(),
                  const SizedBox(height: 20),
                  Builder(builder: (_) {
                    final lots = _buildLotsSection();
                    return lots ?? const SizedBox.shrink();
                  }),
                  const SizedBox(height: 20),
                  _buildContactInfo(),
                ],
              ),
            ),
    );
  }

  List<String> _extractImageUrls() {
    final dynamic imagesData = widget.rappel['liens_vers_les_images'];
    final List<String> imageUrls = [];

    if (imagesData is String && imagesData.isNotEmpty) {
      final rawUrls = imagesData.split(RegExp(r'[,;|\s]+'));
      for (var url in rawUrls) {
        final trimmedUrl = url.trim();
        if (trimmedUrl.startsWith('http')) {
          imageUrls.add(trimmedUrl);
        }
      }
    } else if (imagesData is List) {
      imageUrls.addAll(
        imagesData.whereType<String>().where((url) => url.startsWith('http')),
      );
    }

    return imageUrls;
  }

  Widget _buildFullScreenImage() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isFullScreenImage = false),
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: _fullScreenImageUrl != null
                  ? _buildNetworkImageWithFallback(
                      _fullScreenImageUrl!,
                      fit: BoxFit.contain,
                      hasError: (context) => const Center(
                        child: Text(
                          'Image non disponible',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: GestureDetector(
            onTap: () => setState(() => _isFullScreenImage = false),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection(List<String> imageUrls) {
    final cs = Theme.of(context).colorScheme;

    // Placeholder si aucune image
    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.image_not_supported, size: 50, color: cs.outline),
            const SizedBox(height: 8),
            Text('Aucune image disponible', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        ),
      );
    }

    return Column(children: [
      // Conteneur image pleine largeur
      Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: imageUrls.length == 1
            // Image unique — centrée, visible en entier
            ? GestureDetector(
                onTap: () => setState(() {
                  _fullScreenImageUrl = imageUrls[0];
                  _isFullScreenImage = true;
                }),
                child: _buildNetworkImageWithFallback(
                  imageUrls[0],
                  fit: BoxFit.contain,
                  hasError: (ctx) => Center(child: Icon(Icons.image_not_supported, size: 50, color: cs.outline)),
                ),
              )
            // Plusieurs images — PageView centré
            : PageView.builder(
                controller: _imagePageController,
                itemCount: imageUrls.length,
                onPageChanged: (i) => setState(() => _currentImagePage = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() {
                    _fullScreenImageUrl = imageUrls[i];
                    _isFullScreenImage = true;
                  }),
                  child: _buildNetworkImageWithFallback(
                    imageUrls[i],
                    fit: BoxFit.contain,
                    hasError: (ctx) => Center(child: Icon(Icons.image_not_supported, size: 50, color: cs.outline)),
                  ),
                ),
              ),
      ),
      // Indicateur de pages (points) si plusieurs images
      if (imageUrls.length > 1) ...[
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(imageUrls.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _currentImagePage == i ? 14 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: _currentImagePage == i ? cs.primary : cs.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(
          'Image ${_currentImagePage + 1} / ${imageUrls.length}  •  appuyez pour agrandir',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ] else
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Appuyez sur l\'image pour l\'agrandir',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
    ]);
  }

  Widget _buildNetworkImageWithFallback(
    String url, {
    BoxFit fit = BoxFit.cover,
    required Widget Function(BuildContext) hasError,
  }) {
    final imageUrl = ImageUtils.proxiedUrl(url);

    return Image.network(
      imageUrl,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Erreur image: $error');
        return hasError(context);
      },
    );
  }

  Widget _buildSectionCard({required String title, required Widget content, Color? cardColor}) {
    return Card(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          content,
        ]),
      ),
    );
  }

  /// Section dates clés — toujours affichée, valeurs nulles → 'Non spécifié'
  Widget _buildDatesSection() {
    return _buildSectionCard(
      title: 'Dates clés',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Publié', widget.rappel['date_publication']),
          _buildInfoRow('Début de commercialisation', widget.rappel['date_debut_commercialisation']),
          _buildInfoRow('Fin de commercialisation', widget.rappel['date_date_fin_commercialisation']),
          _buildInfoRow('Fin de rappel', widget.rappel['date_de_fin_de_la_procedure_de_rappel']),
        ],
      ),
    );
  }

  /// Section lots concernés — masquée si conditionnements est absent/vide (per CONTEXT.md)
  Widget? _buildLotsSection() {
    final lots = widget.rappel['conditionnements']?.toString() ?? '';
    if (lots.isEmpty) return null;
    return _buildSectionCard(
      title: 'Lots concernés',
      content: Text(
        lots,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }

  /// Sticky action bar at the bottom of the screen.
  /// Primary action: Voir la fiche officielle (uses lien_vers_la_fiche_rappel — full URL)
  /// Secondary: Télécharger affichette PDF (if URL present)
  /// Share: via share_plus
  Widget _buildStickyActionBar() {
    final officialUrl = widget.rappel['lien_vers_la_fiche_rappel']?.toString() ?? '';
    final pdfUrl = widget.rappel['lien_vers_affichette_pdf']?.toString() ?? '';
    final shareText = '${widget.rappel['libelle'] ?? 'Rappel'} — '
        '${widget.rappel['marque_produit'] ?? ''}\n'
        'Via VigilConso\n$officialUrl';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          // Voir la fiche officielle — primary action
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Fiche officielle', overflow: TextOverflow.ellipsis),
              onPressed: officialUrl.isEmpty ? null : _openOfficialPage,
            ),
          ),
          const SizedBox(width: 8),
          // Télécharger PDF — shown only if URL available
          if (pdfUrl.isNotEmpty) ...[
            IconButton.outlined(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Affichette PDF',
              onPressed: () async {
                final uri = Uri.parse(pdfUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          // Partager
          IconButton.outlined(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Partager',
            onPressed: () => Share.share(shareText),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rappel['libelle'] ?? 'Produit non spécifié',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Marque', widget.rappel['marque_produit']),
            _buildInfoRow('Référence', widget.rappel['modeles_ou_references']),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations produit',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Distributeur', widget.rappel['distributeurs']),
            _buildInfoRow('Catégorie', widget.rappel['categorie_produit']),
            _buildInfoRow(
                'Sous-catégorie', widget.rappel['sous_categorie_produit']),
            _buildInfoRow(
              'Date commercialisation',
              widget.rappel['date_debut_commercialisation'],
            ),
            _buildInfoRow('Motif du rappel', widget.rappel['motif_rappel']),
            _buildInfoRow(
              'DDM',
              _extractDDM(widget.rappel['identification_produits']),
            ),
            _buildInfoRow(
              'Conditionnement',
              widget.rappel['conditionements'] ?? 'Non spécifié',
            ),
            _buildInfoRow(
                'Conservation', widget.rappel['temperature_conservation']),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskSection() {
    // Découpe par | ou , pour gérer les valeurs multiples de l'API
    final rawRisques = widget.rappel['risques_encourus'];
    List<String> risques = [];
    if (rawRisques is String && rawRisques.trim().isNotEmpty) {
      risques = rawRisques
          .split(RegExp(r'[|,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawRisques is List) {
      risques = rawRisques.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    final descComp = (widget.rappel['description_complementaire_risque'] ?? '').toString().trim();

    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.tertiaryContainer.withValues(alpha: 0.5),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error),
                const SizedBox(width: 8),
                Text(
                  'Risque identifié',
                  style: TextStyle(
                    fontSize: 18,
                    color: cs.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (risques.isEmpty)
              Text('Information non disponible',
                  style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: risques.map((r) => Chip(
                  label: Text(
                    _capitalize(r),
                    style: TextStyle(fontSize: 13, color: cs.onErrorContainer, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: cs.errorContainer,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),
            if (descComp.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(descComp, style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _buildConsumerActions() {
    final dynamic actions = widget.rappel['conduites_a_tenir_par_le_consommateur'];
    List<String> actionsList;

    if (actions == null) {
      actionsList = [];
    } else if (actions is String) {
      actionsList = actions.trim().isNotEmpty
          ? actions.split(RegExp(r'[|,]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : [];
    } else if (actions is List) {
      actionsList = actions.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else {
      actionsList = [];
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.errorContainer.withValues(alpha: 0.5),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consignes de sécurité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.error,
              ),
            ),
            const SizedBox(height: 10),
            if (actionsList.isEmpty)
              Text('Information non disponible',
                  style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant))
            else
              ...actionsList.map(
                (action) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.arrow_forward_ios, size: 14, color: cs.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _capitalize(action),
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations complémentaires',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Contact', widget.rappel['numero_contact']),
            _buildInfoRow('Compensation', widget.rappel['modalites_de_compensation']),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    String textValue;
    if (value == null) {
      textValue = 'Non spécifié';
    } else if (value is List) {
      final joined = value.join(', ');
      textValue = joined.isEmpty ? 'Non spécifié' : joined;
    } else {
      final str = value.toString();
      textValue = str.isEmpty ? 'Non spécifié' : str;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label :',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(textValue),
          ),
        ],
      ),
    );
  }

  String _extractDDM(dynamic identification) {
    // L'API peut retourner une String, une List, ou null
    String text;
    if (identification == null) return 'Non disponible';
    if (identification is List) {
      text = identification.join(' ');
    } else {
      text = identification.toString();
    }
    if (text.trim().isEmpty) return 'Non disponible';

    final ddmMatches = RegExp(r'date de durabilité minimale\$([\d-]+)')
        .allMatches(text);
    if (ddmMatches.isNotEmpty) {
      return ddmMatches.map((m) => m.group(1)).join(', ');
    }

    final dateMatches =
        RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4}|\d{4}[/-]\d{2}[/-]\d{2})\b')
            .allMatches(text);
    if (dateMatches.isNotEmpty) {
      return dateMatches.map((m) => m.group(0)).join(', ');
    }

    return 'Non disponible';
  }
}
