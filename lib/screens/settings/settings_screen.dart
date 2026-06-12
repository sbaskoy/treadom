import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';

/// Ayarlar ekranı: dil (sistem/TR/EN) ve tema (sistem/açık/koyu) seçimi.
/// Seçimler sağlayıcılar üzerinden kalıcı olarak hatırlanır.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    // Seçili dilin dil kodu (null => sistem).
    final currentLangCode = localeProvider.locale?.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Dil bölümü ---
          _SectionTitle(l10n.languageLabel),
          _SettingsCard(
            children: [
              RadioListTile<String?>(
                title: Text(l10n.languageSystem),
                value: null,
                groupValue: currentLangCode,
                onChanged: (_) => localeProvider.setLocale(null),
              ),
              RadioListTile<String?>(
                title: Text(l10n.languageTurkish),
                value: 'tr',
                groupValue: currentLangCode,
                onChanged: (_) => localeProvider.setLocale(const Locale('tr')),
              ),
              RadioListTile<String?>(
                title: Text(l10n.languageEnglish),
                value: 'en',
                groupValue: currentLangCode,
                onChanged: (_) => localeProvider.setLocale(const Locale('en')),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Tema bölümü ---
          _SectionTitle(l10n.themeLabel),
          _SettingsCard(
            children: [
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeSystem),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) => themeProvider.setThemeMode(mode!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeLight),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) => themeProvider.setThemeMode(mode!),
              ),
              RadioListTile<ThemeMode>(
                title: Text(l10n.themeDark),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) => themeProvider.setThemeMode(mode!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığı (örn. "Dil", "Tema").
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Ayar seçeneklerini içeren yuvarlatılmış kart sarmalayıcısı.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
