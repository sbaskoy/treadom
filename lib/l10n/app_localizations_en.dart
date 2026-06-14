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
  String get avatarLabel => 'Avatar';

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

  @override
  String get startRunButton => 'Start Running';

  @override
  String get stopRunButton => 'Finish Run';

  @override
  String get newRunButton => 'New Run';

  @override
  String get runDistanceLabel => 'Distance';

  @override
  String get runAreaLabel => 'Area';

  @override
  String get runFinishedTitle => 'Run complete!';

  @override
  String distanceMeters(String meters) {
    return '$meters m';
  }

  @override
  String distanceKilometers(String km) {
    return '$km km';
  }

  @override
  String areaSquareMeters(String value) {
    return '$value m²';
  }

  @override
  String areaSquareKilometers(String value) {
    return '$value km²';
  }

  @override
  String get runElapsedLabel => 'Time';

  @override
  String get runPaceLabel => 'Pace';

  @override
  String get runCaloriesLabel => 'Calories';

  @override
  String caloriesValue(String value) {
    return '$value kcal';
  }

  @override
  String get paceSuffix => '/km';

  @override
  String get unitKilometers => 'km';

  @override
  String get unitMeters => 'm';

  @override
  String get unitKcal => 'kcal';

  @override
  String get runOngoingTitle => 'Run in progress';

  @override
  String get notificationChannelName => 'Run tracking';

  @override
  String get weightLabel => 'Weight';

  @override
  String weightValue(String value) {
    return '$value kg';
  }

  @override
  String get claimTitle => 'Name your land';

  @override
  String claimMessage(String area) {
    return 'You enclosed an area of $area. Give it a name, or leave it blank to use your username.';
  }

  @override
  String get territoryNameLabel => 'Land name';

  @override
  String get landNameHint => 'Shown on all of your land';

  @override
  String get saveButton => 'Save';

  @override
  String get landNameUpdated => 'Land name updated';

  @override
  String get claimButton => 'Claim Land';

  @override
  String claimedSnack(String name) {
    return 'You claimed \"$name\"!';
  }

  @override
  String landsConquered(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count enemy lands conquered!',
      one: '1 enemy land conquered!',
    );
    return '$_temp0';
  }

  @override
  String get runSavedSnack => 'Run saved to your history.';

  @override
  String get loopNotClosedHint =>
      'No land taken — close the loop by returning to your start point (or back into your own land).';

  @override
  String get loopTooShortHint =>
      'No land taken — go a bit farther, then loop back to close it.';

  @override
  String get loopTooFastHint =>
      'No land taken — you moved too fast. Treadom only counts walking or running, not driving.';

  @override
  String get historyTitle => 'Walking History';

  @override
  String get historyTooltip => 'Walking history';

  @override
  String get historyEmptyTitle => 'No runs yet';

  @override
  String get historyEmptyMessage =>
      'Start running to fill your history with routes and conquered lands.';

  @override
  String get historyClaimedBadge => 'Land claimed';

  @override
  String historyConqueredBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conquered',
      one: '1 conquered',
    );
    return '$_temp0';
  }

  @override
  String territoryOwnerLabel(String username) {
    return '$username\'s land';
  }

  @override
  String get territoryYoursLabel => 'Your land';

  @override
  String get territoryClaimedLabel => 'Claimed';

  @override
  String territoryConqueredFromLabel(String username) {
    return 'Conquered from $username';
  }

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardTooltip => 'Leaderboard';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardEmpty => 'No lands claimed yet. Be the first!';

  @override
  String get leaderboardNoRank => 'Claim a land to enter the ranking.';

  @override
  String leaderboardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lands',
      one: '1 land',
    );
    return '$_temp0';
  }

  @override
  String get howToPlayLabel => 'How to play';

  @override
  String get accountLabel => 'Account';

  @override
  String get deleteAccountLabel => 'Delete account';

  @override
  String get deleteAccountSubtitle =>
      'Permanently delete your account and all data';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountMessage =>
      'This action CANNOT be undone. The following will be permanently deleted:\n\n• Your account and username\n• All your run history\n• All territories you own\n• Your chats and messages\n\nDo you want to continue?';

  @override
  String get deleteAccountConfirm => 'Delete account';

  @override
  String get deleteAccountError =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get onboardingTitle1 => 'Walk to claim land';

  @override
  String get onboardingBody1 =>
      'Start a run and walk a closed loop. The area you circle becomes your land.';

  @override
  String get onboardingTitle2 => 'Encircle to conquer';

  @override
  String get onboardingBody2 =>
      'Run around a rival\'s land to take it. Fully surround it to take all of it; cross only part and you take just that piece.';

  @override
  String get onboardingTitle3 => 'Rule the map';

  @override
  String get onboardingBody3 =>
      'Climb the leaderboard, name your land from settings, and find players near you.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileTooltip => 'Profile';

  @override
  String get profileRankLabel => 'Rank';

  @override
  String get profileLandsLabel => 'Lands';

  @override
  String get profileRunsLabel => 'Runs';

  @override
  String get profileConquestsLabel => 'Conquests';

  @override
  String get profileUnranked => 'Unranked';

  @override
  String get chatTitle => 'Messages';

  @override
  String get chatTooltip => 'Messages';

  @override
  String get chatNearbyTitle => 'Nearby players';

  @override
  String get chatNearbyEmpty => 'No players nearby right now.';

  @override
  String get chatNoLocation => 'Waiting for your location…';

  @override
  String get chatEmptyTitle => 'No conversations yet';

  @override
  String get chatEmptyMessage => 'Find nearby players and start chatting.';

  @override
  String get chatMessageHint => 'Message';

  @override
  String get chatEnded => 'This chat has ended.';

  @override
  String get chatEndChat => 'End chat';

  @override
  String get chatEndConfirmTitle => 'End chat?';

  @override
  String get chatEndConfirmMessage =>
      'Neither of you will be able to message again.';

  @override
  String chatAway(String dist) {
    return '$dist away';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get searchHint => 'Search players by username';

  @override
  String get searchNoResults => 'No player found';

  @override
  String searchNoTerritory(String username) {
    return '$username has no land yet';
  }
}
