import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';

/// Widget invisible qui écoute les changements de statut/rôle de l'utilisateur
/// et affiche des notifications ou effectue des actions (logout, refresh).
class UserStatusListener extends ConsumerWidget {
  final Widget child;

  const UserStatusListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProfileProvider, (previous, next) {
      // 1. Vérification des valeurs
      if (previous?.value == null || next.value == null) return;

      final oldUser = previous!.value!;
      final newUser = next.value!;

      // 2. Détection changement de Rôle
      if (oldUser.role != newUser.role) {
        SmartSnackBar.show(
          context,
          message:
              "Votre rôle a été mis à jour : ${newUser.role.toUpperCase()}",
          isSuccess: true,
        );
      }

      // 3. Détection Validation
      if (!oldUser.isValidated && newUser.isValidated) {
        SmartSnackBar.show(
          context,
          message: "Félicitations ! Votre compte a été validé.",
          isSuccess: true,
        );
      }

      // 4. Détection Ban/Rejet
      if (oldUser.status != 'banned' && newUser.status == 'banned') {
        // Force Logout logic usually handled by AuthWrapper or RLS,
        // but a UI feedback is good.
        SmartSnackBar.show(
          context,
          message: "Votre compte a été suspendu.",
          isError: true,
        );
      }
    });

    return child;
  }
}
