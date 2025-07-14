

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:salespulse/providers/auth_provider.dart';
import 'package:salespulse/utils/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données locales pour 'fr_FR'
  await initializeDateFormatting('fr_FR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SalesPulse',
      debugShowCheckedModeBanner: false,
      locale: Locale('fr', 'FR'), // Définir la locale par défaut
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('fr', 'FR'),
      ],
      home: MySplashScreen(),
    );
  }
}
