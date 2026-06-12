import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

/// [AuthError] türünü, mevcut dile uygun kullanıcı metnine çevirir.
String localizedAuthError(AppLocalizations l10n, AuthError error) {
  switch (error) {
    case AuthError.invalidCredentials:
      return l10n.authErrorInvalidCredentials;
    case AuthError.usernameTaken:
      return l10n.authErrorUsernameTaken;
    case AuthError.weakPassword:
      return l10n.authErrorWeakPassword;
    case AuthError.network:
      return l10n.authErrorNetwork;
    case AuthError.generic:
      return l10n.authErrorGeneric;
  }
}
