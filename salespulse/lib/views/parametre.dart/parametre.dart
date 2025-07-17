// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/login_view.dart';
import 'package:salespulse/views/auth/update_password.dart';
import 'package:salespulse/views/parametre.dart/facture_setting_page.dart';
import 'package:salespulse/views/profil/logo_entreprise.dart';
import 'package:salespulse/views/profil/update_profil.dart';

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        title: const Text(
          'Paramètres',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paramètres',
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Gérez les données de base et la configuration de votre application',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _settings(context).length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: isWide ? 5 : 1.9,
                  ),
                  itemBuilder: (context, index) => _settings(context)[index],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _settings(BuildContext context) {
    return [
      _buildSettingCard(
        context,
        icon: Iconsax.building,
        title: 'Infos Entreprise',
        description: 'Gérez le nom, l\'adresse de votre société',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const UpdateProfil())),
      ),
      _buildSettingCard(
        context,
        icon: Iconsax.setting,
        title: 'Sécurisation de compte',
        description: 'Vous pouvez modifier le mot de passe  ',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const UpdatePassword())),
      ),
      _buildSettingCard(
        context,
        icon: Iconsax.document,
        title: 'Logos',
        description: 'Personnalisez le logo de votre entreprise',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const LogoEntrepriseScreen())),
      ),
      _buildSettingCard(
        context,
        icon: Iconsax.category,
        title: 'Gestion des factures',
        description: "Personnalisez la facture",
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const FactureSettingsPage())),
      ),
      
      _buildSettingCard(
        context,
        icon: Iconsax.profile_delete,
        title: 'Suppression definitive',
        description: 'Supprimer votre compte',
        onTap: () => _confirmAccountDeletion(context),
      ),
    ];
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 24, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Iconsax.arrow_right,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAccountDeletion(BuildContext context) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text(
            "Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible. Vous perdrez toutes vos données."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Appel API
              final success = await ServicesAuth().deleteAdminCounts(token);

              if (success.statusCode == 200) {
                // Déconnexion + redirection vers login
                Provider.of<AuthProvider>(context, listen: false)
                    .logoutButton();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Compte supprimé avec succès")),
                  );

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginView()),
                    (route) => false,
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Échec de la suppression du compte")),
                  );
                }
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
