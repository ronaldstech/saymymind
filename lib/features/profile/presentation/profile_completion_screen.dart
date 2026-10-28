import 'dart:convert';
import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:device_region/device_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../home/presentation/home_screen.dart';
import '../data/profile_repository.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({this.user, super.key});

  final RegisteredUser? user;

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _profileRepository = ProfileRepository();
  Country? _country;
  String? _gender;
  String? _errorMessage;
  bool _isSaving = false;
  bool _countryManuallySelected = false;
  int _step = 0;
  List<ProfileAvatar> _avatars = const [];
  ProfileAvatar? _selectedAvatar;
  bool _avatarsLoading = false;
  String? _avatarError;

  @override
  void initState() {
    super.initState();
    final publicId = widget.user?.publicId ?? '';
    _usernameController.text = _generateUsername(publicId);
    _detectDeviceCountry();
    _loadAvatars();
  }

  Future<void> _loadAvatars() async {
    setState(() { _avatarsLoading = true; _avatarError = null; });
    try {
      final avatars = await _profileRepository.fetchAvatars();
      if (mounted) setState(() => _avatars = avatars);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _avatarError = error.message);
    } catch (_) {
      if (mounted) setState(() => _avatarError = 'Could not load avatar choices.');
    } finally {
      if (mounted) setState(() => _avatarsLoading = false);
    }
  }

  Future<void> _detectDeviceCountry() async {
    String? code;
    try {
      code = await DeviceRegion.getSIMCountryCode();
    } catch (_) {
      // Some platforms and simulators do not expose SIM or network region.
    }
    if (code == null || code.trim().isEmpty) {
      for (final locale in ui.PlatformDispatcher.instance.locales) {
        final localeCode = locale.countryCode;
        if (localeCode != null && localeCode.isNotEmpty) {
          code = localeCode;
          break;
        }
      }
    }
    if (!mounted || _countryManuallySelected || code == null || code.trim().isEmpty) {
      return;
    }
    final country = CountryService().findByCode(code.trim().toUpperCase());
    if (country != null) setState(() => _country = country);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _profileRepository.close();
    super.dispose();
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: const TextStyle(color: AppColors.prestigeMauve),
        bottomSheetHeight: 560,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        inputDecoration: InputDecoration(
          hintText: 'Search countries',
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 19),
          filled: true,
          fillColor: AppColors.softBlue.withValues(alpha: 0.18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.prestigeMauve, width: 1.2),
          ),
        ),
      ),
      onSelect: (country) => setState(() {
        _country = country;
        _countryManuallySelected = true;
        _errorMessage = null;
      }),
    );
  }

  Future<void> _saveProfile() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (_gender == null || _country == null) {
      setState(() {
        _errorMessage = _gender == null
            ? 'Choose an option for gender to continue.'
            : 'Select a country to continue.';
      });
      return;
    }
    if (!isFormValid) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _profileRepository.completeProfile(
        gender: _gender!,
        age: int.parse(_ageController.text),
        country: _country!.name,
        username: _usernameController.text,
        bio: _bioController.text,
        avatarId: _selectedAvatar?.id,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => HomeScreen(user: widget.user)),
      );
    } on ProfileException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not save your profile. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _chooseGender(String value) {
    setState(() {
      _gender = value;
      _errorMessage = null;
    });
  }

  void _continue() {
    setState(() => _errorMessage = null);
    if (_step == 0 && _gender == null) {
      setState(() => _errorMessage = 'Choose an option for gender to continue.');
      return;
    }
    if (_step == 1 && !(_formKey.currentState?.validate() ?? false)) return;
    if (_step == 4) {
      _saveProfile();
      return;
    }
    if (_step == 3 && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() { _step--; _errorMessage = null; });
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, size: 19, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.softBlue.withValues(alpha: 0.14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              BorderSide(color: AppColors.softBlue.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppColors.prestigeMauve, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.prestigeMauve),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppColors.prestigeMauve, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(step: _step + 1, totalSteps: 5),
                      const SizedBox(height: 24),
                      Row(children: [
                        SizedBox(width: 48, child: _step > 0 ? IconButton(onPressed: _back, icon: const Icon(Iconsax.arrow_left_2), color: AppColors.prestigeMauve) : null),
                        Expanded(
                          child: Row(
                            children: List.generate(
                              5,
                              (i) => Expanded(
                                child: Container(
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: i <= _step
                                        ? AppColors.martianGreen
                                        : AppColors.softBlue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ]),
                      const SizedBox(height: 28),
                      Text(['How do you identify?', 'How old are you?', 'Choose your avatar', 'Where are you based?', 'Make it yours'][_step], style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 32, height: 1.1, letterSpacing: -1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(['Choose the option that fits best.', 'This helps us personalize your experience.', 'Pick an avatar for your profile. You can change it later.', 'Choose your country of residence.', 'Your username is generated for you. Add a bio if you like.'][_step], style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.7)),
                      const SizedBox(height: 24),
                      Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: _step == 0
                        ? _ProfileSectionCard(icon: Iconsax.user_tag, title: 'Your gender', subtitle: 'Choose one option', child: Row(children: [
                            Expanded(child: _GenderChoice(label: 'Male', icon: Iconsax.man, value: 'male', selected: _gender == 'male', onSelected: _chooseGender)),
                            const SizedBox(width: 12),
                            Expanded(child: _GenderChoice(label: 'Female', icon: Iconsax.woman, value: 'female', selected: _gender == 'female', onSelected: _chooseGender)),
                          ]))
                        : _step == 1
                          ? _ProfileSectionCard(icon: Iconsax.calendar_1, title: 'Your age', subtitle: 'You must be at least 18 years old.', child: TextFormField(controller: _ageController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)], validator: (value) { final age = int.tryParse(value ?? ''); if (age == null) return 'Enter your age to continue.'; if (age < 18 || age > 120) return 'Enter an age between 18 and 120.'; return null; }, decoration: _inputDecoration(hint: 'Enter your age', icon: Iconsax.calendar_edit, suffix: 'years old')))
                          : _step == 2
                            ? _ProfileSectionCard(icon: Iconsax.user, title: 'Choose your avatar', subtitle: 'Pick an avatar for your profile. You can change it later.', child: _buildAvatarChoices())
                            : _step == 3
                              ? _ProfileSectionCard(icon: Iconsax.global_search, title: 'Where are you based?', subtitle: 'Helps us keep things relevant to you', child: _CountryField(country: _country, onTap: _selectCountry))
                              : _ProfileSectionCard(icon: Iconsax.profile_circle, title: 'Your public profile', subtitle: 'Your username is visible to other people. Bio is optional.', child: Column(children: [
                                  TextFormField(controller: _usernameController, maxLength: 30, validator: (value) { final username = (value ?? '').trim(); if (username.isEmpty) return 'Enter a username.'; if (!RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(username)) return 'Use 3–30 letters, numbers, dots, or underscores.'; return null; }, decoration: _inputDecoration(hint: 'Username', icon: Iconsax.user_edit).copyWith(prefixText: '@')),
                                  const SizedBox(height: 12),
                                  TextFormField(controller: _bioController, maxLength: 250, maxLines: 4, validator: (value) => (value ?? '').length > 250 ? 'Use 250 characters or fewer.' : null, decoration: _inputDecoration(hint: 'A little about you (optional)', icon: Iconsax.text)),
                                ]))))),
                      if (_errorMessage != null) ...[
                        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.prestigeMauve.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.prestigeMauve.withValues(alpha: 0.4))), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w600, height: 1.5))),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(height: 60, child: FilledButton(onPressed: _isSaving ? null : _continue, style: FilledButton.styleFrom(backgroundColor: AppColors.prestigeMauve, foregroundColor: AppColors.softBlue, disabledBackgroundColor: AppColors.prestigeMauve, disabledForegroundColor: AppColors.softBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.softBlue, strokeWidth: 2.4)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_step == 4 ? 'Finish profile' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(width: 10), Icon(_step == 4 ? Iconsax.tick_circle : Iconsax.arrow_right_3, size: 20)]))),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Iconsax.tick_circle, size: 14, color: AppColors.muted), const SizedBox(width: 6), Text('Step ${_step + 1} of 5', style: const TextStyle(color: AppColors.muted, fontSize: 12))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildAvatarChoices() {
    if (_avatarsLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator(color: AppColors.prestigeMauve)));
    }
    if (_avatarError != null) {
      return Column(children: [
        Text(_avatarError!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        TextButton.icon(onPressed: _loadAvatars, icon: const Icon(Iconsax.refresh), label: const Text('Try again')),
      ]);
    }
    if (_avatars.isEmpty) return const Text('No avatar choices are available right now.', style: TextStyle(color: AppColors.muted));
    return Wrap(spacing: 12, runSpacing: 12, children: _avatars.map((avatar) {
      final selected = _selectedAvatar?.id == avatar.id;
      return Semantics(
        button: true,
        selected: selected,
        label: 'Avatar ${_avatars.indexOf(avatar) + 1}',
        child: InkWell(
          onTap: () => setState(() => _selectedAvatar = avatar),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: selected ? AppColors.softBlue.withValues(alpha: 0.4) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.prestigeMauve : AppColors.softBlue, width: selected ? 2 : 1)),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Stack(fit: StackFit.expand, children: [
              Image.memory(_avatarBytes(avatar.imageData), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.softBlue, child: Icon(Iconsax.user, color: AppColors.prestigeMauve))),
              if (selected) const Align(alignment: Alignment.topRight, child: Icon(Iconsax.tick_circle, color: AppColors.prestigeMauve, size: 20)),
            ])),
          ),
        ),
      );
    }).toList());
  }

  Uint8List _avatarBytes(String imageData) {
    final comma = imageData.indexOf(',');
    final encoded = imageData.startsWith('data:') && comma >= 0 ? imageData.substring(comma + 1) : imageData;
    try { return base64Decode(encoded); } on FormatException { return Uint8List(0); }
  }
}
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.prestigeMauve,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.prestigeMauve.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                's',
                style: TextStyle(
                  color: AppColors.martianGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SAYMYMIND',
                  style: TextStyle(
                    color: AppColors.prestigeMauve,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A more personal space',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.orangeYellow.withValues(alpha: 0.32),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.orangeYellow.withValues(alpha: 0.7),
              ),
            ),
            child: Text(
              'STEP $step / $totalSteps',
              style: const TextStyle(
                color: AppColors.prestigeMauve,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      );
}

class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.softBlue.withValues(alpha: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.prestigeMauve.withValues(alpha: 0.02),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: AppColors.prestigeMauve,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.prestigeMauve,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );
}

class _GenderChoice extends StatelessWidget {
  const _GenderChoice({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(value),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: 164,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.martianGreen.withValues(alpha: 0.16)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? AppColors.prestigeMauve
                    : AppColors.softBlue.withValues(alpha: 0.85),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.prestigeMauve.withValues(alpha: 0.10),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.prestigeMauve : AppColors.softBlue.withValues(alpha: 0.36),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icon, size: 30, color: selected ? Colors.white : AppColors.prestigeMauve),
                    ),
                    if (selected)
                      const Icon(Iconsax.tick_circle, size: 23, color: AppColors.prestigeMauve),
                  ],
                ),
                const Spacer(),
                Text(label, style: TextStyle(
                  color: AppColors.prestigeMauve,
                  fontSize: 18,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                )),
                const SizedBox(height: 3),
                Text(selected ? 'Selected' : 'Tap to select', style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
              ],
            ),
          ),
        ),
      );
}

class _CountryField extends StatelessWidget {
  const _CountryField({required this.country, required this.onTap});

  final Country? country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.softBlue.withValues(alpha: 0.95),
              ),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.global, size: 20, color: AppColors.muted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    country?.name ?? 'Select your country',
                    style: TextStyle(
                      color: country == null
                          ? AppColors.muted
                          : AppColors.prestigeMauve,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (country != null) ...[
                  Text(country!.flagEmoji,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                ],
                const Icon(Iconsax.arrow_down_1, size: 18, color: AppColors.muted),
              ],
            ),
          ),
        ),
      );
}

String _generateUsername(String publicId) {
  final safeId = publicId.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  final suffix = safeId.length > 24 ? safeId.substring(0, 24) : safeId;
  return suffix.isEmpty ? 'smm_user' : 'smm_$suffix';
}
