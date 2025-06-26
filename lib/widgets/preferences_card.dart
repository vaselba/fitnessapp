import 'package:flutter/material.dart';
import '../utils/localization.dart';

class PreferencesCard extends StatelessWidget {
  final String selectedLanguage;
  final ValueChanged<String?> onLanguageChanged;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final String selectedFont;
  final ValueChanged<String?> onFontChanged;
  final String chatBubbleStyle;
  final ValueChanged<String?> onChatBubbleStyleChanged;
  final Color chatBackgroundColor;
  final ValueChanged<Color?> onChatBackgroundColorChanged;
  const PreferencesCard({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.selectedFont,
    required this.onFontChanged,
    required this.chatBubbleStyle,
    required this.onChatBubbleStyleChanged,
    required this.chatBackgroundColor,
    required this.onChatBackgroundColorChanged,
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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedFont,
              decoration: InputDecoration(
                labelText: LocalizationUtil.select(
                  language: selectedLanguage,
                  bg: 'Шрифт',
                  en: 'Font',
                ),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                DropdownMenuItem(value: 'OpenSans', child: Text('Open Sans')),
                DropdownMenuItem(value: 'Lato', child: Text('Lato')),
              ],
              onChanged: onFontChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: chatBubbleStyle,
              decoration: InputDecoration(
                labelText: LocalizationUtil.select(
                  language: selectedLanguage,
                  bg: 'Стил на балончетата',
                  en: 'Chat Bubble Style',
                ),
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'rounded', child: Text('Rounded')),
                DropdownMenuItem(value: 'square', child: Text('Square')),
              ],
              onChanged: onChatBubbleStyleChanged,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocalizationUtil.select(
                    language: selectedLanguage,
                    bg: 'Цвят на чата',
                    en: 'Chat Background Color',
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                DropdownButton<Color>(
                  value: chatBackgroundColor,
                  items: [
                    DropdownMenuItem(
                      value: Colors.white,
                      child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.white,
                          margin: const EdgeInsets.all(2)),
                    ),
                    DropdownMenuItem(
                      value: Colors.blue,
                      child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.blue,
                          margin: const EdgeInsets.all(2)),
                    ),
                    DropdownMenuItem(
                      value: Colors.green,
                      child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.green,
                          margin: const EdgeInsets.all(2)),
                    ),
                    DropdownMenuItem(
                      value: Colors.purple,
                      child: Container(
                          width: 24,
                          height: 24,
                          color: Colors.purple,
                          margin: const EdgeInsets.all(2)),
                    ),
                  ],
                  onChanged: onChatBackgroundColorChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
