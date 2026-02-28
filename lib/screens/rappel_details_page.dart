import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vigiconso/widgets/app_menu.dart';
import 'package:vigiconso/services/favorites_service.dart';

class RappelDetailsPage extends StatefulWidget {
  final dynamic rappel;

  const RappelDetailsPage({Key? key, required this.rappel}) : super(key: key);

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
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : null,
                  ),
                  tooltip: _isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                  onPressed: _toggleFavorite,
                ),
                const AppMenu(),
              ],
            ),
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
                color: Colors.black.withOpacity(0.5),
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

  /// Retourne l'URL de l'image en passant par un proxy CORS si on est sur Web.
  /// wsrv.nl est un CDN/proxy gratuit qui ajoute les headers CORS manquants.
  String _proxiedImageUrl(String url) {
    if (!kIsWeb) return url;
    final encoded = Uri.encodeComponent(url);
    return 'https://wsrv.nl/?url=$encoded&output=jpg&q=85';
  }

  Widget _buildNetworkImageWithFallback(
    String url, {
    BoxFit fit = BoxFit.cover,
    required Widget Function(BuildContext) hasError,
  }) {
    final imageUrl = _proxiedImageUrl(url);

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
      color: cs.tertiaryContainer.withOpacity(0.5),
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
                  side: BorderSide(color: cs.error.withOpacity(0.4)),
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
      color: cs.errorContainer.withOpacity(0.5),
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
            _buildInfoRow(
                'Compensation', widget.rappel['modalites_de_compensation']),
            _buildInfoRow(
              'Date limite de rappel',
              widget.rappel['date_de_fin_de_la_procedure_de_rappel'],
            ),
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