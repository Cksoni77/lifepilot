import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/notifications/services/notification_service.dart';

export 'app/app.dart' show LifePilotApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const LifePilotApp());
}
