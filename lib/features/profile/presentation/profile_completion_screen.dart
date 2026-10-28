import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

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
  final _profileRepository = ProfileRepository();
  late Country? _country = _detectDeviceCountry();
  String? _gender;
  String? _errorMessage;
  bool _isSaving = false;
  int _step = 0;

  Country? _detectDeviceCountry() {
    final code = ui.PlatformDispatcher.instance.locale.countryCode;
    if (code == null || code.isEmpty) return null;
    return CountryService().findByCode(code);
  }

  @override
  void dispose() {
    _ageController.dispose();
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
    if (_step == 2) {
      _saveProfile();
      return;
    }
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
                      const _ProfileHeader(),
                      const SizedBox(height: 24),
                      Row(children: [
                        SizedBox(width: 48, child: _step > 0 ? IconButton(onPressed: _back, icon: const Icon(Iconsax.arrow_left_2), color: AppColors.prestigeMauve) : null),
                        Expanded(
                          child: Row(
                            children: List.generate(
                              3,
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
                      Text(['How do you identify?', 'How old are you?', 'Where are you based?'][_step], style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 32, height: 1.1, letterSpacing: -1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Text(['Choose the option that fits best.', 'This helps us personalize your experience.', 'Choose your country of residence.'][_step], style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.7)),
                      const SizedBox(height: 24),
                      Expanded(child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: _step == 0
                        ? _ProfileSectionCard(icon: Iconsax.user_tag, title: 'Your gender', subtitle: 'Choose one option', child: Row(children: [
                            Expanded(child: _GenderChoice(label: 'Male', icon: Iconsax.user, value: 'male', selected: _gender == 'male', onSelected: _chooseGender)),
                            const SizedBox(width: 12),
                            Expanded(child: _GenderChoice(label: 'Female', icon: Iconsax.profile_circle, value: 'female', selected: _gender == 'female', onSelected: _chooseGender)),
                          ]))
                        : _step == 1
                          ? _ProfileSectionCard(icon: Iconsax.calendar_1, title: 'Your age', subtitle: 'Tell us a little about you', child: TextFormField(controller: _ageController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)], validator: (value) { final age = int.tryParse(value ?? ''); if (age == null) return 'Enter your age to continue.'; if (age < 13 || age > 120) return 'Enter an age between 13 and 120.'; return null; }, decoration: _inputDecoration(hint: 'Enter your age', icon: Iconsax.calendar_edit, suffix: 'years old')))
                          : Column(children: [
                              _ProfileSectionCard(icon: Iconsax.global_search, title: 'Where are you based?', subtitle: 'Helps us keep things relevant to you', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_CountryField(country: _country, onTap: _selectCountry), const SizedBox(height: 10), Row(children: [const Icon(Iconsax.location, size: 14, color: AppColors.muted), const SizedBox(width: 6), Expanded(child: Text(_country == null ? 'Choose your country to continue.' : 'Suggested from your device region. Tap to change.', style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)))])])),
                              const SizedBox(height: 16),
                              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.softBlue.withValues(alpha: 0.26), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.9))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Iconsax.shield_tick, size: 20, color: AppColors.prestigeMauve), SizedBox(width: 12), Expanded(child: Text('Country comes from your device region setting, not GPS. You can update this anytime.', style: TextStyle(color: AppColors.darkGreen, fontSize: 13, height: 1.6)))])),
                            ])))),
                      if (_errorMessage != null) ...[
                        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: AppColors.prestigeMauve.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.prestigeMauve.withValues(alpha: 0.4))), child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.prestigeMauve, fontWeight: FontWeight.w600, height: 1.5))),
                        const SizedBox(height: 12),
                      ],
                      SizedBox(height: 60, child: FilledButton(onPressed: _isSaving ? null : _continue, style: FilledButton.styleFrom(backgroundColor: AppColors.prestigeMauve, foregroundColor: AppColors.softBlue, disabledBackgroundColor: AppColors.prestigeMauve, disabledForegroundColor: AppColors.softBlue, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: _isSaving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.softBlue, strokeWidth: 2.4)) : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(_step == 2 ? 'Finish profile' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(width: 10), Icon(_step == 2 ? Iconsax.tick_circle : Iconsax.arrow_right_3, size: 20)]))),
                      const SizedBox(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Iconsax.tick_circle, size: 14, color: AppColors.muted), const SizedBox(width: 6), Text('Step ${_step + 1} of 3', style: const TextStyle(color: AppColors.muted, fontSize: 12))]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

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
            child: const Text(
              'STEP 2 / 2',
              style: TextStyle(
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
