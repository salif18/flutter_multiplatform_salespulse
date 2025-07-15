
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:salespulse/models/profil_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String _token = "";
  String _userId = "";
  String _userName = "";
  String _societeName = "";
  String _societeNumber = "";
  String _adminId = "";
  String _role = "";
  bool _isLoading = false;
  ProfilModel? _profil;

  

  ProfilModel? get profil => _profil;
  String get token => _token;
  String get userId => _userId;
  String get adminId => _adminId;
  String get userName => _userName;
  String get societeName => _societeName;
  String get societeNumber => _societeNumber;
  String get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token.isNotEmpty && !_isTokenExpired;

  AuthProvider() {
    _loadUserData();
  }

  // Vérifie si le token est expiré
  bool get _isTokenExpired {
    if (_token.isEmpty) return true;
    
    try {
      // Décodage du JWT (partie payload)
      final parts = _token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      // Vérifie si la date d'expiration est passée
      return DateTime.now().millisecondsSinceEpoch > exp * 1000;
    } catch (e) {
      return true; // Si erreur de décodage, considérer comme expiré
    }
  }

  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString("token") ?? "";
    _userId = prefs.getString("userId") ?? "";
    _userName = prefs.getString("userName") ?? "";
    _societeName = prefs.getString("societeName") ?? "";
    _societeNumber = prefs.getString("societeNumber") ?? "";
    _role = prefs.getString("role") ?? "";
    _adminId = prefs.getString("adminId") ?? "";

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToLocalStorage(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData));
    notifyListeners();
  }

  Future<void> loginButton(
    String userToken, 
    String userUserId,
    String adminId, 
    String role,
    String userName,  
    String number,   
    String entreprise,
  ) async {
    _isLoading = true;
    notifyListeners();
    
    _token = userToken;
    _userId = userUserId;
    _adminId = adminId;
    _role = role;
    _userName = userName;   
    _societeNumber = number;
    _societeName = entreprise;

    await saveToLocalStorage("token", _token);
    await saveToLocalStorage("userId", _userId);
    await saveToLocalStorage("userName", _userName);
    await saveToLocalStorage("societeName", _societeName);
    await saveToLocalStorage("societeNumber", _societeNumber);
    await saveToLocalStorage("adminId", _adminId);
    await saveToLocalStorage("role", _role);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProfilData(ProfilModel? profil) async {
    _profil = profil;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profil_data', jsonEncode(profil?.toJson()));
    notifyListeners();
  }

  Future<void> loadProfilData() async {
    final prefs = await SharedPreferences.getInstance();
    final profilData = prefs.getString('profil_data');
    
    if (profilData != null) {
      try {
        _profil = ProfilModel.fromJson(jsonDecode(profilData));
        notifyListeners();
      } catch (e) {
        debugPrint("Erreur de décodage du profil: $e");
      }
    }
  }

  Future<void> clearProfilData() async {
    _profil = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profil_data');
    notifyListeners();
  }


  Future<void> logoutButton() async {
    _isLoading = true;
    notifyListeners();
    
    _token = "";
    _userId = ""; 
    _adminId = "";
    _role = "";
    _userName = "";    
    _societeNumber = "";
    _societeName = "";
    _profil = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoading = false;
    notifyListeners();
  }

  // Méthode pour vérifier et gérer l'authentification
  Future<bool> checkAuth() async {
    if (!isAuthenticated) {
      await logoutButton();
      return false;
    }
    return true;
  }
}
