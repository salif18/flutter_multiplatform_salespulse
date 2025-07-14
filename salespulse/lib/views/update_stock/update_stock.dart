// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/models/categories_model.dart';
import 'package:salespulse/models/product_model_pro.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/categ_api.dart';
import 'package:salespulse/services/stocks_api.dart';
import 'package:salespulse/views/abonnement/choix_abonement.dart';


class EditProduitPage extends StatefulWidget {
  final ProductModel product;

  const EditProduitPage({super.key, required this.product});

  @override
  State<EditProduitPage> createState() => _EditProduitPageState();
}

class _EditProduitPageState extends State<EditProduitPage> {
  final ServicesStocks api = ServicesStocks();
  final ServicesCategories apiCatego = ServicesCategories();
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  List<CategoriesModel> _categoriesList = [];

  File? _imageFile;
  Uint8List? _imageWeb;
  String? _imageUrl;

  late TextEditingController _nom;
  late TextEditingController _description;
  late TextEditingController _prixAchat;
  late TextEditingController _prixVente;
  late TextEditingController _stock;
  late TextEditingController _seuil;
  late TextEditingController _prixPromo;

  String? _selectedCategorie;

  DateTime? _dateAchat;
  DateTime? _dateExpiration;
  bool _isPromo = false;
  DateTime? _dateDebutPromo;
  DateTime? _dateFinPromo;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _initFormData();
  }

  void _initFormData() {
    final product = widget.product;

    _nom = TextEditingController(text: product.nom);
    _description = TextEditingController(text: product.description);
    _prixAchat = TextEditingController(text: product.prixAchat.toString());
    _prixVente = TextEditingController(text: product.prixVente.toString());
    _stock = TextEditingController(text: product.stocks.toString());
    _seuil = TextEditingController(text: product.seuilAlerte.toString());
    _prixPromo = TextEditingController(text: product.prixPromo.toString());
    _selectedCategorie = product.categories;

    _isPromo = product.isPromo;
    _dateDebutPromo = product.dateDebutPromo;
    _dateFinPromo = product.dateFinPromo;
    _dateAchat = product.dateAchat;
    _dateExpiration = product.dateExpiration;
    _imageUrl = product.image;
  }

  Future<void> _loadCategories() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await apiCatego.getCategories(token);
      if (res.statusCode == 200) {
        setState(() {
          _categoriesList = (res.data["results"] as List)
              .map((json) => CategoriesModel.fromJson(json))
              .toList();
        });
      } else {
        throw Exception("Erreur ${res.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.statusCode == 403) {
        final errorMessage = e.response?.data['error'] ?? '';

        if (errorMessage.toString().contains("abonnement")) {
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

  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        if (kIsWeb) {
          var bytes = await picked.readAsBytes();
          setState(() {
            _imageWeb = bytes;
            _imageFile = null;
            _imageUrl = null;
          });
        } else {
          setState(() {
            _imageFile = File(picked.path);
            _imageUrl = null;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur sélection image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Erreur lors de la sélection de l'image")),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final formData = FormData();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    void addField(String key, dynamic value) {
      if (value != null && value.toString().isNotEmpty) {
        formData.fields.add(MapEntry(key, value.toString()));
      }
    }

    addField('nom', _nom.text);
    addField('categories', _selectedCategorie);
    addField('description', _description.text);
    addField('prix_achat', _prixAchat.text);
    addField('prix_vente', _prixVente.text);
    addField('stocks', _stock.text);
    addField('seuil_alerte', _seuil.text);
    addField('isPromo', _isPromo);
    addField('prix_promo', _prixPromo.text.isNotEmpty ? _prixPromo.text : '0');
    
    if (_dateDebutPromo != null) {
      addField('date_debut_promo', _dateDebutPromo!.toIso8601String());
    }
    if (_dateFinPromo != null) {
      addField('date_fin_promo', _dateFinPromo!.toIso8601String());
    }
    if (_dateAchat != null) {
      addField('date_achat', _dateAchat!.toIso8601String());
    }
    if (_dateExpiration != null) {
      addField('date_expiration', _dateExpiration!.toIso8601String());
    }

    // Handle image upload for web and mobile
    if (kIsWeb) {
      if (_imageWeb != null) {
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            _imageWeb!,
            filename: 'product_image.jpg',
          ),
        ));
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        formData.fields.add(MapEntry('image', _imageUrl!));
      }
    } else {
      if (_imageFile != null) {
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            _imageFile!.path,
            filename: _imageFile!.path.split('/').last,
          ),
        ));
      } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
        formData.fields.add(MapEntry('image', _imageUrl!));
      }
    }

    try {
      final response =
          await api.updateProduct(formData, token, widget.product.id);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Produit modifié avec succès")),
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _resetForm();
          });
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Erreur API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur soumission formulaire: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
  }

  Future<void> _removeArticles(productId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final res = await api.deleteProduct(productId, token);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        api.showSnackBarSuccessPersonalized(context, body["message"]);
        Navigator.pop(context, true);
      } else {
        api.showSnackBarErrorPersonalized(context, body["message"]);
      }
    } catch (e) {
      api.showSnackBarErrorPersonalized(context, e.toString());
    }
  }

  void _resetForm() {
    _nom.clear();
    _description.clear();
    _stock.clear();
    _seuil.clear();
    _prixPromo.clear();

    setState(() {
      _selectedCategorie = null;
      _dateAchat = null;
      _dateExpiration = null;
      _isPromo = false;
      _imageFile = null;
      _imageWeb = null;
      _imageUrl = null;
      _seuil.text = '5';
    });

    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }

    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    _nom.dispose();
    _description.dispose();
    _prixAchat.dispose();
    _prixVente.dispose();
    _stock.dispose();
    _seuil.dispose();
    _prixPromo.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.logoutButton();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      return _imageWeb != null
          ? Image.memory(_imageWeb!, fit: BoxFit.cover)
          : _imageUrl != null && _imageUrl!.isNotEmpty
              ? Image.network(_imageUrl!, fit: BoxFit.cover)
              : _buildPlaceholderImage();
    } else {
      return _imageFile != null
          ? Image.file(_imageFile!, fit: BoxFit.cover)
          : _imageUrl != null && _imageUrl!.isNotEmpty
              ? Image.network(_imageUrl!, fit: BoxFit.cover)
              : _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_search,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            "Aucune image sélectionnée",
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        title: Text(
          "Modifier le produit",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Card(
            elevation: 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: _buildImageSection(),
                    ),
                    const SizedBox(width: 32),
                    Flexible(
                      flex: 3,
                      child: _buildFormSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildImageSection(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildFormSection(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImagePreview(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library, size: 18),
              label: Text(
                "Galerie",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _buildUrlImageDialog(),
                );
              },
              icon: const Icon(Icons.link, size: 18),
              label: Text(
                "Lien image",
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nom et Catégorie
        if (MediaQuery.of(context).size.width > 600)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildTextField(
                  controller: _nom,
                  label: "Nom du produit*",
                  hint: "Saisissez le nom du produit",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildCategoryDropdown(),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildTextField(
                controller: _nom,
                label: "Nom du produit*",
                hint: "Saisissez le nom du produit",
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
            ],
          ),
        const SizedBox(height: 16),

        // Description
        _buildTextField(
          controller: _description,
          label: "Description",
          hint: "Décrivez le produit...",
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Dates
        if (MediaQuery.of(context).size.width > 600)
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  context,
                  label: "Date d'achat",
                  date: _dateAchat,
                  onDateSelected: (date) {
                    setState(() => _dateAchat = date);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateField(
                  context,
                  label: "Date d'expiration",
                  date: _dateExpiration,
                  onDateSelected: (date) {
                    setState(() => _dateExpiration = date);
                  },
                  isExpiration: true,
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildDateField(
                context,
                label: "Date d'achat",
                date: _dateAchat,
                onDateSelected: (date) {
                  setState(() => _dateAchat = date);
                },
              ),
              const SizedBox(height: 16),
              _buildDateField(
                context,
                label: "Date d'expiration",
                date: _dateExpiration,
                onDateSelected: (date) {
                  setState(() => _dateExpiration = date);
                },
                isExpiration: true,
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Prix
        if (MediaQuery.of(context).size.width > 600)
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _prixAchat,
                  label: "Prix d'achat*",
                  hint: "0.00",
                  keyboardType: TextInputType.number,
                  prefix: Text(
                    "FCFA",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Ce champ est obligatoire";
                    }
                    if (double.tryParse(value) == null) {
                      return "Valeur numérique invalide";
                    }
                    if (double.parse(value) <= 0) {
                      return "Doit être supérieur à 0";
                    }
                    return null;
                  }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _prixVente,
                  label: "Prix de vente*",
                  hint: "0.00",
                  keyboardType: TextInputType.number,
                  prefix: Text(
                    "FCFA",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Ce champ est obligatoire";
                    }
                    if (double.tryParse(value) == null) {
                      return "Valeur numérique invalide";
                    }
                    if (double.parse(value) <= 0) {
                      return "Doit être supérieur à 0";
                    }
                    if (_prixAchat.text.isNotEmpty &&
                        double.tryParse(_prixAchat.text) != null) {
                      if (double.parse(value) <=
                          double.parse(_prixAchat.text)) {
                        return "Doit être supérieur au prix d'achat";
                      }
                    }
                    return null;
                  },
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildTextField(
                  controller: _prixAchat,
                  label: "Prix d'achat*",
                  hint: "0.00",
                  keyboardType: TextInputType.number,
                  prefix: Text(
                    "FCFA",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Ce champ est obligatoire";
                    }
                    if (double.tryParse(value) == null) {
                      return "Valeur numérique invalide";
                    }
                    if (double.parse(value) <= 0) {
                      return "Doit être supérieur à 0";
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _prixVente,
                label: "Prix de vente*",
                hint: "0.00",
                keyboardType: TextInputType.number,
                prefix: Text(
                  "FCFA",
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Ce champ est obligatoire";
                  }
                  if (double.tryParse(value) == null) {
                    return "Valeur numérique invalide";
                  }
                  if (double.parse(value) <= 0) {
                    return "Doit être supérieur à 0";
                  }
                  if (_prixAchat.text.isNotEmpty &&
                      double.tryParse(_prixAchat.text) != null) {
                    if (double.parse(value) <=
                        double.parse(_prixAchat.text)) {
                      return "Doit être supérieur au prix d'achat";
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        const SizedBox(height: 16),

        // Stock
        _buildTextField(
          controller: _stock,
          label: "Stock*",
          hint: "0",
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Ce champ est obligatoire";
            }
            if (int.tryParse(value) == null) {
              return "Valeur numérique invalide";
            }
            if (int.parse(value) < 0) {
              return "Doit être positif";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Seuil d'alerte
        _buildTextField(
          controller: _seuil,
          label: "Seuil d'alerte",
          hint: "5",
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (int.tryParse(value) == null) {
                return "Valeur numérique invalide";
              }
              if (int.parse(value) < 0) {
                return "Doit être positif";
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Promotion
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isPromo ? Colors.orange[50] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isPromo ? Colors.orange[100]! : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Activer la promotion",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _isPromo,
                onChanged: (value) {
                  setState(() => _isPromo = value);
                },
              ),
              if (_isPromo) ...[
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _prixPromo,
                  label: "Prix promotionnel*",
                  hint: "0.00",
                  keyboardType: TextInputType.number,
                  prefix: Text(
                    "FCFA",
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  validator: _isPromo
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return "Ce champ est obligatoire";
                          }
                          if (double.tryParse(value) == null) {
                            return "Valeur numérique invalide";
                          }
                          if (double.parse(value) <= 0) {
                            return "Doit être supérieur à 0";
                          }
                          if (_prixVente.text.isNotEmpty &&
                              double.tryParse(_prixVente.text) != null) {
                            if (double.parse(value) >=
                                double.parse(_prixVente.text)) {
                              return "Doit être inférieur au prix de vente";
                            }
                          }
                          return null;
                        }
                      : null,
                ),
                const SizedBox(height: 16),
                if (MediaQuery.of(context).size.width > 600)
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: "Début promo",
                          date: _dateDebutPromo,
                          onDateSelected: (date) {
                            setState(() => _dateDebutPromo = date);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          context,
                          label: "Fin promo",
                          date: _dateFinPromo,
                          onDateSelected: (date) {
                            setState(() => _dateFinPromo = date);
                          },
                          isExpiration: true,
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildDateField(
                        context,
                        label: "Début promo",
                        date: _dateDebutPromo,
                        onDateSelected: (date) {
                          setState(() => _dateDebutPromo = date);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(
                        context,
                        label: "Fin promo",
                        date: _dateFinPromo,
                        onDateSelected: (date) {
                          setState(() => _dateFinPromo = date);
                        },
                        isExpiration: true,
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Boutons
        SizedBox(
          height: 50,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: Text(
                    "MODIFIER LE PRODUIT",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5))),
                  child: Text(
                    "SUPPRIMER LE PRODUIT",
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    _removeArticles(widget.product.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
    bool isExpiration = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary:
                          isExpiration ? Colors.red[400]! : Colors.blue[400]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: isExpiration ? Colors.red[400] : Colors.blue[400],
                ),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : "Sélectionner une date",
                  style: GoogleFonts.poppins(
                    color: date != null ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            prefix: prefix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Catégorie*",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedCategorie,
          items: _categoriesList
              .map((cat) => DropdownMenuItem<String>(
                    value: cat.name,
                    child: Text(
                      cat.name,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedCategorie = value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          validator: (value) =>
              value == null ? "Veuillez sélectionner une catégorie" : null,
        ),
      ],
    );
  }

  Widget _buildUrlImageDialog() {
    final urlController = TextEditingController(text: _imageUrl);
    
    return AlertDialog(
      title: Text(
        "Modifier l'image par URL",
        style: GoogleFonts.poppins(),
      ),
      content: TextField(
        controller: urlController,
        decoration: InputDecoration(
          hintText: "https://example.com/image.jpg",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Annuler",
              style:
                  GoogleFonts.roboto(fontSize: 14, color: Colors.blueAccent)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
          onPressed: () {
            final newUrl = urlController.text.trim();
            if (newUrl.isNotEmpty) {
              setState(() {
                _imageUrl = newUrl;
                _imageFile = null;
                if (kIsWeb) _imageWeb = null;
              });
              Navigator.pop(context);
            }
          },
          child: Text("Valider",
              style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ],
    );
  }
}
// // ignore_for_file: depend_on_referenced_packages

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:salespulse/models/categories_model.dart';
// import 'package:salespulse/models/product_model_pro.dart';
// import 'package:salespulse/providers/auth_provider.dart';
// import 'package:salespulse/services/categ_api.dart';
// import 'package:salespulse/services/stocks_api.dart';
// import 'package:salespulse/views/abonnement/choix_abonement.dart';

// class EditProduitPage extends StatefulWidget {
//   final ProductModel product;

//   const EditProduitPage({super.key, required this.product});

//   @override
//   State<EditProduitPage> createState() => _EditProduitPageState();
// }

// class _EditProduitPageState extends State<EditProduitPage> {
//   final ServicesStocks api = ServicesStocks();
//   final ServicesCategories apiCatego = ServicesCategories();
//   final _formKey = GlobalKey<FormState>();
//   final picker = ImagePicker();
//   List<CategoriesModel> _categoriesList = [];

//   File? _imageFile;
//   String? _imageUrl;

//   late TextEditingController _nom;
//   late TextEditingController _description;
//   late TextEditingController _prixAchat;
//   late TextEditingController _prixVente;
//   late TextEditingController _stock;
//   late TextEditingController _seuil;
//   late TextEditingController _prixPromo;

//   String? _selectedCategorie;

//   DateTime? _dateAchat;
//   DateTime? _dateExpiration;
//   bool _isPromo = false;
//   DateTime? _dateDebutPromo; // Nouveau champ
//   DateTime? _dateFinPromo;

//   @override
//   void initState() {
//     super.initState();
//     _loadCategories();
//     _initFormData();
//   }

//   void _initFormData() {
//     final product = widget.product;

//     _nom = TextEditingController(text: product.nom);
//     _description = TextEditingController(text: product.description);
//     _prixAchat = TextEditingController(text: product.prixAchat.toString());
//     _prixVente = TextEditingController(text: product.prixVente.toString());
//     _stock = TextEditingController(text: product.stocks.toString());
//     _seuil = TextEditingController(text: product.seuilAlerte.toString());
//     _prixPromo = TextEditingController(text: product.prixPromo.toString());
//     _selectedCategorie = product.categories;

//     _isPromo = product.isPromo;
//     _dateDebutPromo = product.dateDebutPromo;
//     _dateFinPromo = product.dateFinPromo;
//     _dateAchat = product.dateAchat;
//     _dateExpiration = product.dateExpiration;
//     _imageUrl = product.image;
//   }

//   Future<void> _loadCategories() async {
//     final token = Provider.of<AuthProvider>(context, listen: false).token;
//     try {
//       final res = await apiCatego.getCategories(token);
//       if (res.statusCode == 200) {
//         setState(() {
//           _categoriesList = (res.data["results"] as List)
//               .map((json) => CategoriesModel.fromJson(json))
//               .toList();
//         });
//       } else {
//         throw Exception("Erreur ${res.statusCode}");
//       }
//     } on DioException catch (e) {
//       if (e.response != null && e.response?.statusCode == 403) {
//         final errorMessage = e.response?.data['error'] ?? '';

//         if (errorMessage.toString().contains("abonnement")) {
//           // 👉 Afficher message spécifique abonnement expiré
//           showDialog(
//             context: context,
//             builder: (_) => AlertDialog(
//               title: const Text("Abonnement expiré"),
//               content: const Text(
//                   "Votre abonnement a expiré. Veuillez le renouveler."),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     Navigator.pushReplacement(
//                       context,
//                       MaterialPageRoute(
//                           builder: (_) => const AbonnementScreen()),
//                     );
//                   },
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//           );
//           return;
//         }
//       }

//       // 🚫 Autres DioException (ex: réseau)
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             "Problème de connexion : Vérifiez votre Internet.",
//             style: GoogleFonts.poppins(fontSize: 14),
//           ),
//         ),
//       );
//     } on TimeoutException {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(
//         "Le serveur ne répond pas. Veuillez réessayer plus tard.",
//         style: GoogleFonts.poppins(fontSize: 14),
//       )));
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
//       debugPrint(e.toString());
//     }
//   }

//   Future<void> _pickImageFromGallery() async {
//     try {
//       final picked = await picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 800,
//         maxHeight: 800,
//         imageQuality: 85,
//       );
//       if (picked != null) {
//         setState(() {
//           _imageFile = File(picked.path);
//           _imageUrl = null;
//         });
//       }
//     } catch (e) {
//       debugPrint("Erreur sélection image: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Erreur lors de la sélection de l'image")),
//         );
//       }
//     }
//   }

//   Future<void> _submitForm() async {
//     if (!_formKey.currentState!.validate()) return;

//     // Création du FormData
//     final formData = FormData();
//     final token = Provider.of<AuthProvider>(context, listen: false).token;
//     // Ajout des champs
//     void addField(String key, dynamic value) {
//       if (value != null && value.toString().isNotEmpty) {
//         formData.fields.add(MapEntry(key, value.toString()));
//       }
//     }

//     addField('nom', _nom.text);
//     addField('categories', _selectedCategorie);
//     addField('description', _description.text);
//     addField('prix_achat', _prixAchat.text);
//     addField('prix_vente', _prixVente.text);
//     addField('stocks', _stock.text);
//     addField('seuil_alerte', _seuil.text);
//     addField('isPromo', _isPromo);
//     addField('prix_promo', _prixPromo.text.isNotEmpty ? _prixPromo.text : '0');
//     if (_dateDebutPromo != null) {
//       addField('date_debut_promo', _dateDebutPromo!.toIso8601String());
//     }

//     if (_dateFinPromo != null) {
//       addField('date_fin_promo', _dateFinPromo!.toIso8601String());
//     }

//     if (_dateAchat != null) {
//       formData.fields
//           .add(MapEntry('date_achat', _dateAchat!.toIso8601String()));
//     }

//     if (_dateExpiration != null) {
//       formData.fields
//           .add(MapEntry('date_expiration', _dateExpiration!.toIso8601String()));
//     }

//     // Gestion de l'image
//     if (_imageFile != null) {
//       formData.files.add(MapEntry(
//         'image', // Le backend attend 'file' pour req.file
//         await MultipartFile.fromFile(
//           _imageFile!.path,
//           filename: _imageFile!.path.split('/').last,
//         ),
//       ));
//     } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
//       formData.fields.add(MapEntry('image', _imageUrl!));
//     }

//     try {
//       final response =
//           await api.updateProduct(formData, token, widget.product.id);

//       if (response.statusCode == 200) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("Produit ajouté avec succès")),
//           );
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (mounted) _resetForm();
//           });
//            Navigator.pop(context,true);
//         }
//       } else {
//         throw Exception("Erreur API: ${response.statusCode}");
//       }
//     } catch (e) {
//       debugPrint("Erreur soumission formulaire: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Erreur : ${e.toString()}")),
//       );
//     }
//   }

//   Future<void> _removeArticles(productId) async {
//     final token = Provider.of<AuthProvider>(context, listen: false).token;
//     try {
//       final res = await api.deleteProduct(productId, token);
//       final body = jsonDecode(res.body);
//       if (res.statusCode == 200) {
//         // ignore: use_build_context_synchronously
       
//         api.showSnackBarSuccessPersonalized(context, body["message"]);
//         Navigator.pop(context,true);
//       } else {
//         // ignore: use_build_context_synchronously
//         api.showSnackBarErrorPersonalized(context, body["message"]);
//       }
//     } catch (e) {
//       // ignore: use_build_context_synchronously
//       api.showSnackBarErrorPersonalized(context, e.toString());
//     }
//   }

//   void _resetForm() {
//     // 1. Réinitialisez d'abord tous les contrôleurs
//     _nom.clear();
//     _description.clear();
//     _stock.clear();
//     _seuil.clear();
//     _prixPromo.clear();

//     // 2. Puis mettez à jour l'état
//     setState(() {
//       _selectedCategorie = null;
//       _dateAchat = null;
//       _dateExpiration = null;
//       _isPromo = false;
//       _imageFile = null;
//       _imageUrl = null;

//       // Réassignez les valeurs par défaut APRÈS le clear()
//       _seuil.text = '5';
//     });

//     // 3. Réinitialisez le formulaire
//     if (_formKey.currentState != null) {
//       _formKey.currentState!.reset();
//     }

//     // 4. Fermez le clavier
//     FocusScope.of(context).requestFocus(FocusNode());
//   }

//   @override
//   void dispose() {
//     _nom.dispose();
//     _description.dispose();
//     _prixAchat.dispose();
//     _prixVente.dispose();
//     _stock.dispose();
//     _seuil.dispose();
//     _prixPromo.dispose();
//     super.dispose();
//   }

//   Future<void> _handleLogout(BuildContext context) async {
//     final authProvider = context.read<AuthProvider>();
//     await authProvider.logoutButton();
//     if (mounted) {
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     // Vérification initiale de l'authentification
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       if (!authProvider.isAuthenticated && mounted) {
//         await _handleLogout(context);
//       }
//     });

//     if (authProvider.isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.blueGrey,
//         foregroundColor: Colors.white,
//         title: Text(
//           "Modifier le produit",
//           style: GoogleFonts.poppins(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Center(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 1200),
//             child: Card(
//               elevation: 2,
//               color: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Padding(
//                 padding: const EdgeInsets.all(24),
//                 child: Form(
//                   key: _formKey,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Colonne gauche - Image et import
//                       Flexible(
//                         flex: 2,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             // Section image
//                             Container(
//                               height: 200,
//                               decoration: BoxDecoration(
//                                 color: Colors.grey[100],
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: Colors.grey[300]!,
//                                   width: 1,
//                                 ),
//                               ),
//                               child: _imageFile != null
//                                   ? ClipRRect(
//                                       borderRadius: BorderRadius.circular(12),
//                                       child: Image.file(
//                                         _imageFile!,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     )
//                                   : _imageUrl != null && _imageUrl!.isNotEmpty
//                                       ? ClipRRect(
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                           child: Image.network(
//                                             _imageUrl!,
//                                             fit: BoxFit.cover,
//                                           ),
//                                         )
//                                       : Center(
//                                           child: Column(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Icon(
//                                                 Icons.image_search,
//                                                 size: 48,
//                                                 color: Colors.grey[400],
//                                               ),
//                                               const SizedBox(height: 8),
//                                               Text(
//                                                 "Aucune image sélectionnée",
//                                                 style: GoogleFonts.poppins(
//                                                   color: Colors.grey[600],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                             ),
//                             const SizedBox(height: 16),

//                             // Boutons d'import
//                             Wrap(
//                               spacing: 12,
//                               runSpacing: 12,
//                               children: [
//                                 ElevatedButton.icon(
//                                   onPressed: _pickImageFromGallery,
//                                   icon:
//                                       const Icon(Icons.photo_library, size: 18),
//                                   label: Text(
//                                     "Galerie",
//                                     style: GoogleFonts.poppins(fontSize: 13),
//                                   ),
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.blue[600],
//                                     foregroundColor: Colors.white,
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 16, vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                 ),
//                                 OutlinedButton.icon(
//                                   onPressed: () {
//                                     showDialog(
//                                       context: context,
//                                       builder: (context) =>
//                                           _buildUrlImageDialog(),
//                                     );
//                                   },
//                                   icon: const Icon(Icons.link, size: 18),
//                                   label: Text(
//                                     "Lien image",
//                                     style: GoogleFonts.poppins(fontSize: 13),
//                                   ),
//                                   style: OutlinedButton.styleFrom(
//                                     foregroundColor: Colors.grey[800],
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 16, vertical: 12),
//                                     side: BorderSide(color: Colors.grey[300]!),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),

//                       const SizedBox(width: 32),

//                       // Colonne droite - Formulaire
//                       Flexible(
//                         flex: 3,
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.stretch,
//                           children: [
//                             // Ligne 1 - Nom et Catégorie
//                             Row(
//                               children: [
//                                 Expanded(
//                                   flex: 3,
//                                   child: _buildTextField(
//                                     controller: _nom,
//                                     label: "Nom du produit*",
//                                     hint: "Saisissez le nom du produit",
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   flex: 2,
//                                   child: _buildCategoryDropdown(),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),

//                             // Description
//                             _buildTextField(
//                               controller: _description,
//                               label: "Description",
//                               hint: "Décrivez le produit...",
//                               maxLines: 3,
//                             ),
//                             const SizedBox(height: 16),

//                             // Ligne 2 - Dates
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildDateField(
//                                     context,
//                                     label: "Date d'achat",
//                                     date: _dateAchat,
//                                     onDateSelected: (date) {
//                                       setState(() => _dateAchat = date);
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: _buildDateField(
//                                     context,
//                                     label: "Date d'expiration",
//                                     date: _dateExpiration,
//                                     onDateSelected: (date) {
//                                       setState(() => _dateExpiration = date);
//                                     },
//                                     isExpiration: true,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),

//                             // Ligne 3 - Prix
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildTextField(
//                                     controller: _prixAchat,
//                                     label: "Prix d'achat*",
//                                     hint: "0.00",
//                                     keyboardType: TextInputType.number,
//                                     prefix: Text(
//                                       "FCFA",
//                                       style: GoogleFonts.poppins(
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                     validator: (value) {
//                                       if (value == null || value.isEmpty) {
//                                         return "Ce champ est obligatoire";
//                                       }
//                                       if (double.tryParse(value) == null) {
//                                         return "Valeur numérique invalide";
//                                       }
//                                       if (double.parse(value) <= 0) {
//                                         return "Doit être supérieur à 0";
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                                 const SizedBox(width: 16),
//                                 Expanded(
//                                   child: _buildTextField(
//                                     controller: _prixVente,
//                                     label: "Prix de vente*",
//                                     hint: "0.00",
//                                     keyboardType: TextInputType.number,
//                                     prefix: Text(
//                                       "FCFA",
//                                       style: GoogleFonts.poppins(
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                     validator: (value) {
//                                       if (value == null || value.isEmpty) {
//                                         return "Ce champ est obligatoire";
//                                       }
//                                       if (double.tryParse(value) == null) {
//                                         return "Valeur numérique invalide";
//                                       }
//                                       if (double.parse(value) <= 0) {
//                                         return "Doit être supérieur à 0";
//                                       }
//                                       if (_prixAchat.text.isNotEmpty &&
//                                           double.tryParse(_prixAchat.text) !=
//                                               null) {
//                                         if (double.parse(value) <=
//                                             double.parse(_prixAchat.text)) {
//                                           return "Doit être supérieur au prix d'achat";
//                                         }
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),

//                             // Ligne 4 - Stock et Unité
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: _buildTextField(
//                                     controller: _stock,
//                                     label: "Stock*",
//                                     hint: "0",
//                                     keyboardType: TextInputType.number,
//                                     validator: (value) {
//                                       if (value == null || value.isEmpty) {
//                                         return "Ce champ est obligatoire";
//                                       }
//                                       if (int.tryParse(value) == null) {
//                                         return "Valeur numérique invalide";
//                                       }
//                                       if (int.parse(value) < 0) {
//                                         return "Doit être positif";
//                                       }
//                                       return null;
//                                     },
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),

//                             // Ligne 5 - Seuil d'alerte
//                             _buildTextField(
//                               controller: _seuil,
//                               label: "Seuil d'alerte",
//                               hint: "5",
//                               keyboardType: TextInputType.number,
//                               validator: (value) {
//                                 if (value != null && value.isNotEmpty) {
//                                   if (int.tryParse(value) == null) {
//                                     return "Valeur numérique invalide";
//                                   }
//                                   if (int.parse(value) < 0) {
//                                     return "Doit être positif";
//                                   }
//                                 }
//                                 return null;
//                               },
//                             ),
//                             const SizedBox(height: 16),

//                             // Promotion
//                             // Promotion
//                             Container(
//                               padding: const EdgeInsets.all(12),
//                               decoration: BoxDecoration(
//                                 color: _isPromo
//                                     ? Colors.orange[50]
//                                     : Colors.transparent,
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(
//                                   color: _isPromo
//                                       ? Colors.orange[100]!
//                                       : Colors.grey[200]!,
//                                 ),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   SwitchListTile(
//                                     contentPadding: EdgeInsets.zero,
//                                     title: Text(
//                                       "Activer la promotion",
//                                       style: GoogleFonts.poppins(
//                                         fontWeight: FontWeight.w500,
//                                       ),
//                                     ),
//                                     value: _isPromo,
//                                     onChanged: (value) {
//                                       setState(() => _isPromo = value);
//                                     },
//                                   ),
//                                   if (_isPromo) ...[
//                                     const SizedBox(height: 8),
//                                     _buildTextField(
//                                       controller: _prixPromo,
//                                       label: "Prix promotionnel*",
//                                       hint: "0.00",
//                                       keyboardType: TextInputType.number,
//                                       prefix: Text(
//                                         "FCFA",
//                                         style: GoogleFonts.poppins(
//                                           color: Colors.grey[600],
//                                         ),
//                                       ),
//                                       validator: _isPromo
//                                           ? (value) {
//                                               if (value == null ||
//                                                   value.isEmpty) {
//                                                 return "Ce champ est obligatoire";
//                                               }
//                                               if (double.tryParse(value) ==
//                                                   null) {
//                                                 return "Valeur numérique invalide";
//                                               }
//                                               if (double.parse(value) <= 0) {
//                                                 return "Doit être supérieur à 0";
//                                               }
//                                               if (_prixVente.text.isNotEmpty &&
//                                                   double.tryParse(
//                                                           _prixVente.text) !=
//                                                       null) {
//                                                 if (double.parse(value) >=
//                                                     double.parse(
//                                                         _prixVente.text)) {
//                                                   return "Doit être inférieur au prix de vente";
//                                                 }
//                                               }
//                                               return null;
//                                             }
//                                           : null,
//                                     ),
//                                     const SizedBox(height: 16),
//                                     // Nouveaux champs date début/fin promo
//                                     Row(
//                                       children: [
//                                         Expanded(
//                                           child: _buildDateField(
//                                             context,
//                                             label: "Début promo",
//                                             date: _dateDebutPromo,
//                                             onDateSelected: (date) {
//                                               setState(
//                                                   () => _dateDebutPromo = date);
//                                             },
//                                           ),
//                                         ),
//                                         const SizedBox(width: 16),
//                                         Expanded(
//                                           child: _buildDateField(
//                                             context,
//                                             label: "Fin promo",
//                                             date: _dateFinPromo,
//                                             onDateSelected: (date) {
//                                               setState(
//                                                   () => _dateFinPromo = date);
//                                             },
//                                             isExpiration: true,
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 24),

//                             // Bouton d'enregistrement
//                             SizedBox(
//                               height: 50,
//                               child: Row(
//                                 children: [
//                                   ElevatedButton(
//                                     onPressed: _submitForm,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color(0xFF0066CC),
//                                       foregroundColor: Colors.white,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(5),
//                                       ),
//                                     ),
//                                     child: Text(
//                                       "MODIFIER LE PRODUIT",
//                                       style: GoogleFonts.poppins(
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     width: 16,
//                                   ),
//                                   ElevatedButton(
//                                     style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.red,
//                                         foregroundColor: Colors.white,
//                                         shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(5))),
//                                     child: Text(
//                                       "SUPPRIMER LE PRODUIT",
//                                       style: GoogleFonts.poppins(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w600),
//                                     ),
//                                     onPressed: () {
//                                       // Action pour supprimer le produit
//                                       _removeArticles(widget.product.id);
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDateField(
//     BuildContext context, {
//     required String label,
//     required DateTime? date,
//     required Function(DateTime) onDateSelected,
//     bool isExpiration = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[800],
//           ),
//         ),
//         const SizedBox(height: 4),
//         InkWell(
//           onTap: () async {
//             final picked = await showDatePicker(
//               context: context,
//               initialDate: date ?? DateTime.now(),
//               firstDate: DateTime(2000),
//               lastDate: DateTime(2100),
//               builder: (context, child) {
//                 return Theme(
//                   data: Theme.of(context).copyWith(
//                     colorScheme: ColorScheme.light(
//                       primary:
//                           isExpiration ? Colors.red[400]! : Colors.blue[400]!,
//                     ),
//                   ),
//                   child: child!,
//                 );
//               },
//             );
//             if (picked != null) {
//               onDateSelected(picked);
//             }
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.calendar_today,
//                   size: 18,
//                   color: isExpiration ? Colors.red[400] : Colors.blue[400],
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   date != null
//                       ? DateFormat('dd/MM/yyyy').format(date)
//                       : "Sélectionner une date",
//                   style: GoogleFonts.poppins(
//                     color: date != null ? Colors.black : Colors.grey[500],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     int maxLines = 1,
//     TextInputType keyboardType = TextInputType.text,
//     Widget? prefix,
//     String? Function(String?)? validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: GoogleFonts.poppins(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[800],
//           ),
//         ),
//         const SizedBox(height: 4),
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           maxLines: maxLines,
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
//             filled: true,
//             fillColor: Colors.grey[50],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             prefix: prefix,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 16,
//               vertical: 12,
//             ),
//           ),
//           validator: validator,
//         ),
//       ],
//     );
//   }

//   Widget _buildCategoryDropdown() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "Catégorie*",
//           style: GoogleFonts.poppins(
//             fontSize: 13,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey[800],
//           ),
//         ),
//         const SizedBox(height: 4),
//         DropdownButtonFormField<String>(
//           value: _selectedCategorie,
//           items: _categoriesList
//               .map((cat) => DropdownMenuItem<String>(
//                     value: cat.name,
//                     child: Text(
//                       cat.name,
//                       style: GoogleFonts.poppins(fontSize: 14),
//                     ),
//                   ))
//               .toList(),
//           onChanged: (value) {
//             setState(() => _selectedCategorie = value);
//           },
//           decoration: InputDecoration(
//             filled: true,
//             fillColor: Colors.grey[50],
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(8),
//               borderSide: BorderSide(color: Colors.grey[300]!),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 12,
//               vertical: 8,
//             ),
//           ),
//           validator: (value) =>
//               value == null ? "Veuillez sélectionner une catégorie" : null,
//         ),
//       ],
//     );
//   }

//   Widget _buildUrlImageDialog() {
//     return AlertDialog(
//       title: Text(
//         "Modifier l'image par URL",
//         style: GoogleFonts.poppins(),
//       ),
//       content: TextField(
//         controller: TextEditingController(text: _imageUrl),
//         decoration: InputDecoration(
//           hintText: "https://example.com/image.jpg",
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(8),
//           ),
//         ),
//         onChanged: (value) {
//           _imageUrl = value;
//           _imageFile = null;
//         },
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: Text("Annuler",
//               style:
//                   GoogleFonts.roboto(fontSize: 14, color: Colors.blueAccent)),
//         ),
//         ElevatedButton(
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
//           onPressed: () {
//             if (_imageUrl != null && _imageUrl!.isNotEmpty) {
//               setState(() {});
//               Navigator.pop(context);
//             }
//           },
//           child: Text("Valider",
//               style: GoogleFonts.roboto(
//                   fontSize: 14,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white)),
//         ),
//       ],
//     );
//   }
// }
