import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import 'conversation_note.dart';

class ConversationArt extends StatelessWidget {
  const ConversationArt({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 248,
        width: 320,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            width: 218,
            height: 218,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.martianGreen,
            ),
          ),
          Positioned(
            left: 8,
            top: 28,
            child: ConversationNote(
              color: AppColors.orangeYellow,
              angle: -0.07,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'somewhere to\nput the heavy stuff.',
                    style: TextStyle(
                      color: AppColors.prestigeMauve,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  _AnonymousLabel(),
                ],
              ),
            ),
          ),
          Positioned(
            right: 1,
            top: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.orangeYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.heart_copy, color: AppColors.prestigeMauve, size: 22),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 23,
            child: ConversationNote(
              color: AppColors.prestigeMauve,
              angle: 0.055,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'you’re not the\nonly one 🤍',
                    style: TextStyle(
                      color: AppColors.softBlue,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(children: [
                    Icon(Iconsax.heart, size: 14, color: AppColors.martianGreen),
                    SizedBox(width: 5),
                    Text(
                      '12 felt this',
                      style: TextStyle(color: AppColors.softBlue, fontSize: 10),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          Positioned(
            left: 15,
            bottom: 14,
            child: Container(
              width: 39,
              height: 39,
              decoration: const BoxDecoration(
                color: AppColors.martianGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.message, size: 18, color: AppColors.prestigeMauve),
            ),
          ),
          Positioned(
            top: 5,
            left: 84,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.orangeYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ]),
      );
}

class _AnonymousLabel extends StatelessWidget {
  const _AnonymousLabel();

  @override
  Widget build(BuildContext context) => const Row(children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.softBlue,
          child: Icon(Iconsax.user, size: 12, color: AppColors.muted),
        ),
        SizedBox(width: 6),
        Text(
          'someone, somewhere',
          style: TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ]);
}




