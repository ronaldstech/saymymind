import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/conversation_art.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 720;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(children: [
                        const SizedBox(height: 18),
                        const _WelcomeHeader(),
                        SizedBox(height: isCompact ? 20 : 34),
                        const ConversationArt(),
                        SizedBox(height: isCompact ? 22 : 30),
                        const Text(
                          'A place to say\nwhat’s on your mind.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 39,
                            height: 1.08,
                            letterSpacing: -1.8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Share the thoughts you keep to yourself, hear from people who get it, and feel a little less alone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.55,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        SizedBox(height: isCompact ? 24 : 32),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: FilledButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Your fresh start is coming soon.'),
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.ink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 9),
                                Icon(Iconsax.arrow_right_1, size: 19),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.magic_star, size: 15, color: Color(0xFF74816F)),
                            SizedBox(width: 7),
                            Text(
                              'No email. No password. Just you.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 20 : 30),
                      ]),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Text(
              's',
              style: TextStyle(
                color: AppColors.lime,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'saymymind',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(children: [
            Icon(Iconsax.lock, size: 14, color: AppColors.muted),
            SizedBox(width: 5),
            Text(
              'A little more private',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
        ),
      ]);
}
