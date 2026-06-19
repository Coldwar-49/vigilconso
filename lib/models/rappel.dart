// lib/models/rappel.dart
// Typed model for RappelConso v2.1 API (dataset: rappelconso-v2-gtin-espaces)
// Field names verified via live API call 2026-06-18.
// WARNING: 'reference_fiche' does NOT exist in v2 API — use lien_vers_la_fiche_rappel.

class Rappel {
  final int id;
  final String libelle;
  final String marqueProduit;
  final String? modelesOuReferences;
  final String? categorieProduit;
  final String? datePublication;
  final String? dateDebutCommercialisation;
  final String? dateDateFinCommercialisation;
  final String? dateFinProcedureRappel;
  final String? motifRappel;
  final String? risquesEncourous;
  final String? conduitesATenirConsommateur;
  final String? conditionnements;
  final String? liensVersLesImages;
  final String? lienVersFicheRappel;
  final String? lienVersAffichettePdf;
  final String? zoneGeographiqueDeVente;

  const Rappel({
    required this.id,
    required this.libelle,
    required this.marqueProduit,
    this.modelesOuReferences,
    this.categorieProduit,
    this.datePublication,
    this.dateDebutCommercialisation,
    this.dateDateFinCommercialisation,
    this.dateFinProcedureRappel,
    this.motifRappel,
    this.risquesEncourous,
    this.conduitesATenirConsommateur,
    this.conditionnements,
    this.liensVersLesImages,
    this.lienVersFicheRappel,
    this.lienVersAffichettePdf,
    this.zoneGeographiqueDeVente,
  });

  factory Rappel.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return Rappel(
      id: (map['id'] as int?) ?? 0,
      libelle: (map['libelle'] as String?)?.isNotEmpty == true
          ? map['libelle'] as String
          : (map['modeles_ou_references'] as String?) ?? 'Produit inconnu',
      marqueProduit: (map['marque_produit'] as String?) ?? '',
      modelesOuReferences: map['modeles_ou_references'] as String?,
      categorieProduit: map['categorie_produit'] as String?,
      datePublication: map['date_publication'] as String?,
      dateDebutCommercialisation: map['date_debut_commercialisation'] as String?,
      dateDateFinCommercialisation: map['date_date_fin_commercialisation'] as String?,
      dateFinProcedureRappel: map['date_de_fin_de_la_procedure_de_rappel'] as String?,
      motifRappel: map['motif_rappel'] as String?,
      risquesEncourous: map['risques_encourus'] as String?,
      conduitesATenirConsommateur: map['conduites_a_tenir_par_le_consommateur'] as String?,
      conditionnements: map['conditionnements'] as String?,
      liensVersLesImages: map['liens_vers_les_images'] as String?,
      // lien_vers_la_fiche_rappel contains the FULL URL in v2 (not a numeric ID as in v1)
      lienVersFicheRappel: map['lien_vers_la_fiche_rappel'] as String?,
      lienVersAffichettePdf: map['lien_vers_affichette_pdf'] as String?,
      zoneGeographiqueDeVente: map['zone_geographique_de_vente'] as String?,
    );
  }

  /// Backwards-compatible map for screens not yet migrated to typed Rappel.
  /// Used by FavoritesService which still stores a dynamic map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'libelle': libelle,
    'marque_produit': marqueProduit,
    'modeles_ou_references': modelesOuReferences,
    'categorie_produit': categorieProduit,
    'date_publication': datePublication,
    'date_debut_commercialisation': dateDebutCommercialisation,
    'date_date_fin_commercialisation': dateDateFinCommercialisation,
    'date_de_fin_de_la_procedure_de_rappel': dateFinProcedureRappel,
    'motif_rappel': motifRappel,
    'risques_encourus': risquesEncourous,
    'conduites_a_tenir_par_le_consommateur': conduitesATenirConsommateur,
    'conditionnements': conditionnements,
    'liens_vers_les_images': liensVersLesImages,
    'lien_vers_la_fiche_rappel': lienVersFicheRappel,
    'lien_vers_affichette_pdf': lienVersAffichettePdf,
    'zone_geographique_de_vente': zoneGeographiqueDeVente,
  };
}
