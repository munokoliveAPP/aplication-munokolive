import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event_model.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../services/event_service.dart';

class ExpandableEventCard extends ConsumerStatefulWidget {
  final EventModel event;
  final UserProfile? currentUser;
  final bool isAdmin;
  final bool isToday;
  final VoidCallback? onAttendToggle;

  const ExpandableEventCard({
    super.key,
    required this.event,
    this.currentUser,
    this.isAdmin = false,
    this.isToday = false,
    this.onAttendToggle,
  });

  @override
  ConsumerState<ExpandableEventCard> createState() =>
      _ExpandableEventCardState();
}

class _ExpandableEventCardState extends ConsumerState<ExpandableEventCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  UserProfile? _creatorProfile;
  List<UserProfile> _attendeesProfiles = [];
  bool _loadingProfiles = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadCreatorAndAttendees();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorAndAttendees() async {
    if (!_isExpanded) return;

    setState(() => _loadingProfiles = true);

    try {
      // Load creator profile
      final authService = ref.read(authServiceProvider);
      final creator = await authService.getUserProfile(widget.event.creatorId);
      _creatorProfile = creator;

      // Load attendees profiles
      final attendees = <UserProfile>[];
      if (widget.event.attendees.isNotEmpty) {
        for (final attendeeId in widget.event.attendees.take(10)) {
          final attendee = await authService.getUserProfile(attendeeId);
          if (attendee != null) {
            attendees.add(attendee);
          }
        }
      }
      _attendeesProfiles = attendees;
    } catch (e) {
      debugPrint('Error loading profiles: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingProfiles = false);
      }
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        _loadCreatorAndAttendees();
      } else {
        _animationController.reverse();
      }
    });
  }

  bool get _isAttending {
    return widget.currentUser != null &&
        widget.event.attendees.contains(widget.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    final isPending = widget.event.status == 'pending';

    return Card(
      margin: EdgeInsets.only(
        bottom: 24,
        left: widget.isToday ? 0 : 16,
        right: widget.isToday ? 0 : 16,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: widget.isToday ? 12 : 8,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: widget.isToday
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDF00FF), Color(0xFF800080)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          border: Border.all(
            color: widget.isToday
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: widget.isToday ? 2 : 1,
          ),
          boxShadow: widget.isToday
              ? [
                  BoxShadow(
                    color: const Color(0xFFDF00FF).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                _buildImageSection(isPending),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.event.title,
                        style: TextStyle(
                          color: widget.isToday ? Colors.white : Colors.white,
                          fontSize: widget.isToday ? 22 : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Info Rows
                      _buildInfoRow(
                        Icons.calendar_today,
                        '${DateFormat('dd MMM yyyy', 'fr_FR').format(widget.event.date)} à ${widget.event.time}',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        Icons.location_on,
                        widget.event.location.isNotEmpty
                            ? widget.event.location
                            : '${widget.event.neighborhood ?? ''}, ${widget.event.commune ?? ''}, ${widget.event.city ?? ''}',
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      if (widget.isAdmin && isPending)
                        _buildAdminActions()
                      else if (!isPending)
                        _buildAttendButton(),

                      // Expandable Details
                      if (!isPending) ...[
                        const SizedBox(height: 12),
                        _buildExpandButton(),
                        SizeTransition(
                          sizeFactor: _expandAnimation,
                          child: _buildExpandedContent(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isPending) {
    return SizedBox(
      height: widget.isToday ? 220 : 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          (widget.event.imageUrl?.isNotEmpty ?? false)
              ? CachedNetworkImage(
                  imageUrl: widget.event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.purple.shade900,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFDF00FF),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.purple.shade900,
                    child: const Icon(
                      Icons.event,
                      size: 64,
                      color: Colors.white24,
                    ),
                  ),
                )
              : Container(
                  color: Colors.purple.shade900,
                  child: const Icon(
                    Icons.event,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
          if (isPending)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'En attente de validation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.event.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: widget.isToday ? Colors.white : Colors.white70,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: widget.isToday ? Colors.white : Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAdminActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => ref
                .read(eventServiceProvider)
                .validateEvent(widget.event.id, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => ref
                .read(eventServiceProvider)
                .validateEvent(widget.event.id, false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Refuser'),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: _isAttending
            ? const LinearGradient(colors: [Colors.green, Colors.greenAccent])
            : null,
        borderRadius: BorderRadius.circular(25),
        border: _isAttending
            ? null
            : Border.all(color: const Color(0xFFDF00FF), width: 2),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          if (widget.currentUser == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Connectez-vous pour participer')),
              );
            }
            return;
          }
          try {
            await ref
                .read(eventServiceProvider)
                .toggleAttendance(widget.event.id, widget.currentUser!.uid);
            widget.onAttendToggle?.call();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
            }
          }
        },
        icon: Icon(
          _isAttending ? Icons.check_circle : Icons.person_add,
          color: _isAttending ? Colors.white : const Color(0xFFDF00FF),
        ),
        label: Text(
          _isAttending ? 'J\'y vais' : 'Je participe',
          style: TextStyle(
            color: _isAttending ? Colors.white : const Color(0xFFDF00FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isAttending ? Colors.transparent : Colors.white10,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildExpandButton() {
    return InkWell(
      onTap: _toggleExpand,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'Masquer les détails' : 'Voir les détails',
              style: TextStyle(
                color: widget.isToday ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: widget.isToday ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white24),
        const SizedBox(height: 12),

        // Description
        if (widget.event.description.isNotEmpty) ...[
          Text(
            'Description',
            style: TextStyle(
              color: widget.isToday ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.event.description,
            style: TextStyle(
              color: widget.isToday ? Colors.white70 : Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Creator
        if (_creatorProfile != null) ...[
          Text(
            'Organisateur',
            style: TextStyle(
              color: widget.isToday ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          _buildUserTile(_creatorProfile!),
          const SizedBox(height: 16),
        ],

        // Attendees
        if (widget.event.attendees.isNotEmpty) ...[
          Text(
            'Participants (${widget.event.attendees.length})',
            style: TextStyle(
              color: widget.isToday ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingProfiles)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFDF00FF)),
            )
          else if (_attendeesProfiles.isEmpty)
            Text(
              'Chargement...',
              style: TextStyle(
                color: widget.isToday ? Colors.white70 : Colors.white70,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._attendeesProfiles.map(
                  (profile) => _buildAttendeeChip(profile),
                ),
                if (widget.event.attendees.length > _attendeesProfiles.length)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+${widget.event.attendees.length - _attendeesProfiles.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }

  Widget _buildUserTile(UserProfile profile) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          backgroundImage:
              profile.photoUrl != null &&
                  profile.photoUrl!.isNotEmpty &&
                  profile.photoUrl!.startsWith('http')
              ? CachedNetworkImageProvider(profile.photoUrl!)
              : null,
          child:
              profile.photoUrl == null ||
                  profile.photoUrl!.isEmpty ||
                  !profile.photoUrl!.startsWith('http')
              ? const Icon(Icons.person, color: Colors.white70)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${profile.firstName} ${profile.lastName}',
                style: TextStyle(
                  color: widget.isToday ? Colors.white : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (profile.category.isNotEmpty)
                Text(
                  profile.category,
                  style: TextStyle(
                    color: widget.isToday ? Colors.white70 : Colors.white70,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeChip(UserProfile profile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            backgroundImage:
                profile.photoUrl != null &&
                    profile.photoUrl!.isNotEmpty &&
                    profile.photoUrl!.startsWith('http')
                ? CachedNetworkImageProvider(profile.photoUrl!)
                : null,
            child:
                profile.photoUrl == null ||
                    profile.photoUrl!.isEmpty ||
                    !profile.photoUrl!.startsWith('http')
                ? const Icon(Icons.person, size: 12, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            '${profile.firstName} ${profile.lastName}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
