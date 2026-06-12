import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/avatar.dart';
import '../../providers/avatar_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/territory_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/weight_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../onboarding/onboarding_screen.dart';

/// Ayarlar ekranı: dil (sistem/TR/EN) ve tema (sistem/açık/koyu) seçimi.
/// Seçimler sağlayıcılar üzerinden kalıcı olarak hatırlanır.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final avatarProvider = context.watch<AvatarProvider>();
    final weightProvider = context.watch<WeightProvider>();

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

          // --- Alan adı bölümü (kişinin tek alan adı; tüm topraklarında görünür) ---
          _SectionTitle(l10n.territoryNameLabel),
          _SettingsCard(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: _LandNameSetting(),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Avatar bölümü ---
          _SectionTitle(l10n.avatarLabel),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _AvatarPicker(
                  selected: avatarProvider.avatar,
                  onSelected: avatarProvider.setAvatar,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // --- Kilo bölümü (kalori tahmini için) ---
          _SectionTitle(l10n.weightLabel),
          _SettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: _WeightSetting(
                  weightKg: weightProvider.weightKg,
                  onChanged: weightProvider.setWeight,
                ),
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

          const SizedBox(height: 24),

          // --- Nasıl oynanır ---
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: Text(l10n.howToPlayLabel),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                ),
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

/// Kullanıcının tek alan adını düzenleyen bileşen. Kaydedince hem kullanıcı
/// dökümanı hem de mevcut tüm alanlarının etiketi güncellenir.
class _LandNameSetting extends StatefulWidget {
  const _LandNameSetting();

  @override
  State<_LandNameSetting> createState() => _LandNameSettingState();
}

class _LandNameSettingState extends State<_LandNameSetting> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<TerritoryProvider>().landName,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final territory = context.read<TerritoryProvider>();
    setState(() => _saving = true);
    await territory.setLandName(_controller.text);
    if (!mounted) return;
    setState(() => _saving = false);
    FocusScope.of(context).unfocus();
    showAppSnackBar(context, l10n.landNameUpdated,
        type: AppSnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: 30,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            labelText: l10n.territoryNameLabel,
            helperText: l10n.landNameHint,
            prefixIcon: const Icon(Icons.flag_rounded),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.saveButton),
          ),
        ),
      ],
    );
  }
}

/// Kiloyu (kg) bir kaydırıcıyla ayarlayan bileşen. Değer üstte gösterilir.
class _WeightSetting extends StatelessWidget {
  const _WeightSetting({required this.weightKg, required this.onChanged});

  final double weightKg;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weightValue(weightKg.round().toString()),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Slider(
          value: weightKg,
          min: WeightProvider.minWeightKg,
          max: WeightProvider.maxWeightKg,
          divisions:
              (WeightProvider.maxWeightKg - WeightProvider.minWeightKg).round(),
          label: weightKg.round().toString(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Avatarları yatay ızgara olarak gösteren ve seçim yaptıran bileşen.
/// Seçili avatar vurgulu bir çerçeveyle belirtilir.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.selected, required this.onSelected});

  final AppAvatar selected;
  final ValueChanged<AppAvatar> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final avatar in kAvatars)
          GestureDetector(
            onTap: () => onSelected(avatar),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: avatar == selected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: avatar == selected
                      ? scheme.primary
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Text(
                avatar.emoji,
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),
      ],
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
