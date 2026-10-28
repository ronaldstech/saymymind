import 'package:flutter/material.dart';

import '../features/auth/data/auth_session_store.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/profile/presentation/profile_completion_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

class AppStartGate extends StatefulWidget {
  const AppStartGate({super.key});

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  final _sessionStore = AuthSessionStore();
  late Future<_SavedSession> _savedSession;

  @override
  void initState() {
    super.initState();
    _savedSession = _readSavedSession();
  }

  Future<_SavedSession> _readSavedSession() async {
    final token = await _sessionStore.readAccessToken();
    if (token == null || token.isEmpty) {
      return const _SavedSession(hasToken: false, profileComplete: false);
    }
    return _SavedSession(
      hasToken: true,
      profileComplete: await _sessionStore.isProfileComplete(),
    );
  }

  void _retrySavedSessionRead() {
    setState(() {
      _savedSession = _readSavedSession();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<_SavedSession>(
    future: _savedSession,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not check your saved sign-in.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _retrySavedSessionRead,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final session = snapshot.data!;
      if (!session.hasToken) return const WelcomeScreen();
      if (!session.profileComplete) return const ProfileCompletionScreen();
      return const HomeScreen(user: null);
    },
  );
}

class _SavedSession {
  const _SavedSession({required this.hasToken, required this.profileComplete});

  final bool hasToken;
  final bool profileComplete;
}
