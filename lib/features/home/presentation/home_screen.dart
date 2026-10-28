import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.user, super.key});

  final RegisteredUser? user;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.martianGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.heart,
                    color: AppColors.prestigeMauve,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  user?.displayName.isNotEmpty == true
                      ? 'Welcome, ${user!.displayName}'
                      : 'You’re in.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.prestigeMauve,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your space to say what’s on your mind is ready.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                if (user?.publicId.isNotEmpty == true) ...[
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      user!.publicId,
                      style: const TextStyle(
                        color: AppColors.prestigeMauve,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
