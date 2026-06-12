import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The application name, shown in the title bar and home screen.
  ///
  /// In en, this message translates to:
  /// **'Treadom'**
  String get appTitle;

  /// Short marketing tagline describing the game.
  ///
  /// In en, this message translates to:
  /// **'Walk. Conquer. Rule the map.'**
  String get appTagline;

  /// Greeting shown on the home placeholder screen.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Treadom!'**
  String get welcomeMessage;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Label for the language selector.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// Option to follow the device language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label for the theme selector.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label for the avatar selector in settings.
  ///
  /// In en, this message translates to:
  /// **'Avatar'**
  String get avatarLabel;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpButton;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButton;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @haveAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get haveAccountPrompt;

  /// No description provided for @goToRegister.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get goToRegister;

  /// No description provided for @goToLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get goToLogin;

  /// No description provided for @validationUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get validationUsernameRequired;

  /// No description provided for @validationUsernameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get validationUsernameTooShort;

  /// No description provided for @validationUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers and underscore'**
  String get validationUsernameInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordTooShort;

  /// No description provided for @validationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordMismatch;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this username'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Username or password is incorrect'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get authErrorUsernameTaken;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get authErrorGeneric;

  /// Shown on the home screen with the current user's name.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {username}'**
  String loggedInAs(String username);

  /// Title of the map screen shown in the app bar.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// Tooltip for the button that recenters the map on the user.
  ///
  /// In en, this message translates to:
  /// **'Center on my location'**
  String get recenterTooltip;

  /// Shown while the first location fix is being acquired.
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get locationLoading;

  /// No description provided for @locationServiceDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is off'**
  String get locationServiceDisabledTitle;

  /// No description provided for @locationServiceDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on your device\'s location (GPS) service to see yourself on the map.'**
  String get locationServiceDisabledMessage;

  /// No description provided for @locationPermissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionDeniedTitle;

  /// No description provided for @locationPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Treadom needs your location to work. Please grant the location permission.'**
  String get locationPermissionDeniedMessage;

  /// No description provided for @locationPermissionDeniedForeverMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. You need to enable it from system settings.'**
  String get locationPermissionDeniedForeverMessage;

  /// No description provided for @openSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retryButton;

  /// Button that starts tracking the user's run.
  ///
  /// In en, this message translates to:
  /// **'Start Running'**
  String get startRunButton;

  /// No description provided for @stopRunButton.
  ///
  /// In en, this message translates to:
  /// **'Finish Run'**
  String get stopRunButton;

  /// No description provided for @newRunButton.
  ///
  /// In en, this message translates to:
  /// **'New Run'**
  String get newRunButton;

  /// No description provided for @runDistanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get runDistanceLabel;

  /// No description provided for @runAreaLabel.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get runAreaLabel;

  /// No description provided for @runFinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Run complete!'**
  String get runFinishedTitle;

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String distanceMeters(String meters);

  /// No description provided for @distanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKilometers(String km);

  /// No description provided for @areaSquareMeters.
  ///
  /// In en, this message translates to:
  /// **'{value} m²'**
  String areaSquareMeters(String value);

  /// No description provided for @areaSquareKilometers.
  ///
  /// In en, this message translates to:
  /// **'{value} km²'**
  String areaSquareKilometers(String value);

  /// No description provided for @runElapsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get runElapsedLabel;

  /// No description provided for @runPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get runPaceLabel;

  /// No description provided for @runCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get runCaloriesLabel;

  /// No description provided for @caloriesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String caloriesValue(String value);

  /// No description provided for @paceSuffix.
  ///
  /// In en, this message translates to:
  /// **'/km'**
  String get paceSuffix;

  /// No description provided for @unitKilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKilometers;

  /// No description provided for @unitMeters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitMeters;

  /// No description provided for @unitKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unitKcal;

  /// Title of the ongoing run notification.
  ///
  /// In en, this message translates to:
  /// **'Run in progress'**
  String get runOngoingTitle;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Run tracking'**
  String get notificationChannelName;

  /// No description provided for @weightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// No description provided for @weightValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String weightValue(String value);

  /// Title of the dialog shown after closing a loop to name the new territory.
  ///
  /// In en, this message translates to:
  /// **'Name your land'**
  String get claimTitle;

  /// No description provided for @claimMessage.
  ///
  /// In en, this message translates to:
  /// **'You enclosed an area of {area}. Give it a name, or leave it blank to use your username.'**
  String claimMessage(String area);

  /// No description provided for @territoryNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Land name'**
  String get territoryNameLabel;

  /// No description provided for @landNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown on all of your land'**
  String get landNameHint;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @landNameUpdated.
  ///
  /// In en, this message translates to:
  /// **'Land name updated'**
  String get landNameUpdated;

  /// No description provided for @claimButton.
  ///
  /// In en, this message translates to:
  /// **'Claim Land'**
  String get claimButton;

  /// No description provided for @claimedSnack.
  ///
  /// In en, this message translates to:
  /// **'You claimed \"{name}\"!'**
  String claimedSnack(String name);

  /// No description provided for @landsConquered.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 enemy land conquered!} other{{count} enemy lands conquered!}}'**
  String landsConquered(int count);

  /// No description provided for @runSavedSnack.
  ///
  /// In en, this message translates to:
  /// **'Run saved to your history.'**
  String get runSavedSnack;

  /// No description provided for @loopNotClosedHint.
  ///
  /// In en, this message translates to:
  /// **'No land taken — close the loop by returning to your start point (or back into your own land).'**
  String get loopNotClosedHint;

  /// No description provided for @loopTooShortHint.
  ///
  /// In en, this message translates to:
  /// **'No land taken — go a bit farther, then loop back to close it.'**
  String get loopTooShortHint;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Walking History'**
  String get historyTitle;

  /// No description provided for @historyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Walking history'**
  String get historyTooltip;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Start running to fill your history with routes and conquered lands.'**
  String get historyEmptyMessage;

  /// No description provided for @historyClaimedBadge.
  ///
  /// In en, this message translates to:
  /// **'Land claimed'**
  String get historyClaimedBadge;

  /// No description provided for @historyConqueredBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 conquered} other{{count} conquered}}'**
  String historyConqueredBadge(int count);

  /// No description provided for @territoryOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'{username}\'s land'**
  String territoryOwnerLabel(String username);

  /// No description provided for @territoryYoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Your land'**
  String get territoryYoursLabel;

  /// No description provided for @territoryClaimedLabel.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get territoryClaimedLabel;

  /// No description provided for @territoryConqueredFromLabel.
  ///
  /// In en, this message translates to:
  /// **'Conquered from {username}'**
  String territoryConqueredFromLabel(String username);

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboardTooltip;

  /// No description provided for @leaderboardYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get leaderboardYou;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No lands claimed yet. Be the first!'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardNoRank.
  ///
  /// In en, this message translates to:
  /// **'Claim a land to enter the ranking.'**
  String get leaderboardNoRank;

  /// No description provided for @leaderboardCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 land} other{{count} lands}}'**
  String leaderboardCount(int count);

  /// No description provided for @howToPlayLabel.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get howToPlayLabel;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Walk to claim land'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Start a run and walk a closed loop. The area you circle becomes your land.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Encircle to conquer'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Run around a rival\'s land to take it. Fully surround it to take all of it; cross only part and you take just that piece.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Rule the map'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Climb the leaderboard, name your land from settings, and find players near you.'**
  String get onboardingBody3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardingStart;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTooltip;

  /// No description provided for @profileRankLabel.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get profileRankLabel;

  /// No description provided for @profileLandsLabel.
  ///
  /// In en, this message translates to:
  /// **'Lands'**
  String get profileLandsLabel;

  /// No description provided for @profileRunsLabel.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get profileRunsLabel;

  /// No description provided for @profileConquestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Conquests'**
  String get profileConquestsLabel;

  /// No description provided for @profileUnranked.
  ///
  /// In en, this message translates to:
  /// **'Unranked'**
  String get profileUnranked;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// No description provided for @chatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTooltip;

  /// No description provided for @chatNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby players'**
  String get chatNearbyTitle;

  /// No description provided for @chatNearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No players nearby right now.'**
  String get chatNearbyEmpty;

  /// No description provided for @chatNoLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your location…'**
  String get chatNoLocation;

  /// No description provided for @chatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatEmptyTitle;

  /// No description provided for @chatEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Find nearby players and start chatting.'**
  String get chatEmptyMessage;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get chatMessageHint;

  /// No description provided for @chatEnded.
  ///
  /// In en, this message translates to:
  /// **'This chat has ended.'**
  String get chatEnded;

  /// No description provided for @chatEndChat.
  ///
  /// In en, this message translates to:
  /// **'End chat'**
  String get chatEndChat;

  /// No description provided for @chatEndConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'End chat?'**
  String get chatEndConfirmTitle;

  /// No description provided for @chatEndConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Neither of you will be able to message again.'**
  String get chatEndConfirmMessage;

  /// No description provided for @chatAway.
  ///
  /// In en, this message translates to:
  /// **'{dist} away'**
  String chatAway(String dist);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search players by username'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No player found'**
  String get searchNoResults;

  /// No description provided for @searchNoTerritory.
  ///
  /// In en, this message translates to:
  /// **'{username} has no land yet'**
  String searchNoTerritory(String username);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
