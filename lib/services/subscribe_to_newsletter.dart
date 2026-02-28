// lib/services/subscribe_to_newsletter.dart
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Service de gestion des notifications push via OneSignal.
class NotificationService {
  /// Vérifie si l'utilisateur a activé les notifications push.
  static bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  /// Demande la permission et active les notifications push.
  /// Retourne true si l'utilisateur a accepté.
  static Future<bool> subscribe() async {
    final granted = await OneSignal.Notifications.requestPermission(true);
    if (granted) {
      await OneSignal.User.pushSubscription.optIn();
    }
    return granted;
  }

  /// Désactive les notifications push.
  static Future<void> unsubscribe() async {
    await OneSignal.User.pushSubscription.optOut();
  }
}
