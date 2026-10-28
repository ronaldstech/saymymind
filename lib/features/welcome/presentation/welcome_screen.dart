import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/presentation/home_screen.dart';
import 'widgets/conversation_art.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void dispose() {
    _authRepository.close();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.registerAnonymousUser();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => HomeScreen(user: user)),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxHeight < 720;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        const _WelcomeHeader(),
                        SizedBox(height: isCompact ? 20 : 34),
                        const ConversationArt(),
                        SizedBox(height: isCompact ? 22 : 30),
                        const Text(
                          'A place to say\nwhat\u2019s on your mind.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 39,
                            height: 1.08,
                            letterSpacing: -1.8,
                            fontWeight: FontWeight.w800,
                            color: AppColors.prestigeMauve,
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
                            onPressed: _isRegistering ? null : _register,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.prestigeMauve,
                              foregroundColor: AppColors.softBlue,
                              disabledBackgroundColor: AppColors.prestigeMauve,
                              disabledForegroundColor: AppColors.softBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isRegistering
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.softBlue,
                                    ),
                                  )
                                : const Row(
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
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.prestigeMauve,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        SizedBox(height: isCompact ? 20 : 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.prestigeMauve,
          borderRadius: BorderRadius.circular(13),
        ),
        child: const Center(
          child: Text(
            's',
            style: TextStyle(
              color: AppColors.martianGreen,
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
          color: AppColors.prestigeMauve,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.orangeYellow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Iconsax.lock, size: 14, color: AppColors.muted),
            SizedBox(width: 5),
            Text(
              'A little more private',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.prestigeMauve,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
