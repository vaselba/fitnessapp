import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../widgets/settings_header.dart';
import '../widgets/preferences_card.dart';
import '../widgets/profile_form_card.dart';
import '../utils/debouncer.dart';
import '../state/app_state.dart';
import '../utils/app_logger.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;
  final String currentLanguage;
  final void Function(bool)? onToggleTheme;
  final bool? isDarkMode;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final Debouncer _debouncer = Debouncer(milliseconds: 400);
  String _selectedFont = 'Roboto';
  String _chatBubbleStyle = 'rounded';
  Color _chatBackgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    AppLogger.log('SettingsScreen initialized', level: LogLevel.info);
    _nameController = TextEditingController(text: widget.userProfile.name);
    _ageController =
        TextEditingController(text: widget.userProfile.age.toString());
    _weightController =
        TextEditingController(text: widget.userProfile.weight.toString());
    _heightController =
        TextEditingController(text: widget.userProfile.height.toString());
    _apiTokenController =
        TextEditingController(text: widget.userProfile.apiToken ?? '');
    // Optionally: Load saved preferences for font, bubble style, color here
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _apiTokenController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    AppLogger.log('Attempting to update profile', level: LogLevel.info);
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = widget.userProfile.copyWith(
        name: _nameController.text,
        preferredLanguage: Provider.of<AppState>(context, listen: false)
            .language, // Use AppState language
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        apiToken:
            _apiTokenController.text.isEmpty ? null : _apiTokenController.text,
      );

      await updatedProfile.save();
      AppLogger.log('Profile updated successfully', level: LogLevel.info);
      if (!mounted) return;
      widget.onProfileUpdated(updatedProfile);
      // Removed language change callback, as it's now handled by AppState
    } on FirebaseException catch (e) {
      AppLogger.log('FirebaseException during profile update: \\${e.code}', level: LogLevel.error, error: e);
      if (!mounted) return;
      String errorMessage;
      switch (e.code) {
        case 'permission-denied':
          errorMessage =
              Provider.of<AppState>(context, listen: false).language ==
                      'Български'
                  ? 'Нямате разрешение за запазване на профила'
                  : 'You don\'t have permission to save the profile';
          break;
        case 'unavailable':
          errorMessage =
              Provider.of<AppState>(context, listen: false).language ==
                      'Български'
                  ? 'Грешка в мрежовата връзка'
                  : 'Network connection error';
          break;
        case 'timeout':
          errorMessage =
              Provider.of<AppState>(context, listen: false).language ==
                      'Български'
                  ? 'Времето за изчакване изтече'
                  : 'Connection timeout';
          break;
        case 'unauthenticated':
          errorMessage =
              Provider.of<AppState>(context, listen: false).language ==
                      'Български'
                  ? 'Моля влезте отново в профила си'
                  : 'Please sign in again';
          await FirebaseAuth.instance.signOut();
          AppLogger.log('User signed out due to unauthenticated error', level: LogLevel.warning);
          break;
        default:
          errorMessage =
              Provider.of<AppState>(context, listen: false).language ==
                      'Български'
                  ? 'Грешка при запазване на профила: e.message}'
                  : 'Error saving profile: ${e.message}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      AppLogger.log('Unknown error during profile update', level: LogLevel.error, error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<AppState>(context, listen: false).language ==
                    'Български'
                ? 'Възникна неочаквана грешка'
                : 'An unexpected error occurred',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Provider.of<AppState>(context, listen: false).language ==
                'Български'
            ? 'Потвърждение'
            : 'Confirmation'),
        content: Text(Provider.of<AppState>(context, listen: false).language ==
                'Български'
            ? 'Сигурни ли сте, че искате да излезете?'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
                Provider.of<AppState>(context, listen: false).language ==
                        'Български'
                    ? 'Отказ'
                    : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
                Provider.of<AppState>(context, listen: false).language ==
                        'Български'
                    ? 'Изход'
                    : 'Logout'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<AppState>(context, listen: false).language ==
                    'Български'
                ? 'Грешка при изход от профила'
                : 'Error logging out',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text(appState.language == 'Български' ? 'Настройки' : 'Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: appState.language == 'Български' ? 'Изход' : 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with avatar and name
              SettingsHeader(
                name: _nameController.text,
                language: appState.language,
              ),
              const SizedBox(height: 24),
              // Preferences Section
              Text(
                  appState.language == 'Български'
                      ? 'Предпочитания'
                      : 'Preferences',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              PreferencesCard(
                selectedLanguage: appState.language,
                onLanguageChanged: (String? newValue) {
                  if (newValue != null) {
                    appState.setLanguage(newValue);
                  }
                },
                isDarkMode: appState.isDarkMode,
                onToggleTheme: (value) {
                  appState.setDarkMode(value);
                },
                selectedFont: _selectedFont,
                onFontChanged: (String? newFont) {
                  if (newFont != null) {
                    setState(() {
                      _selectedFont = newFont;
                    });
                  }
                },
                chatBubbleStyle: _chatBubbleStyle,
                onChatBubbleStyleChanged: (String? newStyle) {
                  if (newStyle != null) {
                    setState(() {
                      _chatBubbleStyle = newStyle;
                    });
                  }
                },
                chatBackgroundColor: _chatBackgroundColor,
                onChatBackgroundColorChanged: (Color? newColor) {
                  if (newColor != null) {
                    setState(() {
                      _chatBackgroundColor = newColor;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              // Profile Section
              Text(appState.language == 'Български' ? 'Профил' : 'Profile',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ProfileFormCard(
                nameController: _nameController,
                ageController: _ageController,
                weightController: _weightController,
                heightController: _heightController,
                apiTokenController: _apiTokenController,
                selectedLanguage: appState.language,
                formKey: _formKey,
                isLoading: _isLoading,
                onSave: _updateProfile,
                onLogout: _logout,
                // Replace all validator: (value) {...} with e.g.:
                // validator: (value) => Validators.validateAge(value, language: appState.language),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
