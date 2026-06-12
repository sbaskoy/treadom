import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/location_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Eklentilerin (SharedPreferences gibi) main içinde kullanılabilmesi için
  // Flutter bağlamının hazır olduğundan emin oluyoruz.
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i platforma uygun yapılandırmayla başlat. flutterfire configure
  // tarafından üretilen DefaultFirebaseOptions kullanılır.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kaydedilmiş dil/tema tercihlerini ilk kareden önce yükleyebilmek için
  // SharedPreferences'i baştan açıyoruz (böylece açılışta titreme olmaz).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        Provider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: const TreadomApp(),
    ),
  );
}

/// Uygulamanın kök bileşeni. Dil ve tema sağlayıcılarını dinleyerek
/// [MaterialApp]'i buna göre yapılandırır.
class TreadomApp extends StatelessWidget {
  const TreadomApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Yalnızca ilgili sağlayıcıları dinleyip değişiminde yeniden çiziyoruz.
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      // Başlık çevrilebilir olduğu için onGenerateTitle kullanıyoruz.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      // --- Tema ---
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,

      // --- Yerelleştirme (i18n) ---
      locale: localeProvider.locale, // null => sistem dili
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const AuthGate(),
    );
  }
}
