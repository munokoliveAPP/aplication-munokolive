import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Fonction pour ouvrir WhatsApp ou Email
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.aboutTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D0036), // Deep Purple
              Colors.black,
              Colors.deepPurple.shade900.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo & Slogan
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.purpleAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purpleAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/Logo.png',
                                width: 60,
                                height: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.appNameTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.appSlogan,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.cyanAccent.withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Sections
                      _buildSection(
                        icon: Icons.star,
                        title: AppLocalizations.of(context)!.sectionEssenceTitle,
                        content:
                            "Munokolive Music n’est pas une simple application de rencontre musicale. C’est l’écosystème numérique de la plateforme Gospel Family Munokolive.\n\nContrairement aux plateformes standards, nous ne formons pas seulement des exécutants pour des concerts. Nous bâtissons une Fraternité de Lévites. Nous sommes un espace sacré où les chanteurs et instrumentistes chrétiens tissent des liens familiaux indestructibles pour devenir les fers de lance de l’Évangile du Christ.",
                        color: Colors.amber,
                      ),

                      _buildSection(
                        icon: Icons.visibility,
                        title: AppLocalizations.of(context)!.sectionVisionTitle,
                        subtitle: AppLocalizations.of(context)!.sectionVisionSubtitle,
                        content:
                            "La \"Vision du futur à long terme vers l’horizon\" est née d’une méditation profonde du Président Fondateur, Christian ANISONOK.\n\nFace aux défis que rencontrent les musiciens chrétiens pour vivre de leur talent sans compromettre leur foi, une équipe de jeunes engagés a décidé de créer cet outil. Notre but est clair : offrir une sécurité, une visibilité et un cadre professionnel aux serviteurs de Dieu, de leurs premiers pas d'étudiants jusqu'à leur plein épanouissement dans le ministère.",
                        color: Colors.cyan,
                      ),

                      _buildSection(
                        icon: Icons.church,
                        title: AppLocalizations.of(context)!.sectionOrganizationTitle,
                        subtitle: AppLocalizations.of(context)!.sectionOrganizationSubtitle,
                        content:
                            "Chez Munokolive, l'ordre et la discipline sont les piliers de l'onction. Nous organisons notre famille en trois catégories de destin :\n\n• Les “100%” : Les lévites dévoués corps et âme à l'art musical sacré.\n• Les Actifs Multi-Talents : Ceux qui servent Dieu par la musique tout en excellant dans l'administration et le monde professionnel.\n• Les Étudiants & Apprentis : La relève de demain, encadrée et soutenue.\n\nChaque membre est rattaché à un département (Guitaristes, Pianistes, Batteurs, Chantres) géré par un bureau efficace de 8 organes, garantissant que personne n'est laissé pour compte.",
                        color: Colors.purpleAccent,
                      ),

                      _buildSection(
                        icon: Icons.bolt,
                        title: AppLocalizations.of(context)!.sectionTechTitle,
                        subtitle: AppLocalizations.of(context)!.sectionTechSubtitle,
                        content:
                            "Nous avons doté Munokolive Music d'une intelligence de pointe pour que le service de Dieu ne soit plus jamais freiné par la distance ou l'oubli :\n\n📡 Radar SOS : Trouvez un instrumentiste disponible en moins de 2 minutes dans un rayon de 10 km.\n🤖 Super Agent Muno-IA : Un guide intelligent qui accompagne chaque membre dans sa progression et son parrainage.\n⭐ Système d'Étoiles : Une valorisation basée sur la fidélité, la ponctualité et la recommandation par les pairs.\n💬 Salons de Tchat Privés : Des espaces d'échange par instrument pour grandir ensemble.",
                        color: Colors.blueAccent,
                      ),

                      _buildSection(
                        icon: Icons.balance,
                        title: AppLocalizations.of(context)!.sectionGoldenRuleTitle,
                        subtitle: AppLocalizations.of(context)!.sectionGoldenRuleSubtitle,
                        content:
                            "Dans l'univers Munokolive, tous les membres sont égaux. La moquerie est bannie, l'encouragement est la norme. Nous ne sommes pas des concurrents, nous sommes une armée.",
                        color: Colors.greenAccent,
                      ),

                      const SizedBox(height: 20),
                      // Founder Quote
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.format_quote,
                              color: Colors.white54,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.founderQuoteText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.founderSignature,
                                style: const TextStyle(
                                  color: Colors.purpleAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      // Contact Section
                      _buildContactSection(),

                      const SizedBox(height: 40),
                      // Copyright
                      Center(
                        child: Text(
                          "© ${DateTime.now().year} Munokolive Music\nVersion 1.0.0",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    String? subtitle,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: color.withValues(alpha: 0.3), width: 2),
              ),
            ),
            child: Text(
              content,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "NOUS CONTACTER",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Besoin d'aide ou envie de soumettre un projet ?",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactTile(
            icon: Icons.chat,
            title: "WhatsApp Officiel",
            subtitle: "Discussion directe avec l'admin",
            color: Colors.green,
            onTap: () => _launchUrl(
              "https://wa.me/2250777916407",
            ), // Replace with actual number
          ),
          const SizedBox(height: 16),
          _buildContactTile(
            icon: Icons.email,
            title: "Email",
            subtitle: "info@munokolive.online",
            color: Colors.blue,
            onTap: () => _launchUrl("mailto:info@munokolive.online"),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Direction : Bureau Gospel Family Munokolive",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
