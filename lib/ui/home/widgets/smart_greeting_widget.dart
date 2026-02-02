import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class SmartGreetingWidget extends StatefulWidget {
  const SmartGreetingWidget({super.key});

  @override
  State<SmartGreetingWidget> createState() => _SmartGreetingWidgetState();
}

class _SmartGreetingWidgetState extends State<SmartGreetingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _currentMessage = "Analyse de votre journée...";

  // Caches for session
  // static String? _cachedMessage; // Deprecated
  // static DateTime? _cacheTime; // Deprecated

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutQuart),
        );

    _generateSmartMessage();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _generateSmartMessage() async {
    // ... (Logique existante conservée pour le fallback)
    // "AI" Delay for effect
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Priority 1: New Events (Local & Event)
      final recentEvents = await supabase
          .from('events')
          .select('title, location')
          .gt(
            'created_at',
            now.subtract(const Duration(hours: 48)).toIso8601String(),
          )
          .limit(1)
          .maybeSingle();

      if (recentEvents != null) {
        if (mounted && _currentMessage == "Analyse de votre journée...") {
          _setMessage(
            "Un nouvel événement vient d'être publié près de vous : ${recentEvents['title']}.",
          );
        }
        return;
      }

      // Priority 2: Top Godfather
      final topGodfather = await supabase
          .from('users')
          .select('first_name, last_name, referral_count')
          .order('referral_count', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted && _currentMessage == "Analyse de votre journée...") {
        // Random selection logic...
        final random = Random();
        final category = random.nextInt(
          100,
        ); // Expanded range for fine-grained probability

        if (category < 10 && topGodfather != null) {
          // 10% chance: Top Godfather
          final name =
              "${topGodfather['first_name']} ${topGodfather['last_name']}";
          _setMessage(
            "Le meilleur parrain de la semaine est $name. Et si c'était vous ?",
          );
        } else if (category < 30) {
          // 20% chance: Engagement & Discovery
          final engagementMessages = [
            "Continuez de partager Munokolive autour de vous, chaque membre compte.",
            "Votre profil est votre témoignage. Est-il à jour ?",
            "Invitez un ami musicien à rejoindre la communauté aujourd'hui.",
            "Avez-vous des préoccupations ? Déposez-les aux pieds du Seigneur.",
            "Avez-vous visité les nouveaux lieux ajoutés à la communauté ?",
            "Explorez les talents de la communauté Munokolive.",
          ];
          _setMessage(
            engagementMessages[random.nextInt(engagementMessages.length)],
          );
        } else if (category < 60) {
          // 30% chance: Spiritual & Biblical Wisdom
          final spiritualMessages = [
            "Avez-vous pris un moment pour méditer la Parole aujourd'hui ?",
            "Que Dieu bénisse votre navigation sur Munokolive.",
            "La louange est l'arme du chrétien. Utilisez-la aujourd'hui.",
            "Soyez fort et courageux, l'Éternel est avec vous.",
            "Que Dieu soit avec vous en ce jour.",
            "La joie du Seigneur est votre force.",
            "Car rien n'est impossible à Dieu. (Luc 1:37)",
            "L'Éternel est mon berger : je ne manquerai de rien. (Psaume 23:1)",
            "Confie-toi en l'Éternel de tout ton cœur. (Proverbes 3:5)",
            "Je puis tout par celui qui me fortifie. (Philippiens 4:13)",
            "Ne vous inquiétez de rien. (Philippiens 4:6)",
            "L'amour est patient, il est plein de bonté. (1 Corinthiens 13:4)",
          ];
          _setMessage(
            spiritualMessages[random.nextInt(spiritualMessages.length)],
          );
        } else {
          // 40% chance: Proverbs from around the World (Surprise Me!)
          final worldProverbs = [
            // Afrique
            "Si tu veux aller vite, marche seul mais si tu veux aller loin, marchons ensemble. (Proverbe Africain)",
            "Le fleuve fait des détours parce que personne ne lui montre le chemin. (Proverbe Gabonais)",
            "Même le poisson qui vit dans l'eau a toujours soif. (Proverbe Congolais)",
            "L'erreur n'annule pas la valeur de l'effort. (Proverbe Africain)",
            "On ne lave pas le visage d'une personne qui ne le veut pas. (Proverbe Ivoirien)",
            "Le soleil n'oublie personne, même pas le plus petit village. (Proverbe Camerounais)",

            // Asie
            "Un voyage de mille lieues commence toujours par un premier pas. (Lao Tseu)",
            "L'échec est le fondement de la réussite. (Lao Tseu)",
            "Celui qui pose une question est bête cinq minutes, celui qui n'en pose pas l'est toute sa vie. (Proverbe Chinois)",
            "Tomber sept fois, se relever huit. (Proverbe Japonais)",

            // Europe / Occident
            "La patience est amère, mais son fruit est doux. (Jean-Jacques Rousseau)",
            "On ne voit bien qu'avec le cœur. L'essentiel est invisible pour les yeux. (Saint-Exupéry)",
            "Il n'y a pas de vent favorable pour celui qui ne sait pas où il va. (Sénèque)",
            "La seule vraie erreur est celle dont on ne retire aucun enseignement. (Confucius)",

            // Moyen-Orient / Sagesse diverse
            "La beauté est à celui qui la regarde.",
            "Ce qui vient du cœur va au cœur.",
            "La parole douce rompt la colère.",

            // Sagesse Chrétienne / Historique
            "Prie comme si tout dépendait de Dieu. Agis comme si tout dépendait de toi. (Saint Augustin)",
            "La mesure de l'amour, c'est d'aimer sans mesure. (Saint Augustin)",
            "La paix commence par un sourire. (Mère Teresa)",
          ];
          _setMessage(worldProverbs[random.nextInt(worldProverbs.length)]);
        }
      }
    } catch (e) {
      if (mounted && _currentMessage == "Analyse de votre journée...") {
        _setMessage("Que la paix soit avec vous aujourd'hui.");
      }
    }
  }

  void _setMessage(String message) {
    if (!mounted) return;
    setState(() {
      _currentMessage = message;
    });
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _currentMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de défilement horizontal infini (Marquee)
class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;

  const MarqueeWidget({
    super.key,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 6000),
  });

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Démarrer l'animation après le build
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    if (!mounted) return;
    try {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.linear,
        );

        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 1000));

        if (mounted && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
          _startScrolling();
        }
      }
    } catch (e) {
      // Ignorer les erreurs d'animation
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: widget.child,
    );
  }
}

// Conserver TypewriterText pour compatibilité si utilisé ailleurs, sinon il peut être retiré.
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 30), // Vitesse par caractère
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _displayedText = "";
    int charIndex = 0;

    _timer = Timer.periodic(widget.duration, (timer) {
      if (!mounted) return;

      if (charIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[charIndex];
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
