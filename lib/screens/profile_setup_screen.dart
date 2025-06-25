import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../main.dart';

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
  String _selectedLanguage = 'Български';
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
                _selectedLanguage == 'Български'
                    ? 'Моля влезте отново в профила си'
                    : 'Please sign in again',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final profile = UserProfile(
        uid: user.uid,
        name: _nameController.text,
        preferredLanguage: _selectedLanguage,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        apiToken: _apiTokenController.text.isEmpty ? null : _apiTokenController.text,
        fitnessGoal: _selectedFitnessGoal,
        workoutsPerWeek: _workoutsPerWeek,
        experienceLevel: _experienceLevel,
        preferredWorkouts: _selectedWorkouts.isEmpty ? null : _selectedWorkouts,
        healthConditions: _healthConditionsController.text.isEmpty ? null : _healthConditionsController.text,
      );

      try {
        await profile.save();
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                title: 'Fitnessa',
                language: _selectedLanguage,
                onLanguageChanged: (lang) {}, // You can pass a real callback if needed
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
            errorMessage = _selectedLanguage == 'Български'
                ? 'Нямате разрешение за запазване на профила'
                : 'You don\'t have permission to save the profile';
            break;
          case 'unavailable':
            errorMessage = _selectedLanguage == 'Български'
                ? 'Грешка в мрежовата връзка'
                : 'Network connection error';
            break;
          case 'timeout':
            errorMessage = _selectedLanguage == 'Български'
                ? 'Времето за изчакване изтече'
                : 'Connection timeout';
            break;
          case 'unauthenticated':
            errorMessage = _selectedLanguage == 'Български'
                ? 'Моля влезте отново в профила си'
                : 'Please sign in again';
            break;
          default:
            errorMessage = _selectedLanguage == 'Български'
                ? 'Грешка при запазване на профила: ${e.message}'
                : 'Error saving profile: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedLanguage == 'Български'
                  ? 'Неочаквана грешка при запазване на профила'
                  : 'Unexpected error saving profile',
            ),
            backgroundColor: Colors.red,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == 'Български' ? 'Създай профил' : 'Create Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            tooltip: _selectedLanguage == 'Български' ? 'Изход' : 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButton<String>(
                value: _selectedLanguage,
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
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: _selectedLanguage == 'Български' ? 'Име' : 'Name',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете име'
                        : 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: _selectedLanguage == 'Български' ? 'Възраст' : 'Age',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете възраст'
                        : 'Please enter your age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 0 || age > 120) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете валидна възраст'
                        : 'Please enter a valid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: _selectedLanguage == 'Български' ? 'Тегло (кг)' : 'Weight (kg)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете тегло'
                        : 'Please enter your weight';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0 || weight > 300) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете валидно тегло'
                        : 'Please enter a valid weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: _selectedLanguage == 'Български' ? 'Височина (см)' : 'Height (cm)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете височина'
                        : 'Please enter your height';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0 || height > 300) {
                    return _selectedLanguage == 'Български'
                        ? 'Моля въведете валидна височина'
                        : 'Please enter a valid height';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiTokenController,
                decoration: InputDecoration(
                  labelText: 'API Token (Optional)',
                  border: const OutlineInputBorder(),
                  helperText: _selectedLanguage == 'Български'
                      ? 'Незадължително: Добавете API токен за AI асистента'
                      : 'Optional: Add API token for AI assistant',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _selectedLanguage == 'Български' 
                    ? 'Фитнес информация'
                    : 'Fitness Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedFitnessGoal,
                decoration: InputDecoration(
                  labelText: _selectedLanguage == 'Български' 
                      ? 'Каква е вашата цел?' 
                      : 'What is your fitness goal?',
                  border: const OutlineInputBorder(),
                ),
                items: <String>['lose_weight', 'build_muscle', 'improve_endurance', 'general_fitness']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(_selectedLanguage == 'Български'
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
                    return _selectedLanguage == 'Български'
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
                      _selectedLanguage == 'Български'
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
                  labelText: _selectedLanguage == 'Български'
                      ? 'Ниво на опит'
                      : 'Experience Level',
                  border: const OutlineInputBorder(),
                ),
                items: <String>['beginner', 'intermediate', 'advanced']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(_selectedLanguage == 'Български'
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
                _selectedLanguage == 'Български'
                    ? 'Предпочитани видове тренировки:'
                    : 'Preferred workout types:',
              ),
              Wrap(
                spacing: 8.0,
                children: _availableWorkouts.map((workout) {
                  return FilterChip(
                    label: Text(_selectedLanguage == 'Български'
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
                  labelText: _selectedLanguage == 'Български'
                      ? 'Здравословни състояния (по избор)'
                      : 'Health Conditions (optional)',
                  helperText: _selectedLanguage == 'Български'
                      ? 'Споделете всякакви здравословни проблеми, които трябва да се вземат предвид'
                      : 'Share any health conditions that should be considered',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(
                  _selectedLanguage == 'Български' ? 'Запази' : 'Save',
                ),
              ),
            ],
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