import 'package:flutter/material.dart';
import 'package:saymymind/core/theme/app_theme.dart';

class ConversationNote extends StatelessWidget {
  const ConversationNote({
    required this.color,
    required this.angle,
    required this.child,
    super.key,
  });

  final Color color;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          width: 205,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: child,
        ),
      );
}

