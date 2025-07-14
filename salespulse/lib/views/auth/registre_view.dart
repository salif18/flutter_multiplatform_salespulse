import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/routes.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/login_view.dart';

class RegistreView extends StatefulWidget {
  const RegistreView({super.key});

  @override
  State<RegistreView> createState() => _RegistreViewState();
}

class _RegistreViewState extends State<RegistreView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ServicesAuth _authService = ServicesAuth();
  
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _debouncer = _Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  Future<void> _handleRegistration(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final data = {
        "name": _nameController.text.trim(),
        "boutique_name": _companyController.text.trim(),
        "numero": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim()
      };

      final response = await _authService.postRegistreUser(data);
      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        provider.loginButton(
          body['token'], 
          body["userId"],  
          body["adminId"], 
          body["role"],
          body["userName"],          
          body["userNumber"],
          body["entreprise"], 
        );
        
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => const Routes())
          );
        }
      } else {
        if (mounted) {
          _authService.showSnackBarErrorPersonalized(context, body["message"]);
        }
      }
    } catch (e) {
      if (mounted) {
        _authService.showSnackBarErrorPersonalized(context, "Erreur: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: 
                [Color(0xFF001C30), Color(0xFF0066CC)],   
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo Section
                  Container(
                    height: 200,
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    child: Image.asset(
                      "assets/logos/LOGO CGTECH.JPG",
                      fit: BoxFit.contain,
                    ),
                  ),
                  
                  // Form Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Center(
                        child: SizedBox(
                          width: 400, // Largeur fixe pour les champs
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                "Création de compte",
                                style: GoogleFonts.roboto(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF001C30),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "Information personnelle",
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              
                              // Name Field
                              TextFormField(
                                controller: _nameController,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Veuillez entrer votre nom'
                                    : null,
                                decoration: _buildInputDecoration(
                                  hintText: "Nom complet",
                                  prefixIcon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Company Field
                              TextFormField(
                                controller: _companyController,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Veuillez entrer votre société'
                                    : null,
                                decoration: _buildInputDecoration(
                                  hintText: "Nom de société",
                                  prefixIcon: Icons.business_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Phone Field
                              TextFormField(
                                controller: _phoneController,
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Veuillez entrer votre numéro'
                                    : null,
                                keyboardType: TextInputType.phone,
                                decoration: _buildInputDecoration(
                                  hintText: "Numéro de téléphone",
                                  prefixIcon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Veuillez entrer votre email';
                                  }
                                  if (!value!.contains('@')) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                                keyboardType: TextInputType.emailAddress,
                                decoration: _buildInputDecoration(
                                  hintText: "Adresse email",
                                  prefixIcon: Icons.email_outlined,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                validator: (value) {
                                  if (value?.isEmpty ?? true) {
                                    return 'Veuillez entrer un mot de passe';
                                  }
                                  if (value!.length < 6) {
                                    return 'Minimum 6 caractères';
                                  }
                                  return null;
                                },
                                obscureText: !_isPasswordVisible,
                                decoration: _buildInputDecoration(
                                  hintText: "Mot de passe",
                                  prefixIcon: Icons.lock_outlined,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () => setState(() => 
                                      _isPasswordVisible = !_isPasswordVisible),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Register Button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF7B00),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading 
                                      ? null 
                                      : () => _debouncer.run(() => _handleRegistration(context)),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(Colors.white),
                                          ),
                                        )
                                      : Text(
                                          "Créer mon compte",
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Vous avez déjà un compte ? ",
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginView(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        "Se connecter",
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.roboto(
        color: Colors.grey[500],
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}

class _Debouncer {
  final int milliseconds;
  Timer? _timer;

  _Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}