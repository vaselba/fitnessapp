/// Common form field validators for the app.
class Validators {
  static String? validateName(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете име'
          : 'Please enter your name';
    }
    return null;
  }

  static String? validateAge(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете възраст'
          : 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null || age < 0 || age > 120) {
      return language == 'Български'
          ? 'Моля въведете валидна възраст'
          : 'Please enter a valid age';
    }
    return null;
  }

  static String? validateWeight(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете тегло'
          : 'Please enter your weight';
    }
    final weight = double.tryParse(value);
    if (weight == null || weight <= 0 || weight > 300) {
      return language == 'Български'
          ? 'Моля въведете валидно тегло'
          : 'Please enter a valid weight';
    }
    return null;
  }

  static String? validateHeight(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете височина'
          : 'Please enter your height';
    }
    final height = double.tryParse(value);
    if (height == null || height <= 0 || height > 300) {
      return language == 'Български'
          ? 'Моля въведете валидна височина'
          : 'Please enter a valid height';
    }
    return null;
  }

  static String? validateEmail(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете имейл'
          : 'Please enter your email';
    }
    if (!value.contains('@')) {
      return language == 'Български'
          ? 'Моля въведете валиден имейл'
          : 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value, {required String language}) {
    if (value == null || value.isEmpty) {
      return language == 'Български'
          ? 'Моля въведете парола'
          : 'Please enter your password';
    }
    if (value.length < 6) {
      return language == 'Български'
          ? 'Паролата трябва да е поне 6 символа'
          : 'Password must be at least 6 characters';
    }
    return null;
  }
}
