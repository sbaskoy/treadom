import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/avatar_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/location_provider.dart';
import 'providers/run_provider.dart';
import 'providers/territory_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weight_provider.dart';
import 'screens/root_screen.dart';
import 'services/foreground_service.dart';
import 'services/push_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Eklentilerin (SharedPreferences gibi) main içinde kullanılabilmesi için
  // Flutter bağlamının hazır olduğundan emin oluyoruz.
  WidgetsFlutterBinding.ensureInitialized();

  // İçeriğin (özellikle haritanın) durum ve gezinme çubuklarının arkasına da
  // çizilerek gerçek anlamda tam ekran görünmesi için edge-to-edge moduna
  // geçiyoruz ve sistem çubuklarını şeffaf yapıyoruz.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Firebase'i platforma uygun yapılandırmayla başlat. flutterfire configure
  // tarafından üretilen DefaultFirebaseOptions kullanılır.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Uygulama arka planda/kapalıyken gelen push bildirimleri için en üst seviye
  // işleyiciyi kaydet (runApp'tan önce kayıtlı olmalı).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Arka plan görev izolatı ile ana izolat arasındaki veri kanalını açıyoruz
  // (koşu noktalarının haritaya akması bununla çalışır). Web'de no-op.
  FlutterForegroundTask.initCommunicationPort();

  // Kaydedilmiş dil/tema tercihlerini ilk kareden önce yükleyebilmek için
  // SharedPreferences'i baştan açıyoruz (böylece açılışta titreme olmaz).
  final prefs = await SharedPreferences.getInstance();

  final foregroundService = ForegroundService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AvatarProvider(prefs)),
        ChangeNotifierProvider(create: (_) => WeightProvider(prefs)),
        Provider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(
          create: (_) => RunProvider(foregroundService: foregroundService),
        ),
        ChangeNotifierProvider(create: (_) => TerritoryProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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

      // WithForegroundTask: koşu servisi çalışırken geri tuşu uygulamayı
      // kapatmak yerine arka plana alır (servis ve takip sürer).
      home: const WithForegroundTask(child: RootScreen()),
    );
  }
}
