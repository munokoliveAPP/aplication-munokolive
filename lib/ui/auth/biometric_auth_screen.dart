import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class BiometricAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const BiometricAuthScreen({super.key, required this.onAuthenticated});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _message = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _message = AppLocalizations.of(context)!.pleaseAuthenticate;
        });
        _authenticate();
      }
    });
  }

  Future<void> _authenticate() async {
    if (!mounted) return;
    setState(() {
      _isAuthenticating = true;
      _message = AppLocalizations.of(context)!.authenticating;
    });

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: AppLocalizations.of(context)!.biometricReason,
      );

      if (didAuthenticate) {
        widget.onAuthenticated();
      } else {
        if (mounted) {
          setState(() {
            _message = AppLocalizations.of(context)!.authenticationFailed;
          });
        }
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _message = "${AppLocalizations.of(context)!.errorPrefix}${e.message}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: const Icon(
                  Icons.fingerprint,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.secureAppTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _message,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (!_isAuthenticating)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.retryButton),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
