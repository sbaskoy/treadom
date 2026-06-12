import 'package:flutter/material.dart';

/// Bildirim türüne göre renk ve ikon seçimi için kullanılır.
enum AppSnackBarType { error, success, info }

/// Uygulama genelinde tutarlı, modern bir bildirim (snackbar) gösterir.
///
/// Yüzen (floating) yapı, yuvarlak köşeler, türüne göre renkli arka plan ve
/// öndeki bir ikon ile Material 3 hissi verir. Aynı anda yalnızca bir bildirim
/// görünür; yenisi gelince öncekini temizler.
void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  final scheme = Theme.of(context).colorScheme;

  final Color background;
  final Color foreground;
  final IconData icon;
  switch (type) {
    case AppSnackBarType.error:
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
      icon = Icons.error_outline_rounded;
    case AppSnackBarType.success:
      background = scheme.primaryContainer;
      foreground = scheme.onPrimaryContainer;
      icon = Icons.check_circle_outline_rounded;
    case AppSnackBarType.info:
      background = scheme.secondaryContainer;
      foreground = scheme.onSecondaryContainer;
      icon = Icons.info_outline_rounded;
  }

  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        elevation: 6,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                  fontSize: 14.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
