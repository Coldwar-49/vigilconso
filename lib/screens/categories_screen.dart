import 'package:flutter/material.dart';
import 'package:vigiconso/screens/rappel_screen.dart';
import 'package:vigiconso/utils/constants.dart' as utils;
import 'package:vigiconso/widgets/app_menu.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        'key': 'all',
        'icon': Icons.list_alt,
        'color': Colors.blue,
        'description':
            'Accédez à tous les rappels de produits sans filtrage par catégorie',
      },
      {
        'key': 'alimentation',
        'icon': Icons.restaurant,
        'color': Colors.green,
        'description':
            'Produits alimentaires, boissons, additifs, compléments...',
      },
      {
        'key': 'automobile',
        'icon': Icons.directions_car,
        'color': Colors.red,
        'description': 'Véhicules, pièces automobiles, équipements...',
      },
      {
        'key': 'bebe_enfant',
        'icon': Icons.child_care,
        'color': Colors.amber,
        'description':
            'Jouets, vêtements enfants, équipements de puériculture...',
      },
      {
        'key': 'hygiene_beaute',
        'icon': Icons.spa,
        'color': Colors.purple,
        'description': 'Cosmétiques, produits d\'hygiène, parfums...',
      },
      {
        'key': 'vetement_mode',
        'icon': Icons.checkroom,
        'color': Colors.pink,
        'description': 'Vêtements, chaussures, accessoires, bijoux...',
      },
      {
        'key': 'sport_loisirs',
        'icon': Icons.sports_basketball,
        'color': Colors.orange,
        'description': 'Équipements sportifs, jeux, articles de loisirs...',
      },
      {
        'key': 'maison_habitat',
        'icon': Icons.home,
        'color': Colors.brown,
        'description': 'Mobilier, décoration, articles ménagers...',
      },
      {
        'key': 'appareils_outils',
        'icon': Icons.electrical_services,
        'color': Colors.grey,
        'description': 'Électroménager, outillage, appareils divers...',
      },
      {
        'key': 'equipements_communication',
        'icon': Icons.devices,
        'color': Colors.teal,
        'description': 'Téléphones, ordinateurs, accessoires informatiques...',
      },
      {
        'key': 'autres',
        'icon': Icons.more_horiz,
        'color': Colors.indigo,
        'description':
            'Produits divers n\'entrant pas dans les autres catégories',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories'),
        elevation: 2,
        actions: const [AppMenu()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sélectionnez une catégorie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...categories.map((cat) => _buildCategoryCard(
                  context,
                  cat['key'],
                  utils.AppConstants.categories[cat['key']]!,
                  cat['description'],
                  cat['icon'],
                  cat['color'],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String categoryKey,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RappelListScreen(
                categoryKey: categoryKey,
                categoryTitle: title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    color: color, size: 32, semanticLabel: 'Icône de $title'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}
