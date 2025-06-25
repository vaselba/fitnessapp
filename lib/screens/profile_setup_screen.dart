import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../utils/validators.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _healthConditionsController = TextEditingController();
  String? _selectedFitnessGoal;
  int _workoutsPerWeek = 3;
  String _experienceLevel = 'beginner';
  final List<String> _selectedWorkouts = [];

  final List<String> _availableWorkouts = [
    'cardio',
    'strength',
    'yoga',
    'hiit',
    'pilates',
    'running',
    'swimming'
  ];

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please sign in again',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final profile = UserProfile(
        uid: user.uid,
        name: _nameController.text,
        preferredLanguage: 'Български',
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        apiToken:
            _apiTokenController.text.isEmpty ? null : _apiTokenController.text,
        fitnessGoal: _selectedFitnessGoal,
        workoutsPerWeek: _workoutsPerWeek,
        experienceLevel: _experienceLevel,
        preferredWorkouts: _selectedWorkouts.isEmpty ? null : _selectedWorkouts,
        healthConditions: _healthConditionsController.text.isEmpty
            ? null
            : _healthConditionsController.text,
      );

      try {
        await profile.save();

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: 'Fitnessa',
                language: 'Български',
                onLanguageChanged:
                    (lang) {}, // You can pass a real callback if needed
                // Pass other required parameters if needed
              ),
            ),
          );
        }
      } on FirebaseException catch (e) {
        if (!mounted) return;

        String errorMessage;
        switch (e.code) {
          case 'permission-denied':
            errorMessage = 'You don\'t have permission to save the profile';
            break;
          case 'unavailable':
            errorMessage = 'Network connection error';
            break;
          case 'timeout':
            errorMessage = 'Connection timeout';
            break;
          case 'unauthenticated':
            errorMessage = 'Please sign in again';
            break;
          default:
            errorMessage = 'Error saving profile: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unexpected error saving profile',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _apiTokenController.dispose();
    _healthConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appState.language == 'Български'
            ? 'Създай профил'
            : 'Create Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: appState.language == 'Български' ? 'Изход' : 'Logout',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 38),
              Colors.white
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header with icon and welcome
                  CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 38),
                    child: Icon(Icons.account_circle,
                        size: 48, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appState.language == 'Български'
                        ? 'Добре дошли!'
                        : 'Welcome!',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.language == 'Български'
                        ? 'Създайте своя профил'
                        : 'Create your profile',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButton<String>(
                              value: appState.language,
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
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  appState.setLanguage(newValue);
                                  setState(
                                      () {}); // To update local UI if needed
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appState.language == 'Български'
                                  ? 'Лични данни'
                                  : 'Personal Info',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Име'
                                    : 'Name',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) => Validators.validateName(
                                  value,
                                  language: appState.language),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Възраст'
                                    : 'Age',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.validateAge(
                                  value,
                                  language: appState.language),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Тегло (кг)'
                                    : 'Weight (kg)',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.validateWeight(
                                  value,
                                  language: appState.language),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _heightController,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Височина (см)'
                                    : 'Height (cm)',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => Validators.validateHeight(
                                  value,
                                  language: appState.language),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _apiTokenController,
                              decoration: InputDecoration(
                                labelText: 'API Token (Optional)',
                                border: const OutlineInputBorder(),
                                helperText: appState.language == 'Български'
                                    ? 'Незадължително: Добавете API токен за AI асистента'
                                    : 'Optional: Add API token for AI assistant',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              appState.language == 'Български'
                                  ? 'Фитнес информация'
                                  : 'Fitness Information',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _selectedFitnessGoal,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Каква е вашата цел?'
                                    : 'What is your fitness goal?',
                                border: const OutlineInputBorder(),
                              ),
                              items: <String>[
                                'lose_weight',
                                'build_muscle',
                                'improve_endurance',
                                'general_fitness'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(appState.language == 'Български'
                                      ? _getGoalTextBg(value)
                                      : _getGoalTextEn(value)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFitnessGoal = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return appState.language == 'Български'
                                      ? 'Моля изберете цел'
                                      : 'Please select a goal';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    appState.language == 'Български'
                                        ? 'Тренировки на седмица: $_workoutsPerWeek'
                                        : 'Workouts per week: $_workoutsPerWeek',
                                  ),
                                ),
                                Slider(
                                  value: _workoutsPerWeek.toDouble(),
                                  min: 1,
                                  max: 7,
                                  divisions: 6,
                                  label: _workoutsPerWeek.toString(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _workoutsPerWeek = value.round();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _experienceLevel,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Ниво на опит'
                                    : 'Experience Level',
                                border: const OutlineInputBorder(),
                              ),
                              items: <String>[
                                'beginner',
                                'intermediate',
                                'advanced'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(appState.language == 'Български'
                                      ? _getExperienceLevelBg(value)
                                      : _getExperienceLevelEn(value)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _experienceLevel = newValue;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              appState.language == 'Български'
                                  ? 'Предпочитани видове тренировки:'
                                  : 'Preferred workout types:',
                            ),
                            Wrap(
                              spacing: 8.0,
                              children: _availableWorkouts.map((workout) {
                                return FilterChip(
                                  label: Text(appState.language == 'Български'
                                      ? _getWorkoutTypeBg(workout)
                                      : _getWorkoutTypeEn(workout)),
                                  selected: _selectedWorkouts.contains(workout),
                                  onSelected: (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedWorkouts.add(workout);
                                      } else {
                                        _selectedWorkouts.remove(workout);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _healthConditionsController,
                              decoration: InputDecoration(
                                labelText: appState.language == 'Български'
                                    ? 'Здравословни състояния (по избор)'
                                    : 'Health Conditions (optional)',
                                helperText: appState.language == 'Български'
                                    ? 'Споделете всякакви здравословни проблеми, които трябва да се вземат предвид'
                                    : 'Share any health conditions that should be considered',
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: _saveProfile,
                              label: Text(
                                appState.language == 'Български'
                                    ? 'Запази'
                                    : 'Save',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getGoalTextEn(String value) {
    switch (value) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'build_muscle':
        return 'Build Muscle';
      case 'improve_endurance':
        return 'Improve Endurance';
      case 'general_fitness':
        return 'General Fitness';
      default:
        return value;
    }
  }

  String _getGoalTextBg(String value) {
    switch (value) {
      case 'lose_weight':
        return 'Отслабване';
      case 'build_muscle':
        return 'Натрупване на мускулна маса';
      case 'improve_endurance':
        return 'Подобряване на издръжливостта';
      case 'general_fitness':
        return 'Обща физическа форма';
      default:
        return value;
    }
  }

  String _getExperienceLevelEn(String value) {
    switch (value) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return value;
    }
  }

  String _getExperienceLevelBg(String value) {
    switch (value) {
      case 'beginner':
        return 'Начинаещ';
      case 'intermediate':
        return 'Средно ниво';
      case 'advanced':
        return 'Напреднал';
      default:
        return value;
    }
  }

  String _getWorkoutTypeEn(String value) {
    switch (value) {
      case 'cardio':
        return 'Cardio';
      case 'strength':
        return 'Strength Training';
      case 'yoga':
        return 'Yoga';
      case 'hiit':
        return 'HIIT';
      case 'pilates':
        return 'Pilates';
      case 'running':
        return 'Running';
      case 'swimming':
        return 'Swimming';
      default:
        return value;
    }
  }

  String _getWorkoutTypeBg(String value) {
    switch (value) {
      case 'cardio':
        return 'Кардио';
      case 'strength':
        return 'Силови тренировки';
      case 'yoga':
        return 'Йога';
      case 'hiit':
        return 'HIIT';
      case 'pilates':
        return 'Пилатес';
      case 'running':
        return 'Бягане';
      case 'swimming':
        return 'Плуване';
      default:
        return value;
    }
  }
}
