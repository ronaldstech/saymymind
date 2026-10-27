import 'package:flutter/material.dart';

void main() => runApp(const SayMyMindApp());

class SayMyMindApp extends StatelessWidget {
  const SayMyMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    const canvas = Color(0xFFF6F5EF);
    return MaterialApp(
      title: 'SayMyMind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB9F278)),
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const ink = Color(0xFF17211D);
  static const muted = Color(0xFF758078);
  static const lime = Color(0xFFB9F278);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxHeight < 720;
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
                        Row(children: [
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(13)),
                            child: const Center(child: Text('s', style: TextStyle(color: lime, fontSize: 25, fontWeight: FontWeight.w800, height: 1))),
                          ),
                          const SizedBox(width: 10),
                          const Text('saymymind', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: const Row(children: [Icon(Icons.lock_outline_rounded, size: 14, color: muted), SizedBox(width: 5), Text('A little more private', style: TextStyle(fontSize: 11, color: ink, fontWeight: FontWeight.w600))]),
                          ),
                        ]),
                        SizedBox(height: compact ? 20 : 34),
                        const _ConversationArt(),
                        SizedBox(height: compact ? 22 : 30),
                        const Text('A place to say\nwhat’s on your mind.', textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 39, height: 1.08, letterSpacing: -1.8, fontWeight: FontWeight.w800, color: ink)),
                        const SizedBox(height: 14),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Share the thoughts you keep to yourself, hear from people who get it, and feel a little less alone.',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.55, color: muted)),
                        ),
                        SizedBox(height: compact ? 24 : 32),
                        SizedBox(
                          width: double.infinity, height: 58,
                          child: FilledButton(
                            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Your fresh start is coming soon.')),
                            ),
                            style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Get started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), SizedBox(width: 9), Icon(Icons.arrow_forward_rounded, size: 19)]),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.auto_awesome, size: 15, color: Color(0xFF74816F)), SizedBox(width: 7),
                          Text('No email. No password. Just you.', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w500)),
                        ]),
                        SizedBox(height: compact ? 20 : 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ConversationArt extends StatelessWidget {
  const _ConversationArt();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 248,
      width: 320,
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 218, height: 218, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE9EEDF))),
        Positioned(left: 8, top: 28, child: _Note(color: Colors.white, angle: -0.07, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('somewhere to\nput the heavy stuff.', style: TextStyle(color: WelcomeScreen.ink, fontSize: 15, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          SizedBox(height: 12), _AnonLabel(),
        ]))),
        Positioned(right: 1, top: 20, child: Container(width: 52, height: 52, decoration: const BoxDecoration(color: WelcomeScreen.lime, shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, color: WelcomeScreen.ink, size: 22))),
        Positioned(right: 2, bottom: 23, child: _Note(color: WelcomeScreen.ink, angle: 0.055, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('you’re not the\nonly one 🤍', style: TextStyle(color: Colors.white, fontSize: 15, height: 1.25, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          SizedBox(height: 12), Row(children: [Icon(Icons.favorite_border_rounded, size: 14, color: WelcomeScreen.lime), SizedBox(width: 5), Text('12 felt this', style: TextStyle(color: Color(0xFFC3CDC5), fontSize: 10))]),
        ]))),
        Positioned(left: 15, bottom: 14, child: Container(width: 39, height: 39, decoration: const BoxDecoration(color: Color(0xFFD8D2F4), shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: WelcomeScreen.ink))),
        Positioned(top: 5, left: 84, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFE8A990), shape: BoxShape.circle))),
      ]),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.color, required this.angle, required this.child});
  final Color color;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 205,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 22, offset: const Offset(0, 9))]),
      child: child,
    ),
  );
}

class _AnonLabel extends StatelessWidget {
  const _AnonLabel();

  @override
  Widget build(BuildContext context) => const Row(children: [
    CircleAvatar(radius: 9, backgroundColor: Color(0xFFE7E8E0), child: Icon(Icons.person_outline_rounded, size: 12, color: WelcomeScreen.muted)),
    SizedBox(width: 6), Text('someone, somewhere', style: TextStyle(color: WelcomeScreen.muted, fontSize: 10)),
  ]);
}


