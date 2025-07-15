// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

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
  ProfilModel? profil;


@override
  void initState() {
    super.initState();
    _loadProfil();
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
          provider.saveProfilData(profil);
      }
    } catch (e) {
      debugPrint("Erreur chargement profil: $e");
    }
  }

  
  
  @override
  Widget build(BuildContext context) {
     
    return Consumer<AuthProvider>(
  builder: (context, provider, _) {
    final profil = provider.profil;
    return  ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 100,
        height: 80,
        child: (profil?.image != null && profil!.image!.isNotEmpty)
                ? AspectRatio(
                  aspectRatio: 8/3.5,
                  child: Image.network(provider.profil!.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset("assets/logos/logo1.png");
                      }),
                )
                : Image.asset("assets/logos/logo1.png"),
      ),
    );
  });
   
  }
}
