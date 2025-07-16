import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/validation.dart';

class ResetToken extends StatefulWidget {
  const ResetToken({super.key});

  @override
  State<ResetToken> createState() => _ResetTokenState();
}

class _ResetTokenState extends State<ResetToken> {
  final ServicesAuth _authService = ServicesAuth();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final _debouncer = _Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final response = await _authService.postResetPassword({
      "numero": _phoneController.text.trim(),
      "email": _emailController.text.trim(),
    });

    if (!mounted) return;

    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ValidationReset()),
      );
    } else {
      if (!mounted) return;
      _authService.showSnackBarErrorPersonalized(context, body["message"] ?? "Erreur lors de la réinitialisation.");
    }
  } catch (e) {
    if (!mounted) return;
    _authService.showSnackBarErrorPersonalized(context, "Erreur : ${e.toString()}");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 50,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  // gradient: LinearGradient(
                  //   colors: [Color(0xFF001C30), Color(0xFF0066CC)],
                  //   begin: Alignment.topLeft,
                  //   end: Alignment.bottomRight,
                  // ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_reset, 
                              size: 48, 
                              color: Color(0xFF003366)),
                            const SizedBox(height: 16),
                            Text("Réinitialisation",
                              style: GoogleFonts.roboto(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              )),
                            const SizedBox(height: 8),
                            Text("Entrez vos informations pour recevoir un code de vérification",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.roboto(
                                color: Colors.grey[600],
                                fontSize: 14,
                              )),
                            const SizedBox(height: 24),
                            _buildPhoneField(),
                            const SizedBox(height: 16),
                            _buildEmailField(),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:  const Color(0xFF001C30),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: _isLoading 
                                    ? null 
                                    : () => _debouncer.run(() => _submitForm(context)),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : Text("CONTINUER",
                                        style: GoogleFonts.roboto(
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                          color: Colors.white
                                        )),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      validator: (value) => value?.isEmpty ?? true 
          ? 'Ce champ est obligatoire' 
          : null,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: "Numéro de téléphone",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.phone_iphone, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF003366),
        ),
      ),
    ));
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Ce champ est obligatoire';
        if (!value!.contains('@')) return 'Email invalide';
        return null;
      },
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Adresse email",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF003366)),
        ),
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