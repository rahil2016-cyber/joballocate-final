import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool showText;
  final double fontSize;

  const AppLogo({
    super.key,
    this.size = 28,
    this.color,
    this.showText = false,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.cover,
      ),
    );

    if (!showText) return logo;

    return Row(
      children: [
        logo,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'JOBALLOCATE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.primary,
              fontSize: fontSize,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
