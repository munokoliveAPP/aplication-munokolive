import 'package:flutter/material.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Aide & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle("Questions Fréquentes (FAQ)"),
              const SizedBox(height: 12),
              _buildFaqItem(
                "Comment changer ma photo de profil ?",
                "Allez dans votre profil, cliquez sur l'icône de crayon (Modifier), puis touchez l'icône d'appareil photo sur votre avatar.",
              ),
              _buildFaqItem(
                "Comment ajouter un lieu ?",
                "Dans l'onglet 'Lieux', appuyez sur le bouton '+' en bas à droite. Remplissez les informations et ajoutez des photos.",
              ),
              _buildFaqItem(
                "C'est quoi le Mode Fantôme ?",
                "Le Mode Fantôme (dans Paramètres > Confidentialité) vous rend invisible sur la carte pour les autres utilisateurs tout en vous permettant de voir les lieux.",
              ),
              _buildFaqItem(
                "Comment gagner des points ?",
                "Vous gagnez des points en visitant des lieux, en participant à des événements et en complétant votre profil.",
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Nous Contacter"),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                icon: Icons.email_outlined,
                title: "Support Email",
                subtitle: "Réponse sous 24h",
                action: "Envoyer",
                onTap: () => _launchEmail(),
              ),
              const SizedBox(height: 12),
              _buildContactCard(
                context,
                icon: Icons.chat_bubble_outline,
                title: "WhatsApp Support",
                subtitle: "Chat direct avec l'équipe",
                action: "Discuter",
                color: Colors.green,
                onTap: () => _launchWhatsApp(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.support_agent,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          const Text(
            "Besoin d'aide ?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Notre équipe est là pour vous accompagner dans votre expérience MunokoLive.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        iconColor: AppTheme.primaryColor,
        collapsedIconColor: Colors.white70,
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
    Color color = AppTheme.primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontSize: 16,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/2250777916407");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp');
    }
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri(
      scheme: 'mailto',
      path: 'support@munokolive.com',
      query: 'subject=Support MunokoLive App',
    );
    if (!await launchUrl(url)) {
      debugPrint('Could not launch Email');
    }
  }
}
