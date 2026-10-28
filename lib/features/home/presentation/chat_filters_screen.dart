import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';

class ChatFiltersScreen extends StatefulWidget {
  const ChatFiltersScreen({super.key});

  @override
  State<ChatFiltersScreen> createState() => _ChatFiltersScreenState();
}

class _ChatFiltersScreenState extends State<ChatFiltersScreen> {
  static const _languages = [
    'English',
    'Chichewa',
    'Swahili',
    'French',
    'Portuguese',
    'Arabic',
  ];
  static const _interests = [
    'Friendship',
    'Life advice',
    'Music',
    'Relationships',
    'Personal growth',
    'Books',
    'Gaming',
    'Everyday life',
  ];

  String _language = 'English';
  String _gender = 'Anyone';
  RangeValues _ageRange = const RangeValues(18, 35);
  final Set<String> _selectedInterests = {};
  Country? _country;

  void _chooseCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      countryListTheme: CountryListThemeData(
        backgroundColor: Colors.white,
        textStyle: const TextStyle(color: AppColors.prestigeMauve),
        bottomSheetHeight: 560,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        inputDecoration: InputDecoration(
          hintText: 'Search countries',
          prefixIcon: const Icon(Iconsax.search_normal_1, size: 19),
          filled: true,
          fillColor: AppColors.softBlue.withValues(alpha: 0.18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onSelect: (country) => setState(() => _country = country),
    );
  }

  void _showSearchPreview() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Partner search will be connected next.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.martianGreen.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Iconsax.messages_2, color: AppColors.prestigeMauve, size: 23),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Partner preferences',
                      style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find your kind of chat',
                      style: TextStyle(color: AppColors.prestigeMauve, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Choose who you’d like to meet. You can change these filters anytime.',
            style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          _FilterCard(
            title: 'Partner language',
            subtitle: 'Choose the language you’d like to chat in.',
            icon: Iconsax.global,
            child: DropdownButtonFormField<String>(
              value: _language,
              decoration: _dropdownDecoration('Language', Iconsax.message_text_1),
              icon: const Icon(Iconsax.arrow_down_1, size: 17),
              items: _languages
                  .map((language) => DropdownMenuItem(value: language, child: Text(language)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _language = value);
              },
            ),
          ),
          const SizedBox(height: 14),
          _FilterCard(
            title: 'Gender',
            subtitle: 'Who would you like to talk with?',
            icon: Iconsax.user,
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              children: ['Anyone', 'Men', 'Women'].map((gender) {
                final selected = _gender == gender;
                return ChoiceChip(
                  label: Text(gender),
                  selected: selected,
                  onSelected: (_) => setState(() => _gender = gender),
                  selectedColor: AppColors.martianGreen.withValues(alpha: 0.38),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.prestigeMauve : AppColors.softBlue,
                  ),
                  labelStyle: TextStyle(
                    color: AppColors.prestigeMauve,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _FilterCard(
            title: 'Age range',
            subtitle: 'Choose the age range you’re comfortable with.',
            icon: Iconsax.calendar_1,
            trailing: Text(
              '${_ageRange.start.round()}–${_ageRange.end.round()}',
              style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            child: Column(
              children: [
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 65,
                  divisions: 47,
                  activeColor: AppColors.prestigeMauve,
                  inactiveColor: AppColors.softBlue,
                  labels: RangeLabels(
                    _ageRange.start.round().toString(),
                    _ageRange.end.round().toString(),
                  ),
                  onChanged: (range) => setState(() => _ageRange = range),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('18 years', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text('65 years', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _FilterCard(
            title: 'Interests',
            subtitle: 'Pick a few things you enjoy talking about.',
            icon: Iconsax.heart,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interests.map((interest) {
                final selected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value) {
                      _selectedInterests.add(interest);
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  }),
                  selectedColor: AppColors.softBlue.withValues(alpha: 0.5),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected ? AppColors.prestigeMauve : AppColors.softBlue,
                  ),
                  checkmarkColor: AppColors.prestigeMauve,
                  labelStyle: const TextStyle(color: AppColors.prestigeMauve, fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          _FilterCard(
            title: 'Country',
            subtitle: 'Meet someone nearby or open it up.',
            icon: Iconsax.location,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chooseCountry,
                    icon: Icon(_country == null ? Iconsax.global : Iconsax.location, size: 18),
                    label: Text(
                      _country == null ? 'Any country' : '${_country!.flagEmoji}  ${_country!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.prestigeMauve,
                      side: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.9)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                if (_country != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Clear country',
                    onPressed: () => setState(() => _country = null),
                    icon: const Icon(Iconsax.close_circle, size: 19),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.prestigeMauve,
                      backgroundColor: AppColors.softBlue.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _showSearchPreview,
              icon: const Icon(Iconsax.search_normal_1, size: 20),
              label: const Text('Find a chat partner', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.prestigeMauve,
                foregroundColor: AppColors.softBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      );

  InputDecoration _dropdownDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.softBlue.withValues(alpha: 0.12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppColors.softBlue.withValues(alpha: 0.8)),
        ),
      );
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(21),
          border: Border.all(color: AppColors.softBlue.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: AppColors.prestigeMauve.withValues(alpha: 0.025),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue.withValues(alpha: 0.26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.prestigeMauve, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: AppColors.prestigeMauve, fontSize: 15, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.35)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      );
}
