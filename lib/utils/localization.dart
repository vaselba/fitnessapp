/// Utility for language-based string selection.
class LocalizationUtil {
  static String select(
      {required String language, required String bg, required String en}) {
    return language == 'Български' ? bg : en;
  }

  // Example for more complex cases (e.g., error codes)
  static String errorMessage(String code, String language) {
    switch (code) {
      case 'permission-denied':
        return language == 'Български'
            ? 'Нямате разрешение за тази операция'
            : 'You don\'t have permission for this operation';
      case 'unavailable':
        return language == 'Български'
            ? 'Грешка в мрежовата връзка'
            : 'Network connection error';
      case 'timeout':
        return language == 'Български'
            ? 'Времето за изчакване изтече'
            : 'Connection timeout';
      case 'unauthenticated':
        return language == 'Български'
            ? 'Моля влезте отново в профила си'
            : 'Please sign in again';
      default:
        return language == 'Български'
            ? 'Възникна грешка'
            : 'An error occurred';
    }
  }
}
