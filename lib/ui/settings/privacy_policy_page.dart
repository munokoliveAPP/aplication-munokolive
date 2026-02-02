import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munokolive_music/l10n/app_localizations.dart';

class PrivacyPolicyPage extends ConsumerWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      title: Builder(
                        builder: (context) => Text(
                          AppLocalizations.of(context)!.privacyTitleAppBar,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                            "1. COLLECTE DES DONNÉES (L’INTÉGRITÉ DES INFORMATIONS)",
                            "Pour garantir la sécurité de la communauté, nous collectons des informations essentielles :\n\n"
                                "Identité : Nom, prénom, date de naissance, photo de profil.\n\n"
                                "Contact : Numéro de téléphone (utilisé comme identifiant de parrainage), adresse e-mail.\n\n"
                                "Profil Ministériel : Église d’appartenance, catégorie (100%, Actif, Étudiant), instrument ou fonction ecclésiastique.\n\n"
                                "Localisation : Coordonnées GPS (uniquement pour le fonctionnement du Radar et du SOS).",
                          ),
                          _buildSection(
                            "2. UTILISATION DES DONNÉES (LE SERVICE AVANT TOUT)",
                            "Vos données sont utilisées strictement pour :\n\n"
                                "Le Matching : Permettre aux Pasteurs de trouver des musiciens proches via le Radar.\n\n"
                                "La Validation : Permettre à l'administration de vérifier l'authenticité de chaque membre.\n\n"
                                "Le Parrainage : Suivre les recommandations via votre numéro de téléphone pour l'attribution des étoiles.\n\n"
                                "La Communication : Envoi de notifications SOS et alertes de la communauté.",
                          ),
                          _buildSection(
                            "3. GÉOLOCALISATION ET MODE RADAR",
                            "Le système de traçage en direct est le cœur de Munokolive Music.\n\n"
                                "Votre position n'est visible que lorsque vous êtes en mode \"Disponible\" (Point Vert).\n\n"
                                "En passant en mode \"Indisponible\" (Point Rouge) ou en fermant l'application, votre position exacte est floutée ou masquée.\n\n"
                                "Protection : Munokolive Music ne vend JAMAIS vos données de localisation à des entreprises tierces.",
                          ),
                          _buildSection(
                            "4. SÉCURITÉ ET DROITS D'ADMINISTRATION",
                            "L'accès aux données sensibles est restreint à l'administrateur principal (Christian ANISONOK) et son bureau restreint.\n\n"
                                "Tout utilisateur peut demander la modification ou la suppression de ses données (sauf le nom et la catégorie, pour maintenir l'intégrité de la base de données).\n\n"
                                "En cas de suppression de compte, vos données sont anonymisées pour préserver l'historique des parrainages sans exposer votre identité.",
                          ),
                          _buildSection(
                            "5. LIMITATION DE RESPONSABILITÉ (VOTRE PROTECTION)",
                            "Munokolive Music est une plateforme de mise en relation.\n\n"
                                "Responsabilité Civile : M. Christian ANISONOK et l'équipe Munokolive Music ne sauraient être tenus responsables des incidents, litiges, ou comportements inappropriés survenant lors de rencontres physiques ou de prestations de services suite à une mise en relation sur l'application.\n\n"
                                "Vérification : Bien que l'administration valide les profils, chaque membre est invité à faire preuve de discernement chrétien lors de ses échanges.",
                          ),
                          _buildSection(
                            "6. PROTECTION CONTRE LE PIRATAGE",
                            "L'application utilise des protocoles de chiffrement avancés (SSL/TLS via Supabase). Toute tentative d'extraction de la base de données des membres par un utilisateur fera l'objet de poursuites pénales pour vol de propriété intellectuelle et violation de données privées.",
                          ),
                          _buildSection(
                            "7. SIGNATURE ET PROPRIÉTÉ",
                            "L’application, son concept, son code source et sa base de données sont la propriété intellectuelle exclusive de M. Christian ANISONOK. Toute reproduction, même partielle, est strictement interdite.",
                          ),
                          const SizedBox(height: 30),
                          _buildLegalMention(),
                          const SizedBox(
                            height: 100,
                          ), // Space for bottom padding
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(Icons.security, size: 60, color: Colors.white),
        const SizedBox(height: 20),
        Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.privacyHeaderTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.blueAccent.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (context) => Text(
            "${AppLocalizations.of(context)!.lastUpdateLabel} ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Builder(
          builder: (context) => Text(
            AppLocalizations.of(context)!.exclusivePropertyLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "La présente Politique de Confidentialité a pour but d'informer les membres de la plateforme Munokolive Music (Gospel Family) sur la manière dont leurs données sont collectées, protégées et utilisées. En utilisant cette application, vous acceptez les pratiques décrites ci-dessous.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
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
              color: Colors.cyanAccent, // Cyan/Blue style for Privacy
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.cyan, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalMention() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Builder(
            builder: (context) => Text(
              AppLocalizations.of(context)!.legalProtectionMentionTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "\"En utilisant Munokolive Music, vous reconnaissez que vous agissez en tant que membre de la famille Gospel et que les informations partagées le sont dans un but de fraternité et de service. L'administration se réserve le droit de bannir tout membre dont le comportement compromettrait la sécurité ou la réputation de la plateforme.\"",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
