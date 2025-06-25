import 'package:flutter/material.dart';
import '../utils/localization.dart';

class SettingsHeader extends StatelessWidget {
  final String name;
  final String language;
  const SettingsHeader({super.key, required this.name, required this.language});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 51),
              child: Icon(Icons.person,
                  size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                name.isNotEmpty
                    ? name
                    : LocalizationUtil.select(
                        language: language, bg: 'Потребител', en: 'User'),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
