// Sélection automatique : stub web ou implémentation mobile selon la plateforme
export 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_mobile.dart';
