import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double height;

  const AppLogo({
    super.key,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(
        Colors.white,
        BlendMode.multiply,
      ),
      child: Image.asset(
        'assets/images/logo.png',
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
