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

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final id = widget.rappel['reference_fiche'] ?? widget.rappel['libelle'] ?? '';
    final fav = await FavoritesService.isFavorite(id);
    if (mounted) setState(() => _isFavorite = fav);
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
                crossAxisAlignment: CrossAxisAlignment.start,
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
      final rawUrls = imagesData.split(RegExp(r'[,;\s]+'));
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
    if (imageUrls.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Aucune image disponible'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _fullScreenImageUrl = imageUrls[index];
                      _isFullScreenImage = true;
                    });
                  },
                  child: Hero(
                    tag: 'product_image_${imageUrls[index]}',
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildNetworkImageWithFallback(
                          imageUrls[index],
                          fit: BoxFit.cover,
                          hasError: (context) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported,
                                      size: 40, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Image non disponible'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (imageUrls.length > 1)
          Center(
            child: Text(
              'Faites défiler pour voir plus d\'images (${imageUrls.length})',
              style: TextStyle(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetworkImageWithFallback(
    String url, {
    BoxFit fit = BoxFit.cover,
    required Widget Function(BuildContext) hasError,
  }) {
    try {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/images/placeholder.png',
        image: url,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        imageErrorBuilder: (context, error, stackTrace) {
          debugPrint('Erreur de chargement de l\'image: $error');
          return hasError(context);
        },
      );
    } catch (e) {
      debugPrint('Exception lors du chargement de l\'image: $e');
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported,
                  size: 40, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Image non disponible',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
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
    return Card(
      color: Colors.orange[50],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Risque identifié',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.rappel['risques_encourus'] ?? 'Information non disponible',
              style: const TextStyle(fontSize: 16),
            ),
            if ((widget.rappel['description_complementaire_risque'] ?? '')
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    widget.rappel['description_complementaire_risque'] ?? ''),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerActions() {
    final dynamic actions = widget.rappel['conduites_a_tenir_par_le_consommateur'];
    List<String> actionsList;

    if (actions == null) {
      actionsList = ['Information non disponible'];
    } else if (actions is String) {
      actionsList = actions.trim().isNotEmpty
          ? actions.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : ['Information non disponible'];
    } else if (actions is List) {
      actionsList = actions.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
      if (actionsList.isEmpty) {
        actionsList = ['Information non disponible'];
      }
    } else {
      actionsList = ['Information non disponible'];
    }

    return Card(
      color: Colors.red[50],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consignes de sécurité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            ...actionsList.map(
              (action) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(action)),
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
    final String textValue =
        (value?.toString() ?? '').isEmpty ? 'Non spécifié' : value.toString();
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

  String _extractDDM(String? identification) {
    if (identification == null || identification.isEmpty)
      return 'Non disponible';

    final ddmMatches = RegExp(r'date de durabilité minimale\$([\d-]+)')
        .allMatches(identification);
    if (ddmMatches.isNotEmpty) {
      return ddmMatches.map((m) => m.group(1)).join(', ');
    }

    final dateMatches =
        RegExp(r'\b(\d{2}[/-]\d{2}[/-]\d{4}|\d{4}[/-]\d{2}[/-]\d{2})\b')
            .allMatches(identification);
    if (dateMatches.isNotEmpty) {
      return dateMatches.map((m) => m.group(0)).join(', ');
    }

    return 'Non disponible';
  }
}