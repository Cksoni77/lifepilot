import 'package:flutter/material.dart';

import '../models/app_notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({required this.notification, super.key});
  final AppNotification notification;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(notification.title),
    subtitle: Text(notification.body),
  );
}
