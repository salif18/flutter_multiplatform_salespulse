import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/client_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/client_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  ServicesClients api = ServicesClients();
  final formData = FormData();
  final GlobalKey<ScaffoldState> drawerKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final StreamController<List<ClientModel>> _listClients =
      StreamController<List<ClientModel>>();

  final ImagePicker _picker = ImagePicker();
  File? documentFile;

  // Contrôleurs de formulaire pour ajout de client
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  final TextEditingController _creditTotal = TextEditingController();
  final TextEditingController _montantPaye = TextEditingController();
  final TextEditingController _reste = TextEditingController();
  final TextEditingController _monnaie = TextEditingController();
  final TextEditingController _recommandation = TextEditingController();
  final TextEditingController _address = TextEditingController();


// Statut sélectionné par défaut
  String _statut = "actif";

  @override
  void initState() {
    _getClients();
    super.initState();
  }

  @override
  void dispose() {
    _listClients.close();
    _nom.dispose();
    _contact.dispose();
    _creditTotal.dispose();
    _montantPaye.dispose();
    _reste.dispose();
    _monnaie.dispose();
    _recommandation.dispose();
    _address.dispose();
    super.dispose();
  }

  // OBTENIR LES CATEGORIES API
  Future<void> _getClients() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.getClients(token);
      final body = res.data;
      if (res.statusCode == 200) {
        setState(() {
          final clients = (body["clients"] as List)
              .map((json) => ClientModel.fromJson(json))
              .toList();
          _listClients.add(clients);
        });
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

//SUPPRIMER CATEGORIE API
  Future<void> _removeClients(id) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteClients(id, token);
      final body = res.data;
      if (res.statusCode == 200) {
           if (!mounted) return;
        // ignore: use_build_context_synchronously
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        _getClients(); // Actualiser la liste des catégories
      } else {
        // ignore: use_build_context_synchronously
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

//AJOUTER CATEGORIE API
  Future<void> _sendToserver(BuildContext context) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userId = Provider.of<AuthProvider>(context, listen: false).userId;
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    if (_globalKey.currentState!.validate()) {
      try {
        // Construction du FormData
        final formDataMap = {
          "userId": userId,
          "adminId": adminId,
          "nom": _nom.text,
          "contact": _contact.text,
          "client_address":_address.text,
          "credit_total": int.tryParse(_creditTotal.text) ?? 0,
          "montant_paye": int.tryParse(_montantPaye.text) ?? 0,
          "reste": int.tryParse(_reste.text) ?? 0,
          "monnaie": int.tryParse(_monnaie.text) ?? 0,
          "recommandation": _recommandation.text,
          "statut": _statut,
          "date": DateTime.now().toIso8601String(),
        };

        // Ajoute le fichier seulement s’il est sélectionné
        if (documentFile != null) {
          formDataMap["image"] = await MultipartFile.fromFile(
            documentFile!.path,
            filename: documentFile!.path.split('/').last,
          );
        }

        final formData = FormData.fromMap(formDataMap);

        showDialog(
          context: context,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final res = await api.postClients(formData, token);

        if (!context.mounted) return; // <-- sécurité si le widget est démonté
        Navigator.pop(context); // Ferme le loader
        Navigator.pop(context); // Ferme le dialog

        if (res.statusCode == 201) {
          if (!context.mounted) return;
          api.showSnackBarSuccessPersonalized(context, res.data["message"]);
             if (!context.mounted) return;
          _getClients();
          
        } else {
          api.showSnackBarErrorPersonalized(context, res.data["message"]);
        }
      } catch (e) {
        if (!context.mounted) {
          Navigator.pop(context);
          api.showSnackBarErrorPersonalized(context, e.toString());
        }
      }
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _getClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Vérification automatique de l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!await authProvider.checkAuth()) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white, // const Color(0xff001c30),
            expandedHeight: 50, // Augmentation de la hauteur
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Mes clients",
                style: GoogleFonts.roboto(fontSize: 16, color: Colors.black),
              ),
            ),
          ),
          // Utiliser un SliverList à la place d'un ListView.builder pour éviter les conflits de défilement
          StreamBuilder<List<ClientModel>>(
            stream: _listClients.stream,
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                          icon: const Icon(Icons.refresh_outlined, size: 28))
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
                    const SizedBox(
                      height: 20,
                    ),
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
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
                                      label: Text('ADDRESSE',
                                          style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                                  DataColumn(
                                      label: Text('STATUT',
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
                                        fournisseur.nom,
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                        ),
                                      )),

                                      // Tél
                                      DataCell(
                                          Text(fournisseur.contact.toString(),
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                              ))),
                                       DataCell(
                                          Text(fournisseur.clientAdresse.toString(),
                                              style: GoogleFonts.roboto(
                                                fontSize: 14,
                                              ))),

                                      // Produit
                                      DataCell(Text(fournisseur.statut,
                                          style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              color:
                                                  fournisseur.statut == "actif"
                                                      ? Colors.green
                                                      : Colors.black))),

                                      // Action (supprimer)
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.badge,
                                                  color: Colors.grey[500]),
                                              tooltip: "Pièce d'identitée",
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final isMobile =
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width <
                                                            500;
                                                    final double imageWidth =
                                                        isMobile
                                                            ? MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width *
                                                                0.9
                                                            : 500;
                                                    final double imageHeight =
                                                        isMobile ? 200 : 300;

                                                    return AlertDialog(
                                                      title: Text(
                                                        "Pièce du client",
                                                        style:
                                                            GoogleFonts.roboto(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      content: SizedBox(
                                                        width: imageWidth,
                                                        height: imageHeight,
                                                        child: fournisseur.image
                                                                .isNotEmpty
                                                            ? Image.network(
                                                                fournisseur
                                                                    .image,
                                                                width:
                                                                    imageWidth,
                                                                height:
                                                                    imageHeight,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (context,
                                                                        error,
                                                                        stackTrace) {
                                                                  return Image
                                                                      .asset(
                                                                    "assets/images/defaultImg.png",
                                                                    width:
                                                                        imageWidth,
                                                                    height:
                                                                        imageHeight,
                                                                    fit: BoxFit
                                                                        .cover,
                                                                  );
                                                                },
                                                              )
                                                            : Image.asset(
                                                                "assets/images/defaultImg.png",
                                                                width:
                                                                    imageWidth,
                                                                height:
                                                                    imageHeight,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          child: const Text(
                                                              "Fermer"),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                        )
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.person_remove_alt_1,
                                                  color: Colors.red),
                                              tooltip: "Supprimer le client",
                                              onPressed: () async {
                                                final confirm =
                                                    await showRemoveClient(
                                                        context);
                                                if (confirm == true) {
                                                  _removeClients(
                                                      fournisseur.id);
                                                }
                                              },
                                            ),
                                          ],
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
          _addClientShow(context);
        },
        child: const Icon(
          Icons.add,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  void _addClientShow(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Center(
              child: Text(
                "Ajouter un client",
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _globalKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (documentFile == null)
                            IconButton(
                              onPressed: () async {
                                final imagePicke = await _picker.pickImage(
                                    source: ImageSource.gallery);
                                if (imagePicke != null) {
                                  setStateDialog(() {
                                    documentFile = File(imagePicke.path);
                                  });
                                }
                              },
                              icon: const Icon(Icons.image_sharp, size: 28),
                            ),
                          if (documentFile != null)
                            ClipRRect(
                              child: Image.file(
                                documentFile!,
                                width: 100,
                                height: 100,
                              ),
                            )
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _nom,
                      validator: (value) => value!.isEmpty
                          ? 'Veuillez entrer le nom du client'
                          : null,
                      decoration: InputDecoration(
                        hintText: "Nom du client",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _contact,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty
                          ? 'Veuillez entrer le numéro du client'
                          : null,
                      decoration: InputDecoration(
                        hintText: "Contact du client",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),                    
                    TextFormField(
                      controller: _address,
                      keyboardType: TextInputType.name,
                      validator: (value) => value!.isEmpty
                          ? "Veuillez entrer l'addresse du client"
                          : null,
                      decoration: InputDecoration(
                        hintText: "Addresse du client",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _creditTotal,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Crédit total",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.attach_money,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _montantPaye,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Montant payé",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.payments,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _reste,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Reste à payer",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.money_off,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _monnaie,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Monnaie",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.monetization_on,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _recommandation,
                      decoration: InputDecoration(
                        hintText: "Recommandé par (facultatif)",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.group,
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _statut,
                      decoration: InputDecoration(
                        hintText: "Statut du client",
                        hintStyle: GoogleFonts.roboto(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.info_outline,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'actif', child: Text("Actif")),
                        DropdownMenuItem(
                            value: 'inactif', child: Text("Inactif")),
                      ],
                      onChanged: (value) => setState(() => _statut = value!),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_globalKey.currentState!.validate()) {
                          _sendToserver(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        "Enregistrer",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  // FENTRE DIALOGUE POUR CONFIRMER LA SUPPRESSION
  Future<bool> showRemoveClient(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmer",
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text("Êtes-vous sûr de vouloir supprimer cette catégorie ?",
              style: GoogleFonts.poppins(fontSize: 14)),
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
