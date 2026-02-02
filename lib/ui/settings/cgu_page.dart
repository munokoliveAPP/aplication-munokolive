import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/providers/cgu_provider.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class CguPage extends ConsumerStatefulWidget {
  const CguPage({super.key});

  @override
  ConsumerState<CguPage> createState() => _CguPageState();
}

class _CguPageState extends ConsumerState<CguPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _acceptCgu() async {
    // Surprise Animation
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.purpleAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 60, color: Colors.amber),
                const SizedBox(height: 20),
                Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.welcomeFamilyDialogTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.welcomeFamilyDialogSubtitle,
                  textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      // Trigger the state change which will rebuild Main and remove this page
      ref.read(cguProvider.notifier).acceptCgu();
    });

    _controller.forward();
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context); // Close the dialog
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              const Color(0xFF1A0033), // Darker deep purple
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      floating: true,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      title: const Text(
                        "CGU Munokolive Music",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildHeader(),
                          const SizedBox(height: 30),
                          _buildSection(
                            "1. PRÉSENTATION DE L'APPLICATION",
                            "L'application Munokolive Music, émanation technologique de la plateforme Gospel Family Munokolive, est un espace exclusivement réservé aux chantres, musiciens instrumentistes et leaders chrétiens. Notre mission est de connecter le talent à l’onction pour bâtir une fraternité efficace au service de l’Évangile du Christ.",
                          ),
                          _buildSection(
                            "2. ADHÉSION ET ÉLIGIBILITÉ",
                            "L’accès à Munokolive Music est un privilège et non un droit.\n\n"
                                "Identité : L'utilisateur doit être un chrétien engagé, qu'il soit musicien (pianiste, batteur, guitariste, chantre, etc.) ou homme de Dieu (pasteur, apôtre, évangéliste, etc.).\n\n"
                                "Validation : Chaque inscription est soumise à une validation manuelle par l’administration. L’accès aux fonctionnalités (Radar, SOS, Salons) n'est ouvert qu'après confirmation du profil.\n\n"
                                "Engagement : En rejoignant Munokolive Music, vous adhérez à la \"Vision du futur à long terme vers l’horizon\" portée par le Président Fondateur Christian ANISONOK.",
                          ),
                          _buildSection(
                            "3. CATÉGORISATION DES MEMBRES",
                            "Afin d'assurer un encadrement professionnel et spirituel, chaque membre doit s'identifier selon l'une des trois catégories suivantes :\n\n"
                                "Les “100 pourcents” : Professionnels vivant exclusivement de l'art musical.\n\n"
                                "Les membres actifs : Travailleurs ou entrepreneurs exerçant la musique en complément.\n\n"
                                "Les membres étudiants : Élèves et étudiants en formation.",
                          ),
                          _buildSection(
                            "4. CODE DE CONDUITE ET RÈGLE D’OR",
                            "Munokolive Music repose sur une règle unique et absolue : LE RESPECT MUTUEL.\n\n"
                                "Zéro Moquerie : Il est strictement interdit de se moquer des autres membres, quel que soit leur niveau technique ou spirituel.\n\n"
                                "Égalité : Tous les membres sont égaux devant Dieu et dans l'application.\n\n"
                                "Discipline : Tout non-respect des statuts, toute fraude sur l'identité ou comportement contraire à l'éthique chrétienne entraînera une radiation immédiate sans préavis.",
                          ),
                          _buildSection(
                            "5. UTILISATION DES SERVICES (RADAR & SOS)",
                            "SOS Urgent : La fonction SOS est destinée à faciliter le service dans l'œuvre de Dieu. Elle doit être utilisée avec intégrité et sérieux.\n\n"
                                "Géolocalisation : Pour permettre le fonctionnement du Radar, l'utilisateur accepte le partage de sa position géographique. Munokolive Music s'engage à protéger ces données et à ne les utiliser que pour la mise en relation entre membres.\n\n"
                                "Disponibilité : Le bouton de statut (Vert/Rouge) doit refléter la réalité de votre disponibilité pour le service.",
                          ),
                          _buildSection(
                            "6. ORGANISATION ET DÉPARTEMENTS",
                            "Chaque membre de la catégorie \"Musicien\" est rattaché à un département (Pianistes, Batteurs, Chantres, etc.) sous l'autorité d'un responsable de département.\n\n"
                                "L'intégration aux salons de tchat spécifiques est automatique.\n\n"
                                "Chaque membre a le devoir de prendre contact avec son responsable pour comprendre son rôle au sein de la famille.",
                          ),
                          _buildSection(
                            "7. PROPRIÉTÉ INTELLECTUELLE ET PROTECTION",
                            "L’application Munokolive Music, son design, ses algorithmes et sa marque sont la propriété exclusive de M. Christian ANISONOK. Toute tentative de clonage, de piratage ou d'utilisation détournée des données de la fraternité fera l'objet de poursuites judiciaires.",
                          ),
                          _buildSection(
                            "8. RESPONSABILITÉ ET SÉCURITÉ",
                            "L'utilisateur est responsable de la confidentialité de ses identifiants. Munokolive Music décline toute responsabilité en cas de litiges personnels entre membres lors des rencontres physiques ou des services d'églises. Nous encourageons la vigilance et la crainte de Dieu dans chaque interaction.",
                          ),
                          _buildSection(
                            "9. MODIFICATIONS DES CONDITIONS",
                            "L’administration se réserve le droit de modifier les présentes conditions pour rester fidèle à l’évolution de la vision. Les membres seront informés de toute mise à jour via les notifications de l'application.",
                          ),
                          const SizedBox(height: 30),
                          _buildSpecialMention(),
                          const SizedBox(height: 100), // Space for button
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              _buildAcceptButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Icon(Icons.gavel_rounded, size: 60, color: Colors.white),
        const SizedBox(height: 20),
        Text(
          l10n.cguHeaderTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.purpleAccent,
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.cguVersionLine,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.purpleAccent, // Neon Magenta style
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.purple, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8), // White opacity 0.8
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialMention() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            "MENTION SPÉCIALE DU PRÉSIDENT FONDATEUR",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "\"Cette stratégie de la vision du futur à long terme est une préparation pour les années de gloire qui suivront. Soyons vigilants, travaillons avec rigueur et bâtissons ensemble cet horizon futur par la grâce de Dieu.\"",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Christian ANISONOK\nPrésident Fondateur Munokolive Music / Gospel Family",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "En cliquant sur \"J'accepte\", vous confirmez avoir lu, compris et accepté de vous soumettre à la vision et aux règles de la fraternité Munokolive Music.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _acceptCgu,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Colors.purpleAccent, width: 2),
                ),
              ),
              child: const Text(
                "J'ACCEPTE LA VISION",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
