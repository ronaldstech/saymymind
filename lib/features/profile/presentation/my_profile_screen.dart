import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../data/profile_repository.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _repository = ProfileRepository();
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  MyProfile? _profile;
  List<ProfileAvatar> _avatars = const [];
  String? _error;
  String? _avatarError;
  bool _loading = true;
  bool _avatarsLoading = true;
  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadAvatars();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _repository.close();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var profile = await _repository.fetchMyProfile();
      if (profile.username.isEmpty && profile.publicId.isNotEmpty) {
        final generated = _generateUsername(profile.publicId);
        profile = await _repository.updateMyProfile(
          username: generated,
          bio: profile.bio,
        );
        if (profile.username.isEmpty) {
          profile = MyProfile(
            publicId: profile.publicId,
            username: generated,
            bio: profile.bio,
            gender: profile.gender,
            age: profile.age,
            country: profile.country,
            avatarUrl: profile.avatarUrl,
          );
        }
      }
      if (!mounted) return;
      _setProfile(profile);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your profile. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAvatars() async {
    setState(() {
      _avatarsLoading = true;
      _avatarError = null;
    });
    try {
      final avatars = await _repository.fetchAvatars();
      if (mounted) setState(() => _avatars = avatars);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _avatarError = error.message);
    } catch (_) {
      if (mounted) setState(() => _avatarError = 'Could not load avatar choices.');
    } finally {
      if (mounted) setState(() => _avatarsLoading = false);
    }
  }

  void _setProfile(MyProfile profile) {
    setState(() {
      _profile = profile;
      _usernameController.text = profile.username;
      _bioController.text = profile.bio;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await _repository.updateMyProfile(
        username: _usernameController.text,
        bio: _bioController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save your profile. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleEditing() {
    if (_editing && _profile != null) {
      _usernameController.text = _profile!.username;
      _bioController.text = _profile!.bio;
    }
    setState(() {
      _editing = !_editing;
      _error = null;
    });
  }

  ProfileAvatar? get _selectedAvatar {
    final id = _profile?.avatarId;
    if (id == null) return null;
    for (final avatar in _avatars) {
      if (avatar.id == id) return avatar;
    }
    return null;
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: AppColors.softBlue, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 18),
              const Text('Choose an avatar', style: TextStyle(color: AppColors.prestigeMauve, fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Select one of the available SayMyMind avatars.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 18),
              if (_avatarsLoading)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: CircularProgressIndicator(color: AppColors.prestigeMauve),
                )
              else if (_avatarError != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(_avatarError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 12),
                      TextButton.icon(onPressed: _loadAvatars, icon: const Icon(Iconsax.refresh), label: const Text('Try again')),
                    ],
                  ),
                )
              else if (_avatars.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No avatars are available right now.', style: TextStyle(color: AppColors.muted)),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.55),
                  child: GridView.builder(
                    shrinkWrap: true,
                    itemCount: _avatars.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final selected = avatar.id == _profile?.avatarId;
                      return InkWell(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _selectAvatar(avatar);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.softBlue.withValues(alpha: 0.3) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected ? AppColors.prestigeMauve : AppColors.softBlue.withValues(alpha: 0.8),
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(13), child: _AvatarImage(avatar: avatar))),
                              if (selected)
                                const Positioned(
                                  right: 4,
                                  top: 4,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.prestigeMauve,
                                    child: Icon(Iconsax.tick_circle, color: Colors.white, size: 16),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectAvatar(ProfileAvatar avatar) async {
    if (_profile == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await _repository.updateMyProfile(
        username: _profile!.username,
        bio: _profile!.bio,
        avatarId: avatar.id,
      );
      if (mounted) {
        setState(() {
          _profile = profile;
          _error = null;
        });
      }
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not update your avatar. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Iconsax.arrow_left_2),
          ),
          title: const Text(
            'My profile',
            style: TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (_profile != null && !_loading)
              TextButton.icon(
                onPressed: _saving ? null : (_editing ? _saveProfile : _toggleEditing),
                icon: Icon(_editing ? Iconsax.tick_circle : Iconsax.edit_2, size: 18),
                label: Text(_editing ? 'Save' : 'Edit'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.prestigeMauve))
                  : _profile == null
                      ? _LoadError(message: _error ?? 'Could not load your profile.', onRetry: _loadProfile)
                      : Form(
                          key: _formKey,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                            children: [
                              _ProfileHero(
                                profile: _profile!,
                                avatar: _selectedAvatar,
                                onChangeAvatar: _showAvatarPicker,
                                saving: _saving,
                              ),
                              const SizedBox(height: 18),
                              if (_error != null) ...[
                                _ErrorBanner(message: _error!),
                                const SizedBox(height: 14),
                              ],
                              _SectionCard(
                                title: 'Your username',
                                icon: Iconsax.user,
                                child: Column(
                                  children: [
                                    _ProfileField(
                                      label: 'Username',
                                      icon: Iconsax.user_edit,
                                      controller: _usernameController,
                                      enabled: _editing,
                                      maxLength: 30,
                                      prefixText: '@',
                                      validator: (value) {
                                        final username = (value ?? '').trim();
                                        if (username.isEmpty) return 'Enter a username.';
                                        if (!RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(username)) {
                                          return 'Use 3–30 letters, numbers, dots, or underscores.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
                                    _ProfileField(
                                      label: 'Bio',
                                      icon: Iconsax.text,
                                      controller: _bioController,
                                      enabled: _editing,
                                      maxLength: 250,
                                      maxLines: 4,
                                      validator: (value) => (value ?? '').length > 250
                                          ? 'Use 250 characters or fewer.'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _SectionCard(
                                title: 'Personal details',
                                icon: Iconsax.profile_2user,
                                child: Column(
                                  children: [
                                    _DetailRow(
                                      icon: Iconsax.user_tag,
                                      label: 'Gender',
                                      value: _displayValue(_profile!.gender),
                                    ),
                                    const SizedBox(height: 15),
                                    _DetailRow(
                                      icon: Iconsax.calendar_1,
                                      label: 'Age',
                                      value: _profile!.age == null
                                          ? 'Not set'
                                          : '${_profile!.age} years old',
                                    ),
                                    const SizedBox(height: 15),
                                    _DetailRow(
                                      icon: Iconsax.global,
                                      label: 'Country',
                                      value: _displayValue(_profile!.country),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              _SectionCard(
                                title: 'Account details',
                                icon: Iconsax.shield_tick,
                                child: _AccountIdRow(publicId: _profile!.publicId),
                              ),
                              if (_editing) ...[
                                const SizedBox(height: 18),
                                SizedBox(
                                  height: 54,
                                  child: FilledButton.icon(
                                    onPressed: _saving ? null : _saveProfile,
                                    icon: _saving
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.softBlue),
                                          )
                                        : const Icon(Iconsax.tick_circle),
                                    label: Text(_saving ? 'Saving…' : 'Save changes'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.prestigeMauve,
                                      foregroundColor: AppColors.softBlue,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(onPressed: _saving ? null : _toggleEditing, child: const Text('Cancel')),
                              ],
                            ],
                          ),
                        ),
            ),
          ),
        ),
      );
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.avatar, required this.onChangeAvatar, required this.saving});

  final MyProfile profile;
  final ProfileAvatar? avatar;
  final VoidCallback onChangeAvatar;
  final bool saving;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.prestigeMauve,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(color: AppColors.prestigeMauve.withValues(alpha: 0.14), blurRadius: 22, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.softBlue,
                  backgroundImage: avatar == null
                      ? (profile.avatarUrl == null || profile.avatarUrl!.isEmpty ? null : NetworkImage(profile.avatarUrl!))
                      : MemoryImage(_avatarBytes(avatar!.imageData)),
                  child: avatar == null && (profile.avatarUrl == null || profile.avatarUrl!.isEmpty)
                      ? const Icon(Iconsax.user, color: AppColors.prestigeMauve, size: 30)
                      : null,
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Material(
                    color: AppColors.orangeYellow,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: saving ? null : onChangeAvatar,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: saving
                            ? const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.prestigeMauve))
                            : const Icon(Iconsax.edit_2, size: 14, color: AppColors.prestigeMauve),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.username.isEmpty ? 'SayMyMind member' : '@${profile.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.username.isEmpty ? 'Add a username' : 'Your public username',
                    style: TextStyle(color: AppColors.softBlue.withValues(alpha: 0.9), fontSize: 14),
                  ),
                  if (profile.publicId.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('ID · ${profile.publicId}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({required this.avatar});

  final ProfileAvatar avatar;

  @override
  Widget build(BuildContext context) => Image.memory(
        _avatarBytes(avatar.imageData),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.softBlue,
          child: Center(child: Icon(Iconsax.user, color: AppColors.prestigeMauve, size: 30)),
        ),
      );
}

Uint8List _avatarBytes(String imageData) {
  final separator = imageData.indexOf(',');
  final encoded = imageData.startsWith('data:') && separator >= 0
      ? imageData.substring(separator + 1)
      : imageData;
  try {
    return base64Decode(encoded);
  } on FormatException {
    return Uint8List(0);
  }
}

String _generateUsername(String publicId) {
  final safeId = publicId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final suffix = safeId.length > 24 ? safeId.substring(0, 24) : safeId;
  return suffix.isEmpty ? 'smm_user' : 'smm_$suffix';
}

String _displayValue(String? value) {
  if (value == null || value.trim().isEmpty) return 'Not set';
  final normalized = value.trim();
  return normalized[0].toUpperCase() + normalized.substring(1);
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.75)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.prestigeMauve, size: 19),
                const SizedBox(width: 9),
                Text(title, style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.enabled,
    this.maxLength,
    this.maxLines = 1,
    this.prefixText,
    this.validator,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final int? maxLength;
  final int maxLines;
  final String? prefixText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        enabled: enabled,
        maxLength: maxLength,
        maxLines: maxLines,
        validator: validator,
        textCapitalization: label == 'Bio' ? TextCapitalization.sentences : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          prefixIcon: Icon(icon, size: 19, color: AppColors.muted),
          filled: true,
          fillColor: enabled ? AppColors.softBlue.withValues(alpha: 0.13) : Colors.white,
          counterText: enabled ? null : '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.65))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.65))),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.4))),
        ),
      );
}

class _AccountIdRow extends StatelessWidget {
  const _AccountIdRow({required this.publicId});

  final String publicId;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Iconsax.personalcard, color: AppColors.muted, size: 19),
          const SizedBox(width: 11),
          const Expanded(child: Text('Public ID', style: TextStyle(color: AppColors.muted))),
          Flexible(
            child: Text(
              publicId.isEmpty ? 'Not available' : publicId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 19),
          const SizedBox(width: 11),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.cloud_cross, color: AppColors.muted, size: 42),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.5)),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Iconsax.refresh), label: const Text('Try again')),
            ],
          ),
        ),
      );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.prestigeMauve.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.prestigeMauve.withValues(alpha: 0.25)),
        ),
        child: Text(message, style: const TextStyle(color: AppColors.prestigeMauve, height: 1.45)),
      );
}
