// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Treadom';

  @override
  String get appTagline => 'Walk. Conquer. Rule the map.';

  @override
  String get welcomeMessage => 'Welcome to Treadom!';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get usernameLabel => 'Username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get goToRegister => 'Sign Up';

  @override
  String get goToLogin => 'Sign In';

  @override
  String get validationUsernameRequired => 'Please enter a username';

  @override
  String get validationUsernameTooShort =>
      'Username must be at least 3 characters';

  @override
  String get validationUsernameInvalid =>
      'Use only letters, numbers and underscore';

  @override
  String get validationPasswordRequired => 'Please enter a password';

  @override
  String get validationPasswordTooShort =>
      'Password must be at least 6 characters';

  @override
  String get validationPasswordMismatch => 'Passwords do not match';

  @override
  String get authErrorUserNotFound => 'No account found with this username';

  @override
  String get authErrorWrongPassword => 'Incorrect password';

  @override
  String get authErrorInvalidCredentials => 'Username or password is incorrect';

  @override
  String get authErrorUsernameTaken => 'This username is already taken';

  @override
  String get authErrorWeakPassword => 'Password is too weak';

  @override
  String get authErrorNetwork => 'Network error. Check your connection';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again';

  @override
  String loggedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get mapTitle => 'Map';

  @override
  String get recenterTooltip => 'Center on my location';

  @override
  String get locationLoading => 'Getting your location…';

  @override
  String get locationServiceDisabledTitle => 'Location is off';

  @override
  String get locationServiceDisabledMessage =>
      'Turn on your device\'s location (GPS) service to see yourself on the map.';

  @override
  String get locationPermissionDeniedTitle => 'Location permission needed';

  @override
  String get locationPermissionDeniedMessage =>
      'Treadom needs your location to work. Please grant the location permission.';

  @override
  String get locationPermissionDeniedForeverMessage =>
      'Location permission was permanently denied. You need to enable it from system settings.';

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get retryButton => 'Try Again';
}
