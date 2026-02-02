import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'biometric_auth_screen.dart';

class BiometricGate extends StatefulWidget {
  final Widget child;
  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  bool _isAuthenticated = false;
  bool _requiresAuth = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRequirement();
  }

  Future<void> _checkRequirement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('biometrics_enabled') ?? false;

      if (mounted) {
        setState(() {
          _requiresAuth = enabled;
          // If no auth required, we consider them authenticated immediately
          if (!enabled) {
            _isAuthenticated = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback sécurisé en cas d'erreur de lecture
      debugPrint("Erreur lecture préférences biométrie: $e");
      if (mounted) {
        setState(() {
          _requiresAuth = false;
          _isAuthenticated =
              true; // On laisse passer par défaut pour ne pas bloquer
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Remplacement de l'écran noir par un loader visible
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
      );
    }

    if (!_requiresAuth || _isAuthenticated) {
      return widget.child;
    }

    return BiometricAuthScreen(
      onAuthenticated: () {
        setState(() {
          _isAuthenticated = true;
        });
      },
    );
  }
}
