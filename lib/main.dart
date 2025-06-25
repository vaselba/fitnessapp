import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// To use your own Firebase config, copy lib/firebase_options.template.dart to lib/firebase_options.dart and fill in your values.
// Do NOT commit lib/firebase_options.dart to git.
import 'firebase_options.dart';
import 'models/user_profile.dart';
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

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
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
            ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;
  const AuthWrapper({super.key, this.onToggleTheme, this.isDarkMode});

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
  const ProfileCheck({super.key, this.onToggleTheme, this.isDarkMode});

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
          );
        }
        return const ProfileSetupScreen();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {super.key, required this.title, this.onToggleTheme, this.isDarkMode});
  final String title;
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  String _language = 'Български';
  final LLMService _llmService = LLMService();

  @override
  void initState() {
    super.initState();
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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        // Home screen
        return Center(
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
              ] else
                const CircularProgressIndicator(),
            ],
          ),
        );

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
