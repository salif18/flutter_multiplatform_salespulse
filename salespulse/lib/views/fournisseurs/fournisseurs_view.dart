import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/fournisseurs_model.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/fournisseur_api.dart';
import 'package:salespulse/utils/app_size.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class FournisseurView extends StatefulWidget {
  const FournisseurView({super.key});

  @override
  State<FournisseurView> createState() => _FournisseurViewState();
}

class _FournisseurViewState extends State<FournisseurView> {
  ServicesFournisseurs api = ServicesFournisseurs();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<FournisseurModel>> _listFournisseurs =
      StreamController<List<FournisseurModel>>();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _numero = TextEditingController();
  final _address = TextEditingController();
  final _produit = TextEditingController();

  @override
  void initState() {
    _getfournisseurs();
    super.initState();
  }

  @override
  void dispose() {
    _listFournisseurs.close();
    _prenom.dispose();
    _nom.dispose();
    _numero.dispose();
    _address.dispose();
    _produit.dispose();
    super.dispose();
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getfournisseurs() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.getFournisseurs(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final fournisseurs = (body["fournisseurs"] as List)
              .map((json) => FournisseurModel.fromJson(json))
              .toList();
          _listFournisseurs.add(fournisseurs);
        });
      }
    } catch (e) {
      Exception(e); // Ajout d'une impression pour le debug
    }
  }

//SUPPRIMER CATEGORIE API
  Future<void> _removeFournisseur(id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteFournisseurs(id, token);
      final body = res.data;
      if (res.statusCode == 200) {
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _getfournisseurs(); // Actualiser la liste des catégories
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
          // 👉 Afficher message spécifique abonnement expiré
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Abonnement expiré"),
              content: const Text(
                  "Votre abonnement a expiré. Veuillez le renouveler."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AbonnementScreen()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return;
        }
      }

      // 🚫 Autres DioException (ex: réseau)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Problème de connexion : Vérifiez votre Internet.",
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
      );
    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
        "Le serveur ne répond pas. Veuillez réessayer plus tard.",
        style: GoogleFonts.poppins(fontSize: 14),
      )));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      debugPrint(e.toString());
    }
  }

//AJOUTER CATEGORIE API
  Future<void> _sendToserver(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    if (_globalKey.currentState!.validate()) {
      final data = {
        "userId": userId,
        "adminId": adminId,
        "prenom": _prenom.text,
        "nom": _nom.text,
        "numero": _numero.text,
        "address": _address.text,
        "produit": _produit.text
      };
      try {
        showDialog(
          context: context,
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        );
        final res = await api.postFournisseur(data, token);
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog

        if (res.statusCode == 201) {
          // ignore: use_build_context_synchronously
          // api.showSnackBarSuccessPersonalized(context, res.data["message"]);
          _getfournisseurs();
        } else {
          // ignore: use_build_context_synchronously
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        Navigator.pop(context); // Fermer le dialog
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, e.toString());
      }
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _getfournisseurs();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutButton();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Vérification initiale de l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!authProvider.isAuthenticated && mounted) {
        await _handleLogout(context);
      }
    });

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white, //const Color(0xff001c30),
            expandedHeight: 50, // Augmentation de la hauteur
            pinned: true,
            floating: true,
             automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Mes fournisseurs",
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          // Utiliser un SliverList à la place d'un ListView.builder pour éviter les conflits de défilement
          StreamBuilder<List<FournisseurModel>>(
            stream: _listFournisseurs.stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverFillRemaining(
                  child: Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.orange, size: 50)),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                    child: Center(
                        child: Container(
                  padding: const EdgeInsets.all(8),
                  height: MediaQuery.of(context).size.width * 0.4,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Column(
                                children: [
                                  Image.asset("assets/images/erreur.png",
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover),
                                  const SizedBox(height: 20),
                                  Text(
                                    "Erreur de chargement des données. Verifier votre réseau de connexion. Réessayer en tirant l'ecrans vers le bas!!",
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ))),
                      const SizedBox(width: 40),
                      IconButton(
                          onPressed: () {
                            _refresh();
                          },
                          icon: const Icon(Icons.refresh_outlined,
                              size: AppSizes.iconLarge))
                    ],
                  ),
                )));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                    child: Center(
                        child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset("assets/images/not_data.png",
                        width: 200, height: 200, fit: BoxFit.cover),
                    const SizedBox(height: 20),
                    Text(
                      "Pas de données disponibles",
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w400),
                    ),
                  ],
                )));
              } else {
                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      child: LayoutBuilder(builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minWidth: constraints.maxWidth),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: DataTable(
                                columnSpacing: 20,
                                headingRowHeight: 35,
                                headingRowColor:
                                    WidgetStateProperty.all(Colors.blueGrey),
                                headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                columns: [
                                  DataColumn(
                                      label: Text(
                                    'PHOTO',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )),
                                  DataColumn(
                                      label: Text('NOM',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('TEL',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('PRODUIT',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('ADRESSE',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('ACTION',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                ],
                                rows: snapshot.data!.map((fournisseur) {
                                  return DataRow(
                                    cells: [
                                      // Logo
                                      DataCell(
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ClipOval(
                                              child: Image.asset(
                                            "assets/images/profil_default.png",
                                            width: 50,
                                            height: 50,
                                          )),
                                        ),
                                      ),

                                      // Nom
                                      DataCell(Text(
                                        fournisseur.prenom,
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                        ),
                                      )),

                                      // Tél
                                      DataCell(
                                          Text(fournisseur.numero.toString(),
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                              ))),

                                      // Produit
                                      DataCell(Text(fournisseur.produit,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                          ))),

                                      // Adresse
                                      DataCell(Text(fournisseur.address,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                          ))),

                                      // Action (supprimer)
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(
                                              Icons.person_remove_alt_1,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm =
                                                await showRemoveFournisseur(
                                                    context);
                                            if (confirm == true) {
                                              _removeFournisseur(
                                                  fournisseur.id);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
        onPressed: () {
          _addFournisseurShow(context);
        },
        child: const Icon(
          Icons.add,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

void _addFournisseurShow(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 500;

      return AlertDialog(
        title: Center(
          child: Text(
            "Ajouter catégories",
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        content: SingleChildScrollView( // pour permettre le scroll sur petits écrans
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 400,
            ),
            child: Form(
              key: _globalKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    controller: _prenom,
                    hint: "Prénom du fournisseur",
                    icon: Icons.person,
                    validatorText: "Veuillez entrer le prénom du fournisseur",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nom,
                    hint: "Nom du fournisseur",
                    icon: Icons.person,
                    validatorText: "Veuillez entrer le nom du fournisseur",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _numero,
                    hint: "Numéro du fournisseur",
                    icon: Icons.phone,
                    inputType: TextInputType.number,
                    validatorText: "Veuillez entrer le numéro du fournisseur",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _produit,
                    hint: "Nom du produit",
                    icon: Icons.article_rounded,
                    validatorText: "Veuillez entrer le nom du produit",
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _address,
                    hint: "Adresse du fournisseur",
                    icon: Icons.location_on,
                    validatorText: "Veuillez entrer l'adresse du fournisseur",
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_globalKey.currentState!.validate()) {
                          _sendToserver(context);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 136, 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        "Enregistrer",
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  required String validatorText,
  TextInputType inputType = TextInputType.text,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: inputType,
    validator: (value) {
      if (value == null || value.isEmpty) {
        return validatorText;
      }
      return null;
    },
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.roboto(fontSize: 14),
      prefixIcon: Icon(icon, size: 24, color: Colors.purpleAccent),
    ),
  );
}

// FENTRE DIALOGUE POUR CONFIRMER LA SUPPRESSION
  Future<bool> showRemoveFournisseur(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmer"),
          content: const Text(
              "Êtes-vous sûr de vouloir supprimer cette catégorie ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Annuler",
                  style: GoogleFonts.roboto(
                      fontSize: 14, color: Colors.blueAccent)),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Supprimer",
                  style: GoogleFonts.roboto(fontSize: 14, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
