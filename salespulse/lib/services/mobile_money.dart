import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class OrangeMoneyService {
  final String clientId = 'TON_CLIENT_ID';
  final String clientSecret = 'TON_CLIENT_SECRET';
  final String merchantKey = 'TON_MERCHANT_KEY';

  final Dio dio = Dio();

  /// 🔐 Étape 1 : Obtenir access_token
  Future<String?> _getAccessToken() async {
    final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));

    try {
      final response = await dio.post(
        'https://api.orange.com/oauth/v3/token',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'grant_type': 'client_credentials'},
      );

      return response.data['access_token'];
    } catch (e) {
      debugPrint("Erreur token: $e");
      return null;
    }
  }

  /// 💳 Étape 2 : Initier un paiement
  Future<String?> initierPaiement({
    required int amount,
    required String orderId,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await dio.post(
        'https://api.orange.com/orange-money-webpay/dev/v1/webpayment',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "merchant_key": merchantKey,
          "currency": "XOF",
          "order_id": orderId,
          "amount": amount.toString(),
          "return_url": "https://tonsite.com/success",
          "cancel_url": "https://tonsite.com/cancel",
          "notif_url": "https://tonsite.com/notify",
          "lang": "fr"
        },
      );

      return response.data['payment_url'];
    } catch (e) {
      debugPrint("Erreur initier paiement: $e");
      return null;
    }
  }

  /// 🌐 Étape 3 : Ouvrir la page de paiement
  Future<void> openPaiementUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir $url';
    }
  }

     /// 📦 Fonction complète pour lancer le paiement
  Future<void> payer({
    required int amount,
    required String orderId,
  }) async {
    final url = await initierPaiement(amount: amount, orderId: orderId,);
    if (url != null) {
      await openPaiementUrl(url);
    } else {
     debugPrint("Échec de l'obtention de l'URL de paiement.");
    }
  }

}


class MobiCashService {
  final String clientId = 'TON_CLIENT_ID';
  final String clientSecret = 'TON_CLIENT_SECRET';
  final String merchantKey = 'TON_MERCHANT_KEY';

  final Dio dio = Dio();

  /// Étape 1 : Obtenir le token
  Future<String?> _getAccessToken() async {
    final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));

    try {
      final response = await dio.post(
        'https://api.mobicash.com/oauth/token',
        options: Options(
          headers: {
            'Authorization': 'Basic $basicAuth',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'grant_type': 'client_credentials'},
      );

      return response.data['access_token'];
    } catch (e) {
     debugPrint("Erreur token MobiCash: $e");
      return null;
    }
  }

  /// Étape 2 : Initier le paiement
  Future<String?> initierPaiement({
    required int amount,
    required String orderId,
  }) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final response = await dio.post(
        'https://api.mobicash.com/payments/initiate',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "merchant_key": merchantKey,
          "order_id": orderId,
          "amount": amount.toString(),
          "currency": "XOF",
          "return_url": "https://tonsite.com/success",
          "cancel_url": "https://tonsite.com/cancel",
          "notif_url": "https://tonsite.com/notify",
        },
      );

      return response.data['payment_url'];
    } catch (e) {
     debugPrint("Erreur initier paiement MobiCash: $e");
      return null;
    }
  }

  /// Ouvrir l'URL de paiement
  Future<void> openPaiementUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Impossible d’ouvrir $url';
    }
  }

  /// Lancer le paiement complet
  Future<void> payer({
    required int amount,
    required String orderId,
  }) async {
    final url = await initierPaiement(amount: amount, orderId: orderId);
    if (url != null) {
      await openPaiementUrl(url);
    } else {
     debugPrint("Échec de l'URL de paiement MobiCash.");
    }
  }
}