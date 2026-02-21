class AppConstants {
  static const String apiBaseUrl =
      'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-espaces';
  static const int pageSize = 10;

  static const Map<String, String> categories = {
    'all': 'Tous les rappels',
    'alimentation': 'Alimentation',
    'automobile': 'Automobile',
    'bebe_enfant': 'Bébé et enfant',
    'hygiene_beaute': 'Hygiène et beauté',
    'vetement_mode': 'Vêtement et mode',
    'sport_loisirs': 'Sport et loisirs',
    'maison_habitat': 'Maison et habitat',
    'appareils_outils': 'Appareils électriques et outils',
    'equipements_communication': 'Équipements de communication',
    'autres': 'Autres',
  };

  // Icônes associées à chaque catégorie
  static const Map<String, String> categoryIcons = {
    'all': 'list_alt',
    'alimentation': 'fastfood',
    'automobile': 'directions_car',
    'bebe_enfant': 'child_care',
    'hygiene_beaute': 'spa',
    'vetement_mode': 'checkroom',
    'sport_loisirs': 'sports_soccer',
    'maison_habitat': 'home',
    'appareils_outils': 'electrical_services',
    'equipements_communication': 'devices',
    'autres': 'more_horiz',
  };

  /// Retourne le filtre API pour une catégorie donnée.
  /// Corrigé pour correspondre aux vraies valeurs de l'API gouvernementale.
  static String getCategoryFilter(String categoryKey) {
    switch (categoryKey) {
      case 'all':
        return '';
      case 'alimentation':
        return 'categorie_produit like "%Alimentation%" or '
            'sous_categorie_produit like "%aliment%" or '
            'categorie_produit like "%alimentaire%"';
      case 'automobile':
        return 'categorie_produit like "%Automobiles%" or '
            'categorie_produit like "%automobile%" or '
            'categorie_produit like "%véhicule%" or '
            'categorie_produit like "%déplacement%"';
      case 'bebe_enfant':
        return 'categorie_produit like "%Bébé%" or '
            'categorie_produit like "%Puériculture%" or '
            'categorie_produit like "%Jouets%" or '
            'categorie_produit like "%enfant%"';
      case 'hygiene_beaute':
        return 'categorie_produit like "%Hygiène%" or '
            'categorie_produit like "%Beauté%" or '
            'categorie_produit like "%cosmétique%"';
      case 'vetement_mode':
        return 'categorie_produit like "%Vêtements%" or '
            'categorie_produit like "%Mode%" or '
            'categorie_produit like "%EPI%" or '
            'categorie_produit like "%habillement%"';
      case 'sport_loisirs':
        return 'categorie_produit like "%Sports%" or '
            'categorie_produit like "%loisirs%" or '
            'categorie_produit like "%sport%"';
      case 'maison_habitat':
        return 'categorie_produit like "%Maison%" or '
            'categorie_produit like "%Habitat%" or '
            'categorie_produit like "%mobilier%" or '
            'categorie_produit like "%jardinage%"';
      case 'appareils_outils':
        return 'categorie_produit like "%Appareils électriques%" or '
            'categorie_produit like "%outils%" or '
            'categorie_produit like "%électroménager%"';
      case 'equipements_communication':
        return 'categorie_produit like "%Equipements de communication%" or '
            'categorie_produit like "%téléphone%" or '
            'categorie_produit like "%informatique%"';
      case 'autres':
        return 'categorie_produit like "%Autres%" or '
            'categorie_produit like "%autres%"';
      default:
        return '';
    }
  }
}
