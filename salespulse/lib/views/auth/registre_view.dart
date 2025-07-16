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
        "password": _passwordController.text.trim(),
      };

      final response = await _authService.postRegistreUser(data);
      final body = json.decode(response.body);

      if (response.statusCode == 201) {
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.loginButton(
          body['token'],
          body["userId"],
          body["adminId"],
          body["role"],
          body["userName"],
          body["userNumber"],
          body["entreprise"],
        );

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Routes()),
        );
      } else {
        if (!context.mounted) return;
        _authService.showSnackBarErrorPersonalized(
          context,
          body["message"] ?? "Erreur d'enregistrement."
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      _authService.showSnackBarErrorPersonalized(
        context,
        "Erreur: ${e.toString()}"
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001C30), Color(0xFF0066CC)],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                final logoSize = isMobile ? 120.0 : 180.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.25),
                                BlendMode.darken,
                              ),
                              child: Image.asset(
                                "assets/logos/LOGO CGTECH.JPG",
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 400,
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Création de compte",
                                          style: GoogleFonts.roboto(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF001C30),
                                          )),
                                        Text("Information personnelle",
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          )),
                                        const SizedBox(height: 24),
                                        _buildField(
                                          controller: _nameController,
                                          hint: "Nom complet",
                                          icon: Icons.person_outline,
                                          validatorMsg: "Veuillez entrer votre nom"
                                        ),
                                        _buildField(
                                          controller: _companyController,
                                          hint: "Nom de société",
                                          icon: Icons.business_outlined,
                                          validatorMsg: "Veuillez entrer votre société"
                                        ),
                                        _buildField(
                                          controller: _phoneController,
                                          hint: "Numéro de téléphone",
                                          icon: Icons.phone_outlined,
                                          keyboard: TextInputType.phone,
                                          validatorMsg: "Veuillez entrer votre numéro"
                                        ),
                                        _buildField(
                                          controller: _emailController,
                                          hint: "Adresse email",
                                          icon: Icons.email_outlined,
                                          keyboard: TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return "Veuillez entrer votre email";
                                            } else if (!value.contains('@')) {
                                              return "Email invalide";
                                            }
                                            return null;
                                          },
                                        ),
                                        TextFormField(
                                          controller: _passwordController,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Veuillez entrer un mot de passe';
                                            } else if (value.length < 6) {
                                              return 'Minimum 6 caractères';
                                            }
                                            return null;
                                          },
                                          obscureText: !_isPasswordVisible,
                                          decoration: _buildInputDecoration(
                                            hintText: "Mot de passe",
                                            prefixIcon: Icons.lock_outlined,
                                            suffixIcon: IconButton(
                                              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[600]),
                                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          height: 50,
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFF7B00),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: _isLoading ? null : () => _debouncer.run(() => _handleRegistration(context)),
                                            child: _isLoading
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                                  ))
                                              : Text("Créer mon compte",
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  )),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text("Vous avez déjà un compte ? ",
                                                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600])),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginView()));
                                              },
                                              child: Text("Se connecter",
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.primaryColor,
                                                  )),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    String? validatorMsg,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          validator: validator ?? (value) => (value?.isEmpty ?? true) ? validatorMsg ?? '' : null,
          keyboardType: keyboard,
          decoration: _buildInputDecoration(hintText: hint, prefixIcon: icon),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.roboto(color: Colors.grey[500], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[100],
      prefixIcon: Icon(prefixIcon, color: Colors.grey[600]),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
