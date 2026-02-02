/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:munokolive_music/ui/widgets/smart_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/services.dart';
import 'package:munokolive_music/ui/booking/booking_request_page.dart';

import 'package:munokolive_music/ui/chat/salon_chat_page.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class MemberDetailsPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> memberData;
  final Position? currentUserPosition;

  const MemberDetailsPage({
    super.key,
    required this.memberData,
    this.currentUserPosition,
  });

  @override
  ConsumerState<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends ConsumerState<MemberDetailsPage> {
  String _distanceDisplay = "";
  bool _contactRevealed = false;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  void _calculateDistance() {
    if (widget.currentUserPosition != null &&
        widget.memberData['latitude'] != null &&
        widget.memberData['longitude'] != null) {
      final double lat = (widget.memberData['latitude'] as num).toDouble();
      final double lng = (widget.memberData['longitude'] as num).toDouble();
      final dist = Geolocator.distanceBetween(
        widget.currentUserPosition!.latitude,
        widget.currentUserPosition!.longitude,
        lat,
        lng,
      );

      setState(() {
        if (dist < 1000) {
          _distanceDisplay = "${dist.toStringAsFixed(0)}m";
        } else {
          _distanceDisplay = "${(dist / 1000).toStringAsFixed(1)}km";
        }
      });
    }
  }

  Future<void> _launchWhatsApp() async {
    final phone = widget.memberData['phone_number']?.toString();
    if (phone != null && phone.isNotEmpty) {
      // Clean phone number
      String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanPhone.startsWith('+')) {
        // Default to Cote d'Ivoire (+225) if no code, just a guess
        // But usually it's better to let user handle it or prompt
      }

      // WhatsApp URL Scheme
      final url = Uri.parse("whatsapp://send?phone=$cleanPhone");
      // Fallback Web URL
      final webUrl = Uri.parse("https://wa.me/$cleanPhone");

      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.impossibleOpenWhatsApp,
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorOpeningWhatsApp),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.numberNotAvailable),
          ),
        );
      }
    }
  }

  Future<void> _launchCall() async {
    final phone = widget.memberData['phone_number']?.toString();
    if (phone != null && phone.isNotEmpty) {
      final url = Uri.parse("tel:$phone");
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.impossibleLaunchCall,
                ),
              ),
            );
          }
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  Future<void> _launchSMS() async {
    final phone = widget.memberData['phone_number']?.toString();
    if (phone != null && phone.isNotEmpty) {
      final url = Uri.parse("sms:$phone");
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } catch (e) {
        // Ignore
      }
    }
  }

  void _launchMissionProposal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingRequestPage(
          providerId: widget.memberData['id'].toString(),
          providerName:
              "${widget.memberData['first_name']} ${widget.memberData['last_name']}",
        ),
      ),
    );
  }

  void _launchPrivateChat() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    final otherUserId = widget.memberData['id'].toString();
    final myId = currentUser.id;

    // Prevent chatting with self
    if (otherUserId == myId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cannotMessageSelf),
        ),
      );
      return;
    }

    // Sort IDs to ensure consistency
    final ids = [myId, otherUserId]..sort();
    final salonId = "private_${ids[0]}_${ids[1]}";

    final otherUserName =
        "${widget.memberData['first_name']} ${widget.memberData['last_name']}";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SalonChatPage(
          salonId: salonId,
          salonTitle: otherUserName,
          themeColor: Colors.deepPurpleAccent,
        ),
      ),
    );
  }

  Future<void> _toggleAdminRole(String userId, bool currentIsAdmin) async {
    final newRole = currentIsAdmin ? 'user' : 'admin';
    final action = currentIsAdmin
        ? AppLocalizations.of(context)!.demoteAction
        : AppLocalizations.of(context)!.promoteAction;
    final title = currentIsAdmin
        ? AppLocalizations.of(context)!.demoteAdmin
        : AppLocalizations.of(context)!.promoteAdmin;

    // Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2D0036),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          AppLocalizations.of(context)!.confirmAdminRoleChange(action),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);

      if (mounted) {
        SmartSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.roleUpdatedSuccess,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        SmartSnackBar.show(
          context,
          message: AppLocalizations.of(context)!.errorUpdate(e.toString()),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch current user profile to check for Admin rights
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final isCurrentUserAdmin = currentUserAsync.when(
      data: (user) => user?.role == 'admin',
      loading: () => false,
      error: (_, _) => false,
    );

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client
          .from('users')
          .stream(primaryKey: ['id'])
          .eq('id', widget.memberData['id'])
          .limit(1),
      initialData: [widget.memberData],
      builder: (context, snapshot) {
        final data = (snapshot.hasData && snapshot.data!.isNotEmpty)
            ? snapshot.data!.first
            : widget.memberData;

        final name = "${data['first_name']} ${data['last_name']}";
        final photoUrl = data['photo_url']?.toString();
        final category = data['category']?.toString() ?? 'Membre';
        final subCategory = data['sub_category']?.toString();
        final church =
            data['church_name']?.toString() ??
            AppLocalizations.of(context)!.churchNotSpecified;
        final isOnline = data['is_online'] == true;

        return Scaffold(
          backgroundColor: const Color(0xFF1E0024),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar with Pulse
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isOnline)
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    CachedCircleAvatar(imageUrl: photoUrl, radius: 60),
                    if (isOnline)
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    "$category ${subCategory != null ? '• $subCategory' : ''}",
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Distance Card
                if (_distanceDisplay.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.near_me, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(
                          "Frère ${widget.memberData['first_name']} est à $_distanceDisplay",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 30),

                // Actions Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Always visible Private Chat (Unlocked)
                      _buildActionButton(
                        icon: Icons.chat_bubble,
                        label: AppLocalizations.of(context)!.writePrivate,
                        color: Colors.deepPurpleAccent,
                        onTap: _launchPrivateChat,
                      ),
                      const SizedBox(height: 30),

                      _contactRevealed
                          ? Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildActionButton(
                                  icon: Icons.call,
                                  label: AppLocalizations.of(context)!.call,
                                  color: Colors.green,
                                  onTap: _launchCall,
                                  onLongPress: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            widget.memberData['phone_number']
                                                ?.toString() ??
                                            "",
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          AppLocalizations.of(context)!.numberCopied,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.chat,
                                  label: AppLocalizations.of(context)!.whatsapp,
                                  color: Colors.greenAccent.shade700,
                                  onTap: _launchWhatsApp,
                                ),
                                _buildActionButton(
                                  icon: Icons.message,
                                  label: AppLocalizations.of(context)!.sms,
                                  color: Colors.blueAccent,
                                  onTap: _launchSMS,
                                ),
                                _buildActionButton(
                                  icon: Icons.map,
                                  label: AppLocalizations.of(context)!.map,
                                  color: Colors.orange,
                                  onTap: () {
                                    if (widget.memberData['latitude'] != null &&
                                        widget.memberData['longitude'] !=
                                            null) {
                                      // ... (code existing)
                                      final lat =
                                          (widget.memberData['latitude'] as num)
                                              .toDouble();
                                      final lng =
                                          (widget.memberData['longitude']
                                                  as num)
                                              .toDouble();
                                      final url = Uri.parse(
                                        "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
                                      );
                                      launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(context)!.locationNotAvailable,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                // MISSION BUTTON (UBER STYLE)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: _buildActionButton(
                                    icon: Icons.rocket_launch,
                                    label: AppLocalizations.of(context)!.mission,
                                    color: Colors.purpleAccent,
                                    onTap: _launchMissionProposal,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _contactRevealed = true;
                                  });
                                },
                                icon: const Icon(Icons.contact_phone),
                                label: Text(AppLocalizations.of(context)!.contactCaps),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppTheme.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Info Section
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.informations,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildInfoRow(Icons.church, "Église / Ministère", church),
                      const Divider(color: Colors.white10, height: 30),
                      _buildInfoRow(
                        Icons.calendar_today,
                        "Membre depuis",
                        _formatDate(widget.memberData['created_at']),
                      ),
                      const Divider(color: Colors.white10, height: 30),
                      _buildInfoRow(
                        Icons.star,
                        "Réputation",
                        "${widget.memberData['points'] ?? 0} points",
                      ),

                      // ADMIN SECTION
                      if (isCurrentUserAdmin) ...[
                        const Divider(color: Colors.white10, height: 30),
                        const Text(
                          "Administration",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Builder(
                                builder: (context) {
                                  final isTargetAdmin = data['role'] == 'admin';
                                  return Column(
                                    children: [
                                      Text(
                                        isTargetAdmin
                                            ? "Ce membre est Administrateur"
                                            : "Ce membre est Utilisateur Standard",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _toggleAdminRole(
                                            data['id'].toString(),
                                            isTargetAdmin,
                                          ),
                                          icon: Icon(
                                            isTargetAdmin
                                                ? Icons.remove_moderator
                                                : Icons.add_moderator,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            isTargetAdmin
                                                ? "RETIRER L'ADMINISTRATION"
                                                : "NOMMER ADMINISTRATEUR",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isTargetAdmin
                                                ? Colors.red
                                                : Colors.blueAccent,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return "Inconnu";
    try {
      final DateTime d = date is DateTime
          ? date
          : DateTime.parse(date.toString());
      return "${d.day}/${d.month}/${d.year}";
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
