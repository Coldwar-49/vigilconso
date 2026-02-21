class AppConstants {
  static const String apiBaseUrl = 'https://data.economie.gouv.fr/api/explore/v2.1/catalog/datasets/rappelconso-v2-gtin-espaces';
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

  // Méthode pour obtenir le filtre API selon la catégorie
  static String getCategoryFilter(String categoryKey) {
    switch (categoryKey) {
      case 'all':
        return ''; // Pas de filtre pour "tous"
      case 'alimentation':
        return 'categorie_produit like "%alimentation%" or sous_categorie_produit like "%aliment%"';
      case 'automobile':
        return 'categorie_produit like "%Automobiles%" or categorie_produit like "%déplacement%"';
      case 'bebe_enfant':
        return 'categorie_produit like "%Bébé%" or categorie_produit like "%Puériculture%" or categorie_produit like "%Jouets%" or categorie_produit like "%enfants%"';
      case 'hygiene_beaute':
        return 'categorie_produit like "%Hygiène%" or categorie_produit like "%Beauté%"';
      case 'vetement_mode':
        return 'categorie_produit like "%Vêtements%" or categorie_produit like "%Mode%" or categorie_produit like "%EPI%"';
      case 'sport_loisirs':
        return 'categorie_produit like "%Sports%" or categorie_produit like "%loisirs%"';
      case 'maison_habitat':
        return 'categorie_produit like "%Maison%" or categorie_produit like "%Habitat%"';
      case 'appareils_outils':
        return 'categorie_produit like "%Appareils électriques%" or categorie_produit like "%outils%"';
      case 'equipements_communication':
        return 'categorie_produit like "%Equipements de communication%"';
      case 'autres':
        return 'categorie_produit like "%autres%"';
      default:
        return '';
    }
  }
}
