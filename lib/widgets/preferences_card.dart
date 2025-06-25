import 'package:flutter/material.dart';
import '../utils/localization.dart';

class PreferencesCard extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  const PreferencesCard({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocalizationUtil.select(
                    language: selectedLanguage,
                    bg: 'Тъмен режим',
                    en: 'Dark Mode',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Switch(
                  value: isDarkMode,
                  onChanged: onToggleTheme,
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedLanguage,
              decoration: InputDecoration(
                labelText: LocalizationUtil.select(
                  language: selectedLanguage,
                  bg: 'Език',
                  en: 'Language',
                ),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Български',
                  child: Text('Български'),
                ),
                DropdownMenuItem(
                  value: 'English',
                  child: Text('English'),
                ),
              ],
              onChanged: onLanguageChanged,
            ),
          ],
        ),
      ),
    );
  }
}
