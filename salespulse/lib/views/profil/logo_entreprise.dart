import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/profil_model.dart';
import 'dart:io';

import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/profil_api.dart';

class LogoEntrepriseScreen extends StatefulWidget {
  const LogoEntrepriseScreen({super.key});

  @override
  State<LogoEntrepriseScreen> createState() => _LogoEntrepriseScreenState();
}

class _LogoEntrepriseScreenState extends State<LogoEntrepriseScreen> {
   final ServicesProfil api = ServicesProfil();
  ProfilModel? profil;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _loadProfil() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<AuthProvider>(context, listen: false);
    try {
      final res = await api.getProfils(token);
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          profil = ProfilModel.fromJson(res.data["profils"]);
        });
         await provider.saveProfilData(profil);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

  Future<void> _updatePhoto() async {

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
     final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    try {
      final formData = FormData.fromMap({
        "userId": userId,
        "adminId":adminId,
        "image": await MultipartFile.fromFile(_selectedImage!.path,
            filename: _selectedImage!.path.split('/').last),
      });

      final res = await api.postProfil(formData, token);
      if (res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Image mise à jour')),
        );
        _loadProfil(); // Refresh
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du téléchargement : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
         leading: IconButton(onPressed:()=> Navigator.pop(context), icon:const Icon(Icons.arrow_back_ios_rounded, color: Colors.white,)),
        backgroundColor: Colors.blueGrey,
        title: Text('Modifier le Logo', 
               style: GoogleFonts.roboto(fontSize: 18,color: Colors.white,fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Logo actuel',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 16),
            
            // Affichage du logo actuel ou du nouveau sélectionné
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.business, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            
            // Boutons d'action
            SizedBox(
              width: 800,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      onPressed: _takePhoto,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
                    const SizedBox(height: 8),
                     if (_selectedImage != null)
            SizedBox(
              width: 400,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  shape: RoundedRectangleBorder( 
                    borderRadius: BorderRadius.circular(10)
                  ),
                  maximumSize: const Size(400, 40)
                ),
                onPressed: _updatePhoto,
                child: const Text('Enregistrer',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            
            // Recommandations
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text('Recommandations',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700)),
                      ],
                    ),
            
                    Text('- Format PNG ou JPG\n'
                        '- Taille minimale 300x300 px\n'
                        '- Fond transparent recommandé',
                        style: TextStyle(color: Colors.blue.shade800)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}