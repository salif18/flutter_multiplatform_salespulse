// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:salespulse/views/auth/update_password.dart';
import 'package:salespulse/views/profil/logo_entreprise.dart';
import 'package:salespulse/views/profil/update_profil.dart';

class ParametresPage extends StatelessWidget {
  const ParametresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(onPressed:()=> Navigator.pop(context), icon:const Icon(Icons.arrow_back_ios_rounded, color: Colors.white,)),
        backgroundColor: Colors.blueGrey,
        title: const Text('Paramètres',
            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gérez les données de base et la configuration de votre application',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 4 : 1.1,
              children: [
                _buildSettingCard(
                  context,
                  icon: Iconsax.building,
                  title: 'Infos Entreprise',
                  description: 'Gérez le nom, l\'adresse et le logo de votre société',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=> const UpdateProfil()))),
                
                _buildSettingCard(
                  context,
                  icon: Iconsax.setting,
                  title: 'Securisation de compte',
                  description: 'Vous pouvez modifier le mot de passe de votre compte pour plus de securité',
                  onTap: () =>  Navigator.push(context, MaterialPageRoute(builder: (context)=> const UpdatePassword()))),
                
                _buildSettingCard(
                  context,
                  icon: Iconsax.document,
                  title: 'Documents',
                  description: 'Personnalisez le logo de votre entreprise',
                  onTap: () =>  Navigator.push(context, MaterialPageRoute(builder: (context)=> const LogoEntrepriseScreen()))),
                
                _buildSettingCard(
                  context,
                  icon: Iconsax.tag,
                  title: 'Gestion des Marques',
                  description: 'Ajoutez et modifiez les marques de produits',
                  onTap: () => _navigateTo(context, '/marques')),
                
                _buildSettingCard(
                  context,
                  icon: Iconsax.category,
                  title: 'Gestion des Types',
                  description: 'Gérez les catégories d\'articles',
                  onTap: () => _navigateTo(context, '/categories')),
                
                _buildSettingCard(
                  context,
                  icon: Iconsax.shop,
                  title: 'Entrepôts Spéciaux',
                  description: 'Désignez les entrepôts pour les retours et autres fonctions',
                  onTap: () => _navigateTo(context, '/entrepots')),
              ],
            ),
          ],
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 24,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
              const SizedBox(height: 8),
              Text(description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      )),
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(Iconsax.arrow_right,
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _confirmAccountDeletion(context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text(
            "Voulez-vous vraiment supprimer votre compte ? Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}