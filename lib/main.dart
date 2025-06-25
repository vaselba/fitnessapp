import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
// To use your own Firebase config, copy lib/firebase_options.template.dart to lib/firebase_options.dart and fill in your values.
// Do NOT commit lib/firebase_options.dart to git.
import 'firebase_options.dart';
import 'models/user_profile.dart';
import 'models/activity.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/llm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final showOnboarding = await shouldShowOnboarding();
  runApp(MyApp(showOnboarding: showOnboarding));
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;
  const MyApp({super.key, this.showOnboarding = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  late bool _showOnboarding;
  String _language = 'Български';

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _loadThemePreference();
    _loadLanguagePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'Български';
    setState(() {
      _language = lang;
    });
  }

  Future<void> _setLanguage(String lang) async {
    setState(() {
      _language = lang;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  Future<void> _toggleTheme(bool isDark) async {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  void _finishOnboarding() async {
    await setOnboardingComplete();
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitnessa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 152, 11, 196)),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 152, 11, 196),
            brightness: Brightness.dark),
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode,
      home: _showOnboarding
          ? OnboardingScreen(
              onFinish: _finishOnboarding,
            )
          : AuthWrapper(
              onToggleTheme: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
              language: _language,
              onLanguageChanged: _setLanguage,
            ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;
  final String language;
  final void Function(String) onLanguageChanged;
  const AuthWrapper({super.key, this.onToggleTheme, this.isDarkMode, required this.language, required this.onLanguageChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return ProfileCheck(
            onToggleTheme: onToggleTheme,
            isDarkMode: isDarkMode,
            language: language,
            onLanguageChanged: onLanguageChanged,
          );
        }
        return const LoginScreen();
      },
    );
  }
}

class ProfileCheck extends StatelessWidget {
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;
  final String language;
  final void Function(String) onLanguageChanged;
  const ProfileCheck({super.key, this.onToggleTheme, this.isDarkMode, required this.language, required this.onLanguageChanged});

  Future<bool> _hasProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.data == true) {
          return MyHomePage(
            title: 'Fitnessa',
            onToggleTheme: onToggleTheme,
            isDarkMode: isDarkMode,
            language: language,
            onLanguageChanged: onLanguageChanged,
          );
        }
        return const ProfileSetupScreen();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.title, this.onToggleTheme, this.isDarkMode, required this.language, required this.onLanguageChanged});
  final String title;
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;
  final String language;
  final void Function(String) onLanguageChanged;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  late String _language;
  final LLMService _llmService = LLMService();

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
    _language = widget.language;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserProfile.getCurrentUserProfile();
      if (profile != null) {
        setState(() {
          _userProfile = profile;
          _language = profile.preferredLanguage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onProfileUpdated(UserProfile updatedProfile) {
    setState(() {
      _userProfile = updatedProfile;
      _language = updatedProfile.preferredLanguage;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _language == 'Български'
              ? 'Профилът е обновен успешно'
              : 'Profile updated successfully',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _onLanguageChanged(String newLanguage) {
    setState(() {
      _language = newLanguage;
    });
    widget.onLanguageChanged(newLanguage);
  }

  Widget _buildProfileScreen() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_userProfile != null) ...[
              Text(
                '${_language == 'Български' ? 'Здравей' : 'Hello'}, ${_userProfile?.name}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Text(
                '${_language == 'Български' ? 'Възраст' : 'Age'}: ${_userProfile?.age}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '${_language == 'Български' ? 'Тегло' : 'Weight'}: ${_userProfile?.weight} kg',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                '${_language == 'Български' ? 'Височина' : 'Height'}: ${_userProfile?.height} cm',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(_language == 'Български' ? 'Активност и напредък' : 'Activity & Progress',
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
              Text(_language == 'Български' ? 'Последни активности' : 'Recent Activities',
                  style: Theme.of(context).textTheme.titleMedium),
              ..._recentActivities.map((a) => ListTile(
                    leading: Icon(Icons.fitness_center),
                    title: Text('${a.type} - ${a.durationMinutes.toInt()} min'),
                    subtitle: Text('${a.date.month}/${a.date.day}/${a.date.year}'),
                    trailing: a.calories != null ? Text('${a.calories!.toInt()} kcal') : null,
                  )),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        // Home/Profile screen
        return _buildProfileScreen();
      case 1:
        // AI Assistant screen
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ChatScreen(
            language: _language,
            llmService: _llmService,
          ),
        );

      case 2:
        // Settings screen
        return _userProfile == null
            ? const Center(child: CircularProgressIndicator())
            : SettingsScreen(
                userProfile: _userProfile!,
                onProfileUpdated: _onProfileUpdated,
                onLanguageChanged: _onLanguageChanged,
                currentLanguage: _language,
                onToggleTheme: widget.onToggleTheme,
                isDarkMode: widget.isDarkMode,
              );

      default:
        return const Center(child: Text('Something went wrong'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          _language == 'Български' ? 'Фитнес асистент' : 'Fitness Assistant',
        ),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  widget.isDarkMode ?? false
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                  color: widget.isDarkMode ?? false
                      ? Colors.amber[200]
                      : Colors.amber[800],
                  size: 22,
                ),
                Switch(
                  value: widget.isDarkMode ?? false,
                  onChanged: (value) {
                    if (widget.onToggleTheme != null) {
                      widget.onToggleTheme!(value);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.secondary,
                  inactiveThumbColor: Theme.of(context).colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: Text(
              _language == 'Български' ? 'Изход' : 'Logout',
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _language == 'Български'
                          ? 'Грешка при изход от профила'
                          : 'Error logging out',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: _language == 'Български' ? 'Начало' : 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy),
            label: _language == 'Български' ? 'AI Асистент' : 'AI Assistant',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: _language == 'Български' ? 'Настройки' : 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
