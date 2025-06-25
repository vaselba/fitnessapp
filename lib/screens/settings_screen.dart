import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user_profile.dart';
import '../models/activity.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;
  final Function(String) onLanguageChanged;
  final String currentLanguage;
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
    required this.onLanguageChanged,
    required this.currentLanguage,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _apiTokenController;
  late String _selectedLanguage;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Mock activity data for demonstration
  final List<Activity> _recentActivities = [
    Activity(date: DateTime.now().subtract(const Duration(days: 1)), type: 'Cardio', durationMinutes: 30, calories: 200),
    Activity(date: DateTime.now().subtract(const Duration(days: 2)), type: 'Strength', durationMinutes: 45, calories: 300),
    Activity(date: DateTime.now().subtract(const Duration(days: 3)), type: 'Yoga', durationMinutes: 20, calories: 80),
    Activity(date: DateTime.now().subtract(const Duration(days: 4)), type: 'HIIT', durationMinutes: 25, calories: 180),
    Activity(date: DateTime.now().subtract(const Duration(days: 5)), type: 'Running', durationMinutes: 40, calories: 350),
  ];

  List<double> get _weeklyMinutes {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: i));
      return _recentActivities
          .where((a) => a.date.year == day.year && a.date.month == day.month && a.date.day == day.day)
          .fold(0.0, (sum, a) => sum + a.durationMinutes);
    }).reversed.toList();
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _ageController = TextEditingController(text: widget.userProfile.age.toString());
    _weightController = TextEditingController(text: widget.userProfile.weight.toString());
    _heightController = TextEditingController(text: widget.userProfile.height.toString());
    _apiTokenController = TextEditingController(text: widget.userProfile.apiToken ?? '');
    _selectedLanguage = widget.currentLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _apiTokenController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = widget.userProfile.copyWith(
        name: _nameController.text,
        preferredLanguage: _selectedLanguage,
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        apiToken: _apiTokenController.text.isEmpty ? null : _apiTokenController.text,
      );

      await updatedProfile.save();
      
      if (!mounted) return;  // Add mounted check before using context
      
      widget.onProfileUpdated(updatedProfile);
      widget.onLanguageChanged(_selectedLanguage);
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
          // In case of authentication error, sign out the user
          await FirebaseAuth.instance.signOut();
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedLanguage == 'Български'
                ? 'Грешка при изход от профила'
                : 'Error logging out',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLanguage == 'Български' ? 'Настройки' : 'Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
              // Activity & Progress Overview
              Text(_selectedLanguage == 'Български' ? 'Активност и напредък' : 'Activity & Progress',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Text(days[value.toInt() % 7]);
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(_weeklyMinutes.length, (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _weeklyMinutes[i],
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    )),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_selectedLanguage == 'Български' ? 'Последни активности' : 'Recent Activities',
                  style: Theme.of(context).textTheme.titleMedium),
              ..._recentActivities.map((a) => ListTile(
                    leading: Icon(Icons.fitness_center),
                    title: Text('${a.type} - ${a.durationMinutes.toInt()} min'),
                    subtitle: Text('${a.date.month}/${a.date.day}/${a.date.year}'),
                    trailing: a.calories != null ? Text('${a.calories!.toInt()} kcal') : null,
                  )),
              const Divider(height: 32),
              // Theme toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedLanguage == 'Български' ? 'Тъмен режим' : 'Dark Mode',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Switch(
                    value: widget.isDarkMode ?? false,
                    onChanged: (value) {
                      if (widget.onToggleTheme != null) {
                        widget.onToggleTheme!(value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text(
                        _selectedLanguage == 'Български' ? 'Запази' : 'Save',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _selectedLanguage == 'Български' ? 'Изход' : 'Logout',
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