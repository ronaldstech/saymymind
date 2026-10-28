import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_start_gate.dart';

class SayMyMindApp extends StatelessWidget {
  const SayMyMindApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SayMyMind',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const AppStartGate(),
  );
}
