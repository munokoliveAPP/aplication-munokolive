import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/urgent_request_model.dart';
import 'package:munokolive_music/providers/urgent_requests_provider.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';

class MissionStatusDialog extends ConsumerWidget {
  final String requestId;

  const MissionStatusDialog({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stream = Supabase.instance.client
        .from('urgent_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((event) => event.isNotEmpty ? UrgentRequest.fromJson(event.first) : null);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: StreamBuilder<UrgentRequest?>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final request = snapshot.data;
          if (request == null) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2A0036),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Text(
                "Mission introuvable ou supprimée.",
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            );
          }

          return _buildContent(context, ref, request);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UrgentRequest request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusDesc;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orangeAccent;
        statusIcon = Icons.radar;
        statusText = "Recherche en cours...";
        statusDesc = "Nous contactons les héros de la zone.";
        break;
      case 'broadcasted':
        statusColor = Colors.blueAccent;
        statusIcon = Icons.wifi_tethering;
        statusText = "Alerte Diffusée";
        statusDesc = "Les musiciens/pasteurs ont reçu votre appel.";
        break;
      case 'accepted':
        statusColor = Colors.greenAccent;
        statusIcon = Icons.check_circle_outline;
        statusText = "Héros Trouvé !";
        statusDesc = "Un intervenant a accepté la mission.";
        break;
      case 'completed':
        statusColor = Colors.purpleAccent;
        statusIcon = Icons.task_alt;
        statusText = "Mission Terminée";
        statusDesc = "L'intervention a été marquée comme réalisée.";
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        statusIcon = Icons.cancel_outlined;
        statusText = "Annulée";
        statusDesc = "Cette mission a été annulée.";
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = "Statut Inconnu";
        statusDesc = "";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E0024),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 40),
          ),
          const SizedBox(height: 16),
          
          // Title & Role
          Text(
            statusText.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Recherche : ${request.roleNeeded}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Motif : ${request.motive}",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          
          const Divider(color: Colors.white24, height: 32),
          
          // Description / Status Details
          Text(
            statusDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          if (request.status == 'pending' || request.status == 'broadcasted')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _cancelMission(context, ref, request.id),
                icon: const Icon(Icons.close),
                label: const Text("Annuler la demande"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            
          if (request.status == 'accepted')
             // Potentially show contact info of the hero here if available
             // For now just a close button
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Fermer"),
              ),
            ),

           if (request.status == 'completed' || request.status == 'cancelled')
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Fermer"),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _cancelMission(BuildContext context, WidgetRef ref, String requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0036),
        title: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Êtes-vous sûr de vouloir annuler cette demande SOS ?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text("Oui, annuler"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(urgentRequestsRepositoryProvider).updateStatus(requestId, 'cancelled');
        if (context.mounted) {
          SmartSnackBar.show(context, message: "Mission annulée.", isSuccess: true);
          Navigator.pop(context); // Close status dialog
        }
      } catch (e) {
        if (context.mounted) {
          SmartSnackBar.show(context, message: "Erreur: $e", isError: true);
        }
      }
    }
  }
}
