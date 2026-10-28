import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final RegisteredUser? user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const _destinations = [
    _Destination('SMM', Iconsax.home_2),
    _Destination('Call', Iconsax.call_calling),
    _Destination('Chat', Iconsax.message_text),
    _Destination('Messages', Iconsax.messages_2),
    _Destination('Premium', Iconsax.crown_1),
  ];

  void _showProfile() {
    final user = widget.user;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.displayName.isNotEmpty == true ? user!.displayName : 'SAYMYMIND user'),
            if (user?.username.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('@${user!.username}'),
            ],
            if (user?.publicId.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text('ID: ${user!.publicId}'),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
      ),
    );
  }

  void _showSettings() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.softBlue.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Iconsax.setting_2, color: AppColors.prestigeMauve, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Settings'),
          ],
        ),
        content: const Text(
          'Your account and privacy settings will be available here.',
          style: TextStyle(color: AppColors.muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final destination = _destinations[_selectedIndex];
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.prestigeMauve,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        alignment: Alignment.center,
                        child: const Text('s', style: TextStyle(color: AppColors.martianGreen, fontSize: 27, fontWeight: FontWeight.w900, height: 1)),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          destination.label == 'SMM' ? 'SAYMYMIND' : destination.label,
                          style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Profile menu',
                        offset: const Offset(0, 12),
                        position: PopupMenuPosition.under,
                        color: Colors.white,
                        elevation: 12,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.8)),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 236, maxWidth: 280),
                        onSelected: (value) {
                          if (value == 'profile') _showProfile();
                          if (value == 'settings') _showSettings();
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            enabled: false,
                            height: 72,
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: const BoxDecoration(
                                    color: AppColors.softBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(Iconsax.user, size: 21, color: AppColors.prestigeMauve),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.user?.displayName.isNotEmpty == true
                                            ? widget.user!.displayName
                                            : 'SAYMYMIND user',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w800),
                                      ),
                                      if (widget.user?.username.isNotEmpty == true)
                                        Text(
                                          '@${widget.user!.username}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: const _ProfileMenuItem(icon: Iconsax.user, label: 'My profile'),
                          ),
                          PopupMenuItem<String>(
                            value: 'settings',
                            child: const _ProfileMenuItem(icon: Iconsax.setting_2, label: 'Settings'),
                          ),
                        ],
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.softBlue),
                          ),
                          child: const Icon(Iconsax.user, size: 21, color: AppColors.prestigeMauve),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _selectedIndex == 0 ? _HomeContent(user: widget.user) : _ComingSoonContent(destination: destination)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.7)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.prestigeMauve.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: List.generate(_destinations.length, (index) {
                final item = _destinations[index];
                final selected = index == _selectedIndex;
                return Expanded(
                  child: Semantics(
                    button: true,
                    selected: selected,
                    label: item.label,
                    child: InkWell(
                      onTap: () => setState(() => _selectedIndex = index),
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.softBlue.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 21,
                              color: selected
                                  ? AppColors.prestigeMauve
                                  : AppColors.muted.withValues(alpha: 0.72),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selected
                                    ? AppColors.prestigeMauve
                                    : AppColors.muted.withValues(alpha: 0.78),
                                fontSize: 9,
                                letterSpacing: -0.1,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: AppColors.prestigeMauve),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w600)),
        ],
      );
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.user});
  final RegisteredUser? user;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.martianGreen, shape: BoxShape.circle), child: const Icon(Iconsax.heart, color: AppColors.prestigeMauve, size: 32)),
                const SizedBox(height: 24),
                Text(user?.displayName.isNotEmpty == true ? 'Welcome, ${user!.displayName}' : 'You’re in.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.prestigeMauve)),
                const SizedBox(height: 10),
                const Text('Your space to say what’s on your mind is ready.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.5, color: AppColors.muted)),
                if (user?.publicId.isNotEmpty == true) ...[
                  const SizedBox(height: 28),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(14)), child: Text(user!.publicId, style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w600))),
                ],
              ],
            ),
          ),
        ),
      );
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent({required this.destination});
  final _Destination destination;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(destination.icon, size: 44, color: AppColors.prestigeMauve),
            const SizedBox(height: 16),
            Text(destination.label, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AppColors.prestigeMauve)),
            const SizedBox(height: 8),
            const Text('Coming soon', style: TextStyle(color: AppColors.muted, fontSize: 15)),
          ],
        ),
      );
}
