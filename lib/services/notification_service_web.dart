// Stub web — OneSignal n'est pas supporté sur web, ces méthodes ne font rien
class NotificationService {
  static void initialize(String appId) {}
  static bool isSubscribed() => false;
  static Future<bool> subscribe() async => false;
  static Future<void> unsubscribe() async {}
}
