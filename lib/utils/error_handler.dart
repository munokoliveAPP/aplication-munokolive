/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
class ErrorHandler {
  static String getErrorMessage(Object error) {
    // Customize error messages here based on error type
    return error.toString().replaceAll('Exception:', '').trim();
  }
}
