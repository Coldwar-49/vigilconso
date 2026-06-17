import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// FilterState — value object représentant l'état courant des filtres.
// Immuable — copyWith pour créer des variantes modifiées.
// ---------------------------------------------------------------------------

class FilterState {
  final Set<String> riskLevels; // 'grave', 'modéré', 'faible' — vide = tous
  final int? dateDays; // 7, 30, 90 — null = pas de filtre date preset
  final DateTimeRange? customDateRange; // non-null si 'Personnalisé' sélectionné
  final String brandKeyword; // '' = pas de filtre marque
  final String readFilter; // 'all', 'unread', 'read' — défaut: 'all'

  const FilterState({
    this.riskLevels = const {},
    this.dateDays,
    this.customDateRange,
    this.brandKeyword = '',
    this.readFilter = 'all',
  });

  bool get hasActiveFilters =>
      riskLevels.isNotEmpty ||
      dateDays != null ||
      customDateRange != null ||
      brandKeyword.isNotEmpty ||
      readFilter != 'all';

  /// Calcule dateFrom ('YYYY-MM-DD') pour l'appel API selon dateDays ou customDateRange
  String? get apiDateFrom {
    if (customDateRange != null) {
      return '${customDateRange!.start.year.toString().padLeft(4, '0')}-'
          '${customDateRange!.start.month.toString().padLeft(2, '0')}-'
          '${customDateRange!.start.day.toString().padLeft(2, '0')}';
    }
    if (dateDays != null) {
      final d = DateTime.now().subtract(Duration(days: dateDays!));
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  /// Calcule dateTo ('YYYY-MM-DD') pour le filtre personnalisé
  String? get apiDateTo {
    if (customDateRange != null) {
      return '${customDateRange!.end.year.toString().padLeft(4, '0')}-'
          '${customDateRange!.end.month.toString().padLeft(2, '0')}-'
          '${customDateRange!.end.day.toString().padLeft(2, '0')}';
    }
    return null;
  }

  FilterState copyWith({
    Set<String>? riskLevels,
    int? dateDays,
    bool clearDateDays = false,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    String? brandKeyword,
    String? readFilter,
  }) {
    return FilterState(
      riskLevels: riskLevels ?? this.riskLevels,
      dateDays: clearDateDays ? null : (dateDays ?? this.dateDays),
      customDateRange:
          clearCustomDateRange ? null : (customDateRange ?? this.customDateRange),
      brandKeyword: brandKeyword ?? this.brandKeyword,
      readFilter: readFilter ?? this.readFilter,
    );
  }

  /// Sérialise en Map pour SharedPreferences
  /// (customDateRange non inclus — reset entre sessions)
  Map<String, dynamic> toJson() => {
        'riskLevels': riskLevels.toList(),
        'dateDays': dateDays,
        'brandKeyword': brandKeyword,
        'readFilter': readFilter,
      };

  /// Désérialise depuis SharedPreferences
  /// (customDateRange toujours null après restore)
  factory FilterState.fromJson(Map<String, dynamic> json) {
    return FilterState(
      riskLevels: Set<String>.from((json['riskLevels'] as List? ?? [])),
      dateDays: json['dateDays'] as int?,
      brandKeyword: (json['brandKeyword'] as String?) ?? '',
      readFilter: (json['readFilter'] as String?) ?? 'all',
    );
  }

  static const FilterState empty = FilterState();
}

// ---------------------------------------------------------------------------
// FilterPanel — bottom sheet réutilisable avec 4 sections de filtres
// ---------------------------------------------------------------------------

class FilterPanel extends StatefulWidget {
  final FilterState initialState;
  final void Function(FilterState) onApply;
  final VoidCallback onReset;

  const FilterPanel({
    super.key,
    required this.initialState,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Set<String> _riskLevels;
  late int? _dateDays;
  late DateTimeRange? _customDateRange;
  late TextEditingController _brandController;
  late String _readFilter; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _riskLevels = Set.from(widget.initialState.riskLevels);
    _dateDays = widget.initialState.dateDays;
    _customDateRange = widget.initialState.customDateRange;
    _brandController =
        TextEditingController(text: widget.initialState.brandKeyword);
    _readFilter = widget.initialState.readFilter;
  }

  @override
  void dispose() {
    _brandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Titre
              const Text(
                'Filtres',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              // Section Niveau de risque
              Text(
                'Niveau de risque',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _riskChip('grave', 'Grave', cs),
                _riskChip('modéré', 'Modéré', cs),
                _riskChip('faible', 'Faible', cs),
              ]),
              const SizedBox(height: 24),
              // Section Période
              Text(
                'Période',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _dateDaysChip(7, '7 jours', cs),
                _dateDaysChip(30, '30 jours', cs),
                _dateDaysChip(90, '90 jours', cs),
                _customDateChip(cs),
              ]),
              const SizedBox(height: 24),
              // Section Marque / mot-clé
              Text(
                'Marque / mot-clé',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(
                  hintText: 'Ex : Danone, Samsung',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Section Statut (locked decision CONTEXT.md)
              Text(
                'Statut',
                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                _readFilterChip('all', 'Tout', cs),
                _readFilterChip('unread', 'Non lus', cs),
                _readFilterChip('read', 'Lus', cs),
              ]),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              // Boutons d'action
              Row(children: [
                TextButton(
                  onPressed: () {
                    widget.onReset();
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyAndClose,
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  // ── Chip helpers ──────────────────────────────────────────────────────────

  Widget _riskChip(String level, String label, ColorScheme cs) {
    final selected = _riskLevels.contains(level);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() {
        if (v) {
          _riskLevels = {..._riskLevels, level};
        } else {
          _riskLevels = _riskLevels.difference({level});
        }
      }),
      selectedColor: cs.primary,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
      backgroundColor: cs.surfaceContainerHighest,
      showCheckmark: false,
    );
  }

  Widget _dateDaysChip(int days, String label, ColorScheme cs) {
    final selected = _dateDays == days && _customDateRange == null;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() {
        _dateDays = v ? days : null;
        _customDateRange = null; // mutuellement exclusif
      }),
      selectedColor: cs.primary,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
      backgroundColor: cs.surfaceContainerHighest,
      showCheckmark: false,
    );
  }

  Widget _customDateChip(ColorScheme cs) {
    final hasCustom = _customDateRange != null;
    final label = hasCustom
        ? '${_customDateRange!.start.day.toString().padLeft(2, '0')}/${_customDateRange!.start.month.toString().padLeft(2, '0')} – '
            '${_customDateRange!.end.day.toString().padLeft(2, '0')}/${_customDateRange!.end.month.toString().padLeft(2, '0')}'
        : 'Personnalisé...';
    return FilterChip(
      label: Text(label),
      selected: hasCustom,
      onSelected: (_) async {
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (range != null) {
          setState(() {
            _customDateRange = range;
            _dateDays = null;
          });
        }
      },
      selectedColor: cs.primary,
      labelStyle: TextStyle(color: hasCustom ? cs.onPrimary : cs.onSurface),
      backgroundColor: cs.surfaceContainerHighest,
      showCheckmark: false,
    );
  }

  /// Section Statut : Tout / Non lus / Lus (locked decision CONTEXT.md)
  Widget _readFilterChip(String value, String label, ColorScheme cs) {
    final selected = _readFilter == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _readFilter = value),
      selectedColor: cs.primary,
      labelStyle: TextStyle(color: selected ? cs.onPrimary : cs.onSurface),
      backgroundColor: cs.surfaceContainerHighest,
      showCheckmark: false,
    );
  }

  void _applyAndClose() {
    final state = FilterState(
      riskLevels: Set.from(_riskLevels),
      dateDays: _customDateRange != null ? null : _dateDays,
      customDateRange: _customDateRange,
      brandKeyword: _brandController.text.trim(),
      readFilter: _readFilter,
    );
    widget.onApply(state);
    Navigator.pop(context);
  }
}
