import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile userProfile;
  final Function(UserProfile) onProfileUpdated;
  final Function(String) onLanguageChanged;
  final String currentLanguage;

  const SettingsScreen({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
    required this.onLanguageChanged,
    required this.currentLanguage,
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userProfile.name);
    _ageController =
        TextEditingController(text: widget.userProfile.age.toString());
    _weightController =
        TextEditingController(text: widget.userProfile.weight.toString());
    _heightController =
        TextEditingController(text: widget.userProfile.height.toString());
    _apiTokenController =
        TextEditingController(text: widget.userProfile.apiToken ?? '');
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
        apiToken:
            _apiTokenController.text.isEmpty ? null : _apiTokenController.text,
      );

      await updatedProfile.save();

      if (!mounted) return; // Add mounted check before using context

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            _selectedLanguage == 'Български' ? 'Потвърждение' : 'Confirmation'),
        content: Text(_selectedLanguage == 'Български'
            ? 'Сигурни ли сте, че искате да излезете?'
            : 'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(_selectedLanguage == 'Български' ? 'Отказ' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_selectedLanguage == 'Български' ? 'Изход' : 'Logout'),
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
            _selectedLanguage == 'Български'
                ? 'Грешка при изход от профила'
                : 'Error logging out',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchUrl(String url) async {
    // For real apps, use url_launcher package
    // ignore: avoid_print
    print('Open URL: $url');
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedLanguage == 'Български' ? 'Смяна на парола' : 'Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: InputDecoration(
            labelText: _selectedLanguage == 'Български' ? 'Нова парола' : 'New Password',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(_selectedLanguage == 'Български' ? 'Отказ' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(_selectedLanguage == 'Български' ? 'Запази' : 'Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Паролата е сменена успешно' : 'Password changed successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Грешка при смяна на паролата' : 'Error changing password'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedLanguage == 'Български' ? 'Потвърждение' : 'Confirmation'),
        content: Text(_selectedLanguage == 'Български'
            ? 'Сигурни ли сте, че искате да изтриете акаунта си? Това действие е необратимо.'
            : 'Are you sure you want to delete your account? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_selectedLanguage == 'Български' ? 'Отказ' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_selectedLanguage == 'Български' ? 'Изтрий' : 'Delete')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid;
        if (uid != null) {
          // Delete user profile from Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).delete();
          // Delete chat history
          final chatDocs = await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').get();
          for (final doc in chatDocs.docs) {
            await doc.reference.delete();
          }
        }
        await user?.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Акаунтът е изтрит' : 'Account deleted'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Грешка при изтриване на акаунта' : 'Error deleting account'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedLanguage == 'Български' ? 'Потвърждение' : 'Confirmation'),
        content: Text(_selectedLanguage == 'Български'
            ? 'Сигурни ли сте, че искате да изчистите историята на чата?'
            : 'Are you sure you want to clear chat history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_selectedLanguage == 'Български' ? 'Отказ' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(_selectedLanguage == 'Български' ? 'Изчисти' : 'Clear')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        final uid = user?.uid;
        if (uid != null) {
          final chatDocs = await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').get();
          for (final doc in chatDocs.docs) {
            await doc.reference.delete();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Историята на чата е изчистена' : 'Chat history cleared'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Грешка при изчистване на историята' : 'Error clearing chat history'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final chats = await FirebaseFirestore.instance.collection('users').doc(uid).collection('chats').get();
        final data = {
          'profile': userDoc.data(),
          'chats': chats.docs.map((doc) => doc.data()).toList(),
        };
        final jsonStr = JsonEncoder.withIndent('  ').convert(data);
        // For web, you might use AnchorElement for download; for mobile, use share or file APIs
        // Here, just print to console as a placeholder
        print(jsonStr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Данните са експортирани (виж конзолата)' : 'Data exported (see console)'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_selectedLanguage == 'Български' ? 'Грешка при експортиране на данни' : 'Error exporting data'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importData() async {
    // For a real app, use file picker and parse JSON
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedLanguage == 'Български' ? 'Импорт на данни' : 'Import Data'),
        content: Text(_selectedLanguage == 'Български' ? 'Тази функция предстои.' : 'This feature is coming soon.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_selectedLanguage == 'Български' ? 'Настройки' : 'Settings'),
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
              // Section: Language
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Език' : 'Language',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
              // Section: Personal Info
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Лична информация' : 'Personal Info',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
              // Section: App/API Settings
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Настройки на приложението' : 'App/API Settings',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ),
              // Section: Actions
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.save, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Действия' : 'Actions',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                                textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
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
              // Section: Account Management
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Акаунт' : 'Account',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.lock_reset),
                        onPressed: _changePassword,
                        label: Text(_selectedLanguage == 'Български' ? 'Смени парола' : 'Change Password'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.normal),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: _deleteAccount,
                        label: Text(
                          _selectedLanguage == 'Български' ? 'Изтрий акаунта' : 'Delete Account',
                          style: const TextStyle(letterSpacing: 0.5, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Section: Data Management
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage, color: Colors.brown),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Данни' : 'Data',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_sweep),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.normal),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        onPressed: _clearChatHistory,
                        label: Text(
                          _selectedLanguage == 'Български' ? 'Изчисти историята на чата' : 'Clear Chat History',
                          style: const TextStyle(letterSpacing: 0.5, fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.download),
                        onPressed: _exportData,
                        label: Text(_selectedLanguage == 'Български' ? 'Експортирай данни' : 'Export Data'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        onPressed: _importData,
                        label: Text(_selectedLanguage == 'Български' ? 'Импортирай данни' : 'Import Data'),
                      ),
                    ],
                  ),
                ),
              ),
              // Section: App Info
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Text(
                            _selectedLanguage == 'Български' ? 'Информация за приложението' : 'App Info',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Version: 1.0.0+1'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchUrl('https://github.com/martinivanov/fitnessappvaso'),
                        child: Text(
                          _selectedLanguage == 'Български' ? 'Изходен код в GitHub' : 'Source Code on GitHub',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _launchUrl('https://martinivanov.net'),
                        child: Text(
                          _selectedLanguage == 'Български' ? 'Уебсайт на разработчика' : 'Developer Website',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
