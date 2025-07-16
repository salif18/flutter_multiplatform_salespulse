// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/services/auth_api.dart';
import 'package:salespulse/views/auth/reset_password.dart';

class UpdatePassword extends StatefulWidget {
  const UpdatePassword({super.key});

  @override
  State<UpdatePassword> createState() => _UpdatePasswordState();
}

class _UpdatePasswordState extends State<UpdatePassword> {
  final ServicesAuth _authService = ServicesAuth();
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _debouncer = _Debouncer(milliseconds: 500);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _debouncer.cancel();
    super.dispose();
  }

  Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final response = await _authService.postUpdatePassword({
      "current_password": _currentPasswordController.text.trim(),
      "new_password": _newPasswordController.text.trim(),
      "confirm_password": _confirmPasswordController.text.trim()
    }, provider.token);

    if (!mounted) return;

    final decodedData = json.decode(response.body);

    if (response.statusCode == 200) {
      if (!mounted) return;
      _authService.showSnackBarSuccessPersonalized(
        context,
        decodedData['message']?.toString() ?? "Mot de passe mis à jour avec succès."
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      _authService.showSnackBarErrorPersonalized(
        context,
        decodedData["message"]?.toString() ?? "Erreur lors de la mise à jour."
      );
    }
  } catch (err) {
    if (!mounted) return;
    _authService.showSnackBarErrorPersonalized(
      context,
      "Erreur lors de la mise à jour: ${err.toString()}"
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, 
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
                      const Icon(Icons.lock_reset,
                        size: 48,
                        color: Color(0xFF003366)),
                      const SizedBox(height: 16),
                      Text("Changer le mot de passe",
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        )),
                      const SizedBox(height: 8),
                      Text("Votre mot de passe doit contenir au moins 6 caractères",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          fontSize: 14,
                        )),
                      const SizedBox(height: 24),
                      _buildCurrentPasswordField(),
                      const SizedBox(height: 16),
                      _buildNewPasswordField(),
                      const SizedBox(height: 16),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetToken(),
                              ),
                            );
                          },
                          child: Text("Mot de passe oublié ?",
                            style: GoogleFonts.roboto(
                              color: const Color(0xFF003366),
                              fontSize: 14,
                            )),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              : () => _debouncer.run(_submitForm),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text("METTRE À JOUR",
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

  Widget _buildCurrentPasswordField() {
    return TextFormField(
      controller: _currentPasswordController,
      obscureText: _obscureCurrentPassword,
      validator: (value) => 
          value?.isEmpty ?? true ? 'Mot de passe actuel requis' : null,
      decoration: InputDecoration(
        labelText: "Mot de passe actuel",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureCurrentPassword 
                ? Icons.visibility_off 
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => 
              _obscureCurrentPassword = !_obscureCurrentPassword),
        ),
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

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNewPassword,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Nouveau mot de passe requis';
        if (value!.length < 6) return 'Minimum 6 caractères';
        return null;
      },
      decoration: InputDecoration(
        labelText: "Nouveau mot de passe",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.lock_reset, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNewPassword 
                ? Icons.visibility_off 
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => 
              _obscureNewPassword = !_obscureNewPassword),
        ),
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
      obscureText: _obscureConfirmPassword,
      validator: (value) {
        if (value?.isEmpty ?? true) return 'Confirmation requise';
        if (value != _newPasswordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: "Confirmer le mot de passe",
        labelStyle: GoogleFonts.roboto(color: Colors.grey[600]),
        prefixIcon: const Icon(Icons.verified_user_outlined, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword 
                ? Icons.visibility_off 
                : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () => setState(() => 
              _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
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