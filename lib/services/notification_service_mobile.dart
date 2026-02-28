// Implémentation mobile (Android / iOS) — utilise OneSignal
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  static void initialize(String appId) {
    OneSignal.initialize(appId);
  }

  static bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }

  static Future<bool> subscribe() async {
    final granted = await OneSignal.Notifications.requestPermission(true);
    if (granted) await OneSignal.User.pushSubscription.optIn();
    return granted;
  }

  static Future<void> unsubscribe() async {
    await OneSignal.User.pushSubscription.optOut();
  }
}
