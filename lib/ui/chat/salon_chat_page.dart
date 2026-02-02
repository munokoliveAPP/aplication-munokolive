import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/models/user_profile.dart';
import 'package:munokolive_music/models/chat_message.dart';
import 'package:munokolive_music/providers/user_provider.dart';
import 'package:munokolive_music/ui/chat/controllers/chat_controller.dart';
import 'package:munokolive_music/ui/widgets/cached_circle_avatar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:munokolive_music/ui/widgets/glass_container.dart';
import 'package:munokolive_music/ui/profile/view_profile_page.dart';
import 'package:flutter/services.dart';
import 'package:munokolive_music/services/notification_service.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class SalonChatPage extends ConsumerStatefulWidget {
  final String salonId;
  final String salonTitle;
  final Color themeColor;

  const SalonChatPage({
    super.key,
    required this.salonId,
    required this.salonTitle,
    required this.themeColor,
  });

  @override
  ConsumerState<SalonChatPage> createState() => _SalonChatPageState();
}

class _SalonChatPageState extends ConsumerState<SalonChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showWelcomeMessage = true;
  ChatMessage? _replyingTo;
  DateTime? _lastTypingSent;
  StreamSubscription? _topicSubscription;

  @override
  void dispose() {
    _topicSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    PaintingBinding.instance.imageCache.clear();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Smart Triggers
    SmartTriggerService().startListening();

    // Manne Fraîche: Silent Cleanup
    Future.microtask(() {
      ref.read(chatControllerProvider(widget.salonId)).cleanupOldMessages();
    });

    // Welcome message auto-hide
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _showWelcomeMessage = false;
        });
      }
    });

    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null && _messageController.text.isNotEmpty) {
      if (_lastTypingSent == null ||
          DateTime.now().difference(_lastTypingSent!) >
              const Duration(seconds: 2)) {
        ref
            .read(chatControllerProvider(widget.salonId))
            .sendTypingEvent(user.firstName);
        _lastTypingSent = DateTime.now();
      }
    }
  }

  Future<void> _sendMessage(UserProfile user) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    HapticFeedback.lightImpact();

    try {
      await ref
          .read(chatControllerProvider(widget.salonId))
          .sendMessage(text, user, replyToId: _replyingTo?.id);

      setState(() {
        _replyingTo = null;
      });

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.sendError}$e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProfileOptions(
    BuildContext context,
    String userId,
    String userName,
    String? photoUrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F2C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedCircleAvatar(imageUrl: photoUrl, radius: 40),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person),
                    label: Text(AppLocalizations.of(context)!.viewProfile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewProfilePage(userId: userId),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: Text(AppLocalizations.of(context)!.privateMessage),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.themeColor,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);

                      final currentUser =
                          Supabase.instance.client.auth.currentUser;
                      if (currentUser == null) return;

                      if (currentUser.id == userId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)!.cannotMessageSelf,
                            ),
                          ),
                        );
                        return;
                      }

                      final ids = [currentUser.id, userId]..sort();
                      final privateSalonId = "private_${ids[0]}_${ids[1]}";

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalonChatPage(
                            salonId: privateSalonId,
                            salonTitle: userName,
                            themeColor: widget.themeColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTopicDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2C),
        title: Text(
          AppLocalizations.of(context)!.debateTopicTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.topicTitleLabel,
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.descriptionLabel,
                labelStyle: const TextStyle(color: Colors.grey),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancelButton,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.themeColor),
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref
                    .read(chatControllerProvider(widget.salonId))
                    .setActiveTopic(
                      titleController.text.trim(),
                      descController.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: Text(
              AppLocalizations.of(context)!.publishButton,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebateBoard(
    AsyncValue<Map<String, dynamic>?> activeTopicAsync,
    Color themeColor,
    int onlineCount,
  ) {
    return activeTopicAsync.when(
      data: (topicData) {
        if (topicData == null) return const SizedBox.shrink();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Container(
            key: ValueKey(topicData['id']),
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColor.withValues(alpha: 0.2),
                  const Color(0xFF1A1F2C).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border(
                left: BorderSide(color: themeColor, width: 4),
                top: BorderSide(color: themeColor.withValues(alpha: 0.3)),
                bottom: BorderSide(color: themeColor.withValues(alpha: 0.3)),
                right: BorderSide(color: themeColor.withValues(alpha: 0.3)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign, color: themeColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.activeDebateTopic,
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    // Counter badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          PulsingDot(color: Colors.greenAccent),
                          const SizedBox(width: 6),
                          Text(
                            "$onlineCount",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  topicData['topic'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (topicData['description'] != null &&
                    topicData['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    topicData['description'],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "$onlineCount ${AppLocalizations.of(context)!.membersInCommunion}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }

  Widget _buildTypingIndicator() {
    final typingUsers = ref.watch(typingUsersProvider(widget.salonId));
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Row(
              children: List.generate(3, (index) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: (value + (index * 0.2)) % 1.0,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                  onEnd: () {},
                );
              }),
            ),
          ),
          Text(
            "${typingUsers.join(', ')} ${AppLocalizations.of(context)!.typingIndicator}",
            style: TextStyle(
              color: widget.themeColor,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2C),
        border: Border(left: BorderSide(color: widget.themeColor, width: 4)),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: widget.themeColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Réponse à ${_replyingTo!.userName}",
                  style: TextStyle(
                    color: widget.themeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.salonId));
    final onlineUsers = ref.watch(salonPresenceProvider(widget.salonId));
    final activeTopicAsync = ref.watch(activeTopicProvider(widget.salonId));
    final isAdmin =
        userAsync.value?.role == 'admin' ||
        userAsync.value?.role == 'super_admin';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tag, color: widget.themeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.salonTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    PulsingDot(color: Colors.greenAccent),
                    const SizedBox(width: 6),
                    Text(
                      "${onlineUsers.length} en communion",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.campaign, color: Colors.white),
              tooltip: AppLocalizations.of(context)!.defineDebateTopicTooltip,
              onPressed: () => _showTopicDialog(context),
            ),
          // Avatar pile of online users (limit to 3)
          if (onlineUsers.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                itemCount: onlineUsers.take(3).length,
                itemBuilder: (context, index) {
                  return Align(
                    widthFactor: 0.7,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: CachedCircleAvatar(
                        imageUrl: onlineUsers[index].photoUrl,
                        radius: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              const Color(0xFF120B20),
              widget.themeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Active Debate Board
            _buildDebateBoard(
              activeTopicAsync,
              widget.themeColor,
              onlineUsers.length,
            ),

            // Ephemeral Welcome Message
            AnimatedSize(
              duration: const Duration(milliseconds: 500),
              child: _showWelcomeMessage
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.themeColor.withValues(alpha: 0.2),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: widget.themeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.auto_awesome, color: widget.themeColor),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.welcomeVisionMunokolive,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: widget.themeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Ici, la manne est fraîche chaque matin. Exprimez-vous librement dans la sainteté.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Chat Stream
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Soyez le premier à écrire...",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true, // Start from bottom
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      cacheExtent: 1000,
                      addAutomaticKeepAlives: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = userAsync.value?.id == msg.userId;

                        // Check continuity with next message (which is previous in reverse list)
                        final bool isNextSameUser =
                            index < messages.length - 1 &&
                            messages[index + 1].userId == msg.userId;

                        // Find replied message
                        ChatMessage? repliedMsg;
                        if (msg.replyToId != null) {
                          try {
                            repliedMsg = messages.firstWhere(
                              (m) => m.id == msg.replyToId,
                            );
                          } catch (_) {}
                        }

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildMessageBubble(
                                msg,
                                isMe,
                                isNextSameUser,
                                context,
                                repliedMsg: repliedMsg,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: 10,
                  itemBuilder: (_, index) {
                    final isRight = index % 2 == 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: isRight
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (!isRight) ...[
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            width: 200,
                            height: 40 + (index % 3) * 20.0,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                error: (err, stack) => Center(
                  child: Text(
                    "Erreur: $err",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),

            // Typing Indicator
            _buildTypingIndicator(),

            // Reply Preview
            _buildReplyPreview(),

            // Input Area
            userAsync.when(
              data: (user) => user != null
                  ? _buildInputArea(user)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg,
    bool isMe,
    bool isNextSameUser,
    BuildContext context, {
    ChatMessage? repliedMsg,
  }) {
    final DateTime createdAt = msg.createdAt;
    final DateTime now = DateTime.now();
    final bool isToday =
        now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    final String dateStr = isToday
        ? ""
        : "${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ";
    final timeStr =
        "$dateStr${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1F2C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ["❤️", "😂", "🙏", "🔥", "😮"].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(chatControllerProvider(widget.salonId))
                            .addReaction(msg.id, emoji);
                        Navigator.pop(context);
                      },
                      child: Text(emoji, style: const TextStyle(fontSize: 32)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.reply, color: Colors.white),
                  title: const Text(
                    "Répondre",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _replyingTo = msg;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: isNextSameUser ? 4 : 16),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              // Avatar with Online Indicator
              GestureDetector(
                onTap: () => _showProfileOptions(
                  context,
                  msg.userId,
                  msg.userName,
                  msg.userAvatar,
                ),
                child: Stack(
                  children: [
                    CachedCircleAvatar(imageUrl: msg.userAvatar, radius: 16),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe && !isNextSameUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        msg.userName,
                        style: TextStyle(
                          color: widget.themeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? widget.themeColor.withValues(alpha: 0.8)
                          : const Color(0xFF2A2A35),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMe ? 20 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Replied Message Context
                        if (repliedMsg != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  repliedMsg.userName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                Text(
                                  repliedMsg.content,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Text(
                          msg.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reactions Display
                  if (msg.reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: msg.reactions.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1F2C),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Text(
                              entry.value, // Emoji
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid(BuildContext ctx, List<String> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return GestureDetector(
          onTap: () {
            _messageController.text = _messageController.text + emoji;
            _messageController.selection = TextSelection.fromPosition(
              TextPosition(offset: _messageController.text.length),
            );
            // Don't pop to allow chaining
          },
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(UserProfile user) {
    return GlassContainer(
      blur: 20,
      opacity: 0.1,
      color: Colors.black,
      border: Border(
        top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Emoji Engine Button
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions_outlined,
                  color: widget.themeColor.withValues(alpha: 0.8),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => Container(
                      height: 400,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1A1F2C),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            "Emoji Engine",
                            style: TextStyle(
                              color: widget.themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: DefaultTabController(
                              length: 4,
                              child: Column(
                                children: [
                                  TabBar(
                                    indicatorColor: widget.themeColor,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.grey,
                                    tabs: const [
                                      Tab(text: "🔥 Top"),
                                      Tab(text: "😀 Faces"),
                                      Tab(text: "❤️ Love"),
                                      Tab(text: "🙏 Spirit"),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        _buildEmojiGrid(ctx, [
                                          "🔥",
                                          "🙏",
                                          "❤️",
                                          "🙌",
                                          "🕊️",
                                          "😂",
                                          "😮",
                                          "✝️",
                                          "🎶",
                                          "👏",
                                          "💪",
                                          "✨",
                                          "💯",
                                          "🎉",
                                          "👀",
                                          "👋",
                                          "🤝",
                                          "🛐",
                                          "🥁",
                                          "🎹",
                                        ]),
                                        _buildEmojiGrid(ctx, [
                                          "😀",
                                          "😃",
                                          "😄",
                                          "😁",
                                          "😆",
                                          "😅",
                                          "😂",
                                          "🤣",
                                          "😊",
                                          "😇",
                                          "🙂",
                                          "🙃",
                                          "😉",
                                          "😌",
                                          "😍",
                                          "🥰",
                                          "😘",
                                          "😗",
                                          "😙",
                                          "😚",
                                          "😋",
                                          "😛",
                                          "😝",
                                          "😜",
                                          "🤪",
                                          "🤨",
                                          "🧐",
                                          "🤓",
                                          "😎",
                                          "🤩",
                                        ]),
                                        _buildEmojiGrid(ctx, [
                                          "❤️",
                                          "🧡",
                                          "💛",
                                          "💚",
                                          "💙",
                                          "💜",
                                          "🖤",
                                          "🤍",
                                          "🤎",
                                          "💔",
                                          "❣️",
                                          "💕",
                                          "💞",
                                          "💓",
                                          "💗",
                                          "💖",
                                          "💘",
                                          "💝",
                                          "💟",
                                          "☮️",
                                        ]),
                                        _buildEmojiGrid(ctx, [
                                          "🙏",
                                          "🙌",
                                          "👐",
                                          "🤲",
                                          "🤝",
                                          "🛐",
                                          "✝️",
                                          "🕊️",
                                          "⛪",
                                          "🕯️",
                                          "📖",
                                          "✨",
                                          "🌟",
                                          "💫",
                                          "⭐",
                                          "😇",
                                          "📿",
                                          "🛐",
                                          "🍇",
                                          "🍞",
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(user),
                    decoration: InputDecoration(
                      hintText: "Message...",
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _messageController,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;

                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: hasText ? 1.0 : 0.5,
                    child: GestureDetector(
                      onTap: hasText ? () => _sendMessage(user) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasText
                              ? widget.themeColor
                              : Colors.grey.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: hasText
                              ? [
                                  BoxShadow(
                                    color: widget.themeColor.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        transform: Matrix4.diagonal3Values(
                          hasText ? 1.05 : 1.0,
                          hasText ? 1.05 : 1.0,
                          hasText ? 1.05 : 1.0,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;
  const PulsingDot({super.key, required this.color});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * _animation.value),
                blurRadius: 8 * _animation.value,
                spreadRadius: 2 * _animation.value,
              ),
            ],
          ),
          child: Icon(
            Icons.circle,
            color: widget.color.withValues(alpha: _animation.value),
            size: 10,
          ),
        );
      },
    );
  }
}
