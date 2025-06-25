import 'package:flutter/material.dart';
import '../utils/validators.dart';
import '../utils/localization.dart';

class ProfileFormCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController weightController;
  final TextEditingController heightController;
  final TextEditingController apiTokenController;
  final String selectedLanguage;
  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback onLogout;

  const ProfileFormCard({
    super.key,
    required this.nameController,
    required this.ageController,
    required this.weightController,
    required this.heightController,
    required this.apiTokenController,
    required this.selectedLanguage,
    required this.formKey,
    required this.isLoading,
    required this.onSave,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: LocalizationUtil.select(
                      language: selectedLanguage, bg: 'Име', en: 'Name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationUtil.select(
                        language: selectedLanguage,
                        bg: 'Моля въведете име',
                        en: 'Please enter your name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: LocalizationUtil.select(
                      language: selectedLanguage, bg: 'Възраст', en: 'Age'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return LocalizationUtil.select(
                        language: selectedLanguage,
                        bg: 'Моля въведете възраст',
                        en: 'Please enter your age');
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 120) {
                    return LocalizationUtil.select(
                        language: selectedLanguage,
                        bg: 'Моля въведете валидна възраст',
                        en: 'Please enter a valid age');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: weightController,
                decoration: InputDecoration(
                  labelText: LocalizationUtil.select(
                      language: selectedLanguage,
                      bg: 'Тегло (кг)',
                      en: 'Weight (kg)'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validateWeight(value,
                    language: selectedLanguage),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: heightController,
                decoration: InputDecoration(
                  labelText: LocalizationUtil.select(
                      language: selectedLanguage,
                      bg: 'Височина (см)',
                      en: 'Height (cm)'),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => Validators.validateHeight(value,
                    language: selectedLanguage),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: apiTokenController,
                decoration: InputDecoration(
                  labelText: 'API Token (Optional)',
                  border: const OutlineInputBorder(),
                  helperText: LocalizationUtil.select(
                      language: selectedLanguage,
                      bg: 'Незадължително: Добавете API токен за AI асистента',
                      en: 'Optional: Add API token for AI assistant'),
                ),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onSave,
                        label: Text(
                          LocalizationUtil.select(
                              language: selectedLanguage,
                              bg: 'Запази',
                              en: 'Save'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: onLogout,
                        label: Text(
                          LocalizationUtil.select(
                              language: selectedLanguage,
                              bg: 'Изход',
                              en: 'Logout'),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
