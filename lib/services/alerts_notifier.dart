import 'package:flutter/foundation.dart';

/// Notifie le nombre de nouvelles alertes depuis la dernière visite.
/// Mis à jour par HomeScreen, lu par MainScreen pour afficher le badge.
final ValueNotifier<int> newAlertsNotifier = ValueNotifier(0);
