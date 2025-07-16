import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/facture_setting_api.dart';

class FactureSettingsPage extends StatefulWidget {
  const FactureSettingsPage({super.key});

  @override
  State<FactureSettingsPage> createState() => _FactureSettingsPageState();
}

class _FactureSettingsPageState extends State<FactureSettingsPage> {
  final ServicesFactures _api = ServicesFactures();

  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedAlignment = 'gauche'; // ➕ Alignement initial par défaut

  String? token;
  String? adminId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    token = Provider.of<AuthProvider>(context, listen: false).token;
    adminId = Provider.of<AuthProvider>(context, listen: false).adminId;

    try {
      final response = await _api.getFactureSettings(token);
      if (response.statusCode == 200) {
        _prefixController.text = response.data['facturePrefix'] ?? '';
        _footerController.text = response.data['factureFooter'] ?? '';
        _selectedAlignment = response.data['footerAlignement'] ?? 'gauche';
      }
    } catch (e) {
      debugPrint("Erreur chargement paramètres: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "adminId": adminId,
      "prefix": _prefixController.text.trim(),
      "footer": _footerController.text.trim(),
      "alignement":_selectedAlignment.trim()
    };

    try {
      final response = await _api.updateFactureSettings(data, token);
      if (response.statusCode == 200) {
        // ✅ Vider les champs
        _prefixController.clear();
        _footerController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Paramètres mis à jour")),
        );
      } else {
        throw Exception("Erreur lors de l'enregistrement");
      }
    } catch (e) {
      debugPrint("Erreur enregistrement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Échec de la mise à jour")),
      );
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_outlined,
              size: 18,
              color: Colors.white,
            )),
        backgroundColor: Colors.blueGrey,
        title: Text(
          'Personnalisation Facture',
          style: GoogleFonts.roboto(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: _loading
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.orange, size: 50))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isMobile ? double.infinity : 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('Préfixe du numéro de facture'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                          child: TextFormField(
                            controller: _prefixController,
                            decoration: InputDecoration(
                              hintText: "Ex: FAC-2023-",
                              border: const OutlineInputBorder(
                                  // borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un préfixe';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ce préfixe sera ajouté avant le numéro de facture (ex: FAC-2023-001)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 30),
                        _buildSectionHeader('Pied de page de la facture'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                          child: TextFormField(
                            controller: _footerController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  "Entrez le texte à afficher en bas des factures...",
                              border: const OutlineInputBorder(
                                  //borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ce texte apparaîtra en bas de chaque facture générée',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 30),
                        _buildSectionHeader('Alignement du texte'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedAlignment,
                            decoration: const InputDecoration.collapsed(
                                hintText: ''),
                            items: const [
                              DropdownMenuItem(
                                  value: 'gauche', child: Text("Gauche")),
                              DropdownMenuItem(
                                  value: 'centre', child: Text("Centré")),
                              DropdownMenuItem(
                                  value: 'droite', child: Text("Droite")),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAlignment = value!;
                              });
                            },
                          ),
                        ),
              
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueGrey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Enregistrer les modifications',
                                style: GoogleFonts.roboto(fontSize: 16)),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          fontSize: 14),
    );
  }
}
