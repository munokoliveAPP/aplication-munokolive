// Minimal shim to provide `AppStrings.get` when the full language service
// is not present. This keeps analysis/build fast while we apply safe i18n fixes.
class AppStrings {
  static String get(String languageCode, String key) {
    // Return a fallback: the key itself. Replace with real translations later.
    return key;
  }
}
