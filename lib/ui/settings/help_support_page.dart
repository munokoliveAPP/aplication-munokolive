import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'cgu_page.dart';
import 'privacy_policy_page.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';
import 'package:munokolive_music/ui/theme/app_theme.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  // Fonction pour ouvrir WhatsApp ou Email
  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      debugPrint('Could not launch $url');
    }
  }

  void _clearCache() {
    // Simuler un nettoyage de cache
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.cacheCleared),
        backgroundColor: Colors.green,
      ),
    );
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
            AppLocalizations.of(context)!.helpSupportTitle,
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
              const Color(0xFF002033), // Deep Blue/Green
              Colors.black,
              Colors.blueAccent.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Slogan
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.support_agent,
                                size: 50,
                                color: Colors.cyanAccent,
                              ),
                              const SizedBox(height: 10),
                              Builder(
                                builder: (context) => Text(
                                  AppLocalizations.of(context)!.supportHeaderTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Builder(
                                builder: (context) => Text(
                                  AppLocalizations.of(context)!.supportHeaderSlogan,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 1. Assistance IA
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.sectionAiTitle,
                        Icons.smart_toy,
                      ),
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Avant de contacter un administrateur, parlez à notre agent intelligent.",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.purple,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                "Muno-IA Guide",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: const Text(
                                "Cliquez sur la bulle animée en bas de votre écran pour poser une question.",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.format_quote,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Exemple : \"Muno, comment changer mon église d'appartenance ?\"",
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. FAQ
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.sectionFaqTitle,
                        Icons.quiz,
                      ),
                      _buildFaqItem(
                        "A. Pourquoi mon compte n'est-il pas encore validé ?",
                        "Chaque profil est vérifié manuellement par le bureau Gospel Family pour garantir l'intégrité de la communauté. Cela peut prendre entre 2 et 24 heures. Passé ce délai, contactez le secrétariat.",
                      ),
                      _buildFaqItem(
                        "B. Comment gagner ma première étoile ?",
                        "C'est simple : invitez 10 frères ou sœurs à rejoindre Munokolive. Donnez-leur votre numéro de téléphone (identifiant de parrainage). Dès qu'ils s'inscrivent avec votre numéro, l'algorithme calcule vos points.",
                      ),
                      _buildFaqItem(
                        "C. Le Radar ne m'affiche personne, que faire ?",
                        "• Vérifiez que votre GPS est activé.\n• Augmentez le rayon de recherche (5km, 10km, 20km).\n• Assurez-vous d'avoir sélectionné une catégorie précise (ex: Bassiste).",
                      ),
                      _buildFaqItem(
                        "D. Je suis indisponible, comment l'indiquer ?",
                        "Allez sur votre profil et basculez le bouton de statut sur ROUGE. Vous ne recevrez plus de notifications SOS et vous ne serez plus tracé sur la carte.",
                      ),

                      // 3. Contacter le bureau
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.sectionContactTitle,
                        Icons.contact_phone,
                      ),
                      _buildCard(
                        child: Column(
                          children: [
                            const Text(
                              "Si vous ne trouvez pas de solution, notre équipe est là pour vous accompagner.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // WhatsApp Button
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _launchUrl("https://wa.me/2250777916407"),
                              icon: const Icon(Icons.chat_bubble),
                              label: Text(AppLocalizations.of(context)!.supportWhatsappButton),
                              style: AppTheme.ctaElevated(Colors.green, Colors.greenAccent),
                            ),
                            const SizedBox(height: 10),
                            // Bouton d'Appel Direct (Bonus)
                            OutlinedButton.icon(
                              onPressed: () => _launchUrl("tel:+2250777916407"),
                              icon: const Icon(Icons.call, color: Colors.white70),
                              label: Text(AppLocalizations.of(context)!.callAdminButton),
                              style: AppTheme.ctaOutlined(Colors.white70),
                            ),
                            const SizedBox(height: 5),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.urgentValidationsHint,
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 30),
                            _buildContactRow(
                              Icons.email,
                              AppLocalizations.of(context)!.supportEmailLabel,
                              "info@munokolive.online",
                              () => _launchUrl("mailto:info@munokolive.online"),
                            ),
                            const SizedBox(height: 10),
                            _buildContactRow(
                              Icons.report_problem,
                              AppLocalizations.of(context)!.emergencyReportLabel,
                              AppLocalizations.of(context)!.emergencyReportSubtitle,
                              () => _launchUrl(
                                "mailto:abuse@munokolive.online?subject=SIGNALEMENT URGENT&body=Veuillez décrire l'incident ici...",
                              ),
                              isWarning: true,
                            ),
                          ],
                        ),
                      ),

                      // 4. Centre de Diagnostic
                      const SizedBox(height: 20),
                      _buildSectionHeader(
                        AppLocalizations.of(context)!.sectionDiagnosticTitle,
                        Icons.build,
                      ),
                      _buildCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Builder(
                                  builder: (context) => Text(
                                    AppLocalizations.of(context)!.appVersionLabel,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    "v1.0.0 (Bêta)",
                                    style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Builder(
                                  builder: (context) => Text(
                                    AppLocalizations.of(context)!.serverStatusLabel,
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Builder(
                                      builder: (context) => Text(
                                        AppLocalizations.of(context)!.serverOperational,
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _clearCache,
                                icon: const Icon(Icons.cleaning_services),
                                label: Text(AppLocalizations.of(context)!.cacheCleared),
                                style: AppTheme.ctaOutlined(Colors.orangeAccent),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Builder(
                              builder: (context) => Text(
                                AppLocalizations.of(context)!.usefulIfImagesMessage,
                                style: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 5. Liens Légaux
                      const SizedBox(height: 20),
                      _buildSectionHeader("5. LIENS LÉGAUX", Icons.gavel),
                      _buildCard(
                        child: Column(
                          children: [
                            _buildLegalLink(
                              "Conditions Générales d'Utilisation",
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CguPage(),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10),
                            _buildLegalLink(
                              "Politique de Confidentialité",
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PrivacyPolicyPage(),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10),
                            _buildLegalLink(
                              "Charte de la Famille Gospel",
                              () {}, // Placeholder
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 18),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: child,
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        collapsedIconColor: Colors.white54,
        iconColor: Colors.cyanAccent,
        backgroundColor: Colors.white.withValues(alpha: 0.02),
        collapsedBackgroundColor: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(
            answer,
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isWarning = false,
  }) {
    final color = isWarning ? Colors.redAccent : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const Icon(Icons.open_in_new, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
