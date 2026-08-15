import 'package:flutter/material.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, color: foregroundColor, size: 19),
      ),
    );
  }
}
