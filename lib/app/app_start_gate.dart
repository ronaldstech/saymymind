import 'package:flutter/material.dart';

import '../features/auth/data/auth_session_store.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/welcome/presentation/welcome_screen.dart';

class AppStartGate extends StatefulWidget {
  const AppStartGate({super.key});

  @override
  State<AppStartGate> createState() => _AppStartGateState();
}

class _AppStartGateState extends State<AppStartGate> {
  late Future<String?> _savedToken;

  @override
  void initState() {
    super.initState();
    _savedToken = AuthSessionStore().readAccessToken();
  }

  void _retrySavedTokenRead() {
    setState(() {
      _savedToken = AuthSessionStore().readAccessToken();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
    future: _savedToken,
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
                    onPressed: _retrySavedTokenRead,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      if (snapshot.data?.isNotEmpty == true) {
        return const HomeScreen(user: null);
      }
      return const WelcomeScreen();
    },
  );
}
