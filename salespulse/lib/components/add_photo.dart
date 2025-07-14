// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/profil_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/profil_api.dart';

class PikedPhoto extends StatefulWidget {
  const PikedPhoto({super.key});

  @override
  State<PikedPhoto> createState() => _PikedPhotoState();
}

class _PikedPhotoState extends State<PikedPhoto> {
  final ServicesProfil api = ServicesProfil();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  ProfilModel? profil;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    try {
      final res = await api.getProfils(token);
      if (res.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          profil = ProfilModel.fromJson(res.data["profils"]);
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

  Future<void> _updatePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final imageFile = File(picked.path);
    setState(() {
      selectedImage = imageFile;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
     final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    try {
      final formData = FormData.fromMap({
        "userId": userId,
        "adminId":adminId,
        "image": await MultipartFile.fromFile(imageFile.path,
            filename: imageFile.path.split('/').last),
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
    return Stack(
      children: [
        GestureDetector(
          onTap: _updatePhoto,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 100,
              height: 80,
              child: selectedImage != null
                  ? AspectRatio(aspectRatio: 8/3.5,child: Image.file(selectedImage!, fit: BoxFit.cover))
                  : (profil?.image != null && profil!.image!.isNotEmpty
                      ? AspectRatio(
                        aspectRatio: 8/3.5,
                        child: Image.network(profil!.image!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset("assets/logos/logo1.png");
                            }),
                      )
                      : Image.asset("assets/logos/logo1.png")),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton(
            onPressed: _updatePhoto,
            icon: CircleAvatar(
              backgroundColor: Colors.grey[400]!.withOpacity(0.8),
              
              child: const Icon(
                Icons.edit,
                size: 20,
                color: Colors.black,
              ),
            ),
            tooltip: "Modifier la photo",
          ),
        )
      ],
    );
  }
}
