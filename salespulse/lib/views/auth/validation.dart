// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/login_view.dart';

class ValidationReset extends StatefulWidget {
  const ValidationReset({super.key});

  @override
  State<ValidationReset> createState() => _ValidationResetState();
}

class _ValidationResetState extends State<ValidationReset> {
  final ServicesAuth _authService = ServicesAuth();
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _resetTokenValue = "";
  bool _isLoading = false;
  final _debouncer = _Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  Future<void> _submitForm(BuildContext context) async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final response = await _authService.postValidatePassword({
      "reset_token": _resetTokenValue,
      "new_password": _newPasswordController.text.trim(),
      "confirm_password": _confirmPasswordController.text.trim(),
    });

    if (!mounted) return;

    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      _authService.showSnackBarSuccessPersonalized(
        context,
        body["message"] ?? "Mot de passe réinitialisé avec succès.",
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
      );
    } else {
      _authService.showSnackBarErrorPersonalized(
        context,
        body["message"] ?? "Erreur lors de la réinitialisation du mot de passe.",
      );
    }
  } catch (e) {
    if (!mounted) return;
    _authService.showSnackBarErrorPersonalized(
      context,
      "Erreur: ${e.toString()}",
    );
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
      appBar: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
            size: 20, 
            color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined,
                        size: 48,
                        color: Color(0xFF003366)),
                      const SizedBox(height: 16),
                      Text("Validation du mot de passe",
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        )),
                      const SizedBox(height: 8),
                      Text("Entrez le code de vérification et votre nouveau mot de passe",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          fontSize: 14,
                        )),
                      const SizedBox(height: 24),
                      _buildPinCodeField(context),
                      const SizedBox(height: 24),
                      _buildNewPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003366),
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
                              : Text("VALIDER",
                                  style: GoogleFonts.roboto(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 1,
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
    );
  }

  Widget _buildPinCodeField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Code de vérification",
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: Colors.grey[600],
          )),
        const SizedBox(height: 8),
        PinCodeTextField(
          appContext: context,
          length: 4,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 60,
            fieldWidth: 60,
            activeColor: const Color(0xFF003366),
            selectedColor: const Color(0xFF003366),
            inactiveColor: Colors.grey[300]!,
          ),
          onCompleted: (value) => _resetTokenValue = value,
          validator: (value) => 
            value?.isEmpty ?? true ? 'Code requis' : null,
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: true,
      validator: (value) => 
          value?.isEmpty ?? true ? 'Nouveau mot de passe requis' : null,
      decoration: InputDecoration(
        labelText: "Nouveau mot de passe",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
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

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Confirmation requise';
        if (value != _newPasswordController.text) return 'Les mots de passe ne correspondent pas';
        return null;
      },
      decoration: InputDecoration(
        labelText: "Confirmer le mot de passe",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.lock_reset, color: Colors.grey),
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