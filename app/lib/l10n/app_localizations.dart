import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_he.dart';

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
  static const List<Locale> supportedLocales = <Locale>[Locale('he')];

  /// No description provided for @appTitle.
  ///
  /// In he, this message translates to:
  /// **'לבשל כל אחד יכול'**
  String get appTitle;

  /// No description provided for @kitchenTitle.
  ///
  /// In he, this message translates to:
  /// **'המטבח שלי'**
  String get kitchenTitle;

  /// No description provided for @continueCooking.
  ///
  /// In he, this message translates to:
  /// **'המשך בישול'**
  String get continueCooking;

  /// No description provided for @myRecipes.
  ///
  /// In he, this message translates to:
  /// **'המתכונים שלי'**
  String get myRecipes;

  /// No description provided for @favorites.
  ///
  /// In he, this message translates to:
  /// **'מועדפים'**
  String get favorites;

  /// No description provided for @cookingHistory.
  ///
  /// In he, this message translates to:
  /// **'היסטוריית בישול'**
  String get cookingHistory;

  /// No description provided for @settings.
  ///
  /// In he, this message translates to:
  /// **'הגדרות'**
  String get settings;

  /// No description provided for @newRecipe.
  ///
  /// In he, this message translates to:
  /// **'מתכון חדש'**
  String get newRecipe;

  /// No description provided for @noActiveSession.
  ///
  /// In he, this message translates to:
  /// **'אין בישול פעיל כרגע'**
  String get noActiveSession;

  /// No description provided for @importComingSoon.
  ///
  /// In he, this message translates to:
  /// **'ייבוא מתכונים חדשים (טקסט, תמונה וקישור) יתווסף בשלב הבא'**
  String get importComingSoon;

  /// No description provided for @backendConnecting.
  ///
  /// In he, this message translates to:
  /// **'מתחבר לשרת…'**
  String get backendConnecting;

  /// No description provided for @backendWakingUp.
  ///
  /// In he, this message translates to:
  /// **'השרת מתעורר… זה יכול לקחת עד דקה'**
  String get backendWakingUp;

  /// No description provided for @backendOk.
  ///
  /// In he, this message translates to:
  /// **'השרת מחובר ✓'**
  String get backendOk;

  /// No description provided for @aiModeDemo.
  ///
  /// In he, this message translates to:
  /// **'מצב הדגמה (ללא בינה מלאכותית)'**
  String get aiModeDemo;

  /// No description provided for @aiModeLive.
  ///
  /// In he, this message translates to:
  /// **'בינה מלאכותית מחוברת'**
  String get aiModeLive;

  /// No description provided for @aiModeUnknown.
  ///
  /// In he, this message translates to:
  /// **'מצב בינה מלאכותית לא ידוע'**
  String get aiModeUnknown;

  /// No description provided for @backendOffline.
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לשרת'**
  String get backendOffline;

  /// No description provided for @offlineCookingNote.
  ///
  /// In he, this message translates to:
  /// **'אפשר לבשל גם בלי חיבור'**
  String get offlineCookingNote;

  /// No description provided for @retry.
  ///
  /// In he, this message translates to:
  /// **'נסו שוב'**
  String get retry;

  /// No description provided for @databaseReady.
  ///
  /// In he, this message translates to:
  /// **'מסד הנתונים מוכן (גרסה {version})'**
  String databaseReady(int version);

  /// No description provided for @errorGeneric.
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש. נסו שוב.'**
  String get errorGeneric;

  /// No description provided for @allRecipes.
  ///
  /// In he, this message translates to:
  /// **'הכל'**
  String get allRecipes;

  /// No description provided for @searchRecipes.
  ///
  /// In he, this message translates to:
  /// **'חיפוש מתכון'**
  String get searchRecipes;

  /// No description provided for @noRecipes.
  ///
  /// In he, this message translates to:
  /// **'אין מתכונים עדיין'**
  String get noRecipes;

  /// No description provided for @noFavorites.
  ///
  /// In he, this message translates to:
  /// **'עוד לא סימנתם מתכונים כמועדפים'**
  String get noFavorites;

  /// No description provided for @sampleRecipeLabel.
  ///
  /// In he, this message translates to:
  /// **'מתכון לדוגמה'**
  String get sampleRecipeLabel;

  /// No description provided for @recipeNotFound.
  ///
  /// In he, this message translates to:
  /// **'המתכון לא נמצא'**
  String get recipeNotFound;

  /// No description provided for @ingredients.
  ///
  /// In he, this message translates to:
  /// **'מצרכים'**
  String get ingredients;

  /// No description provided for @equipment.
  ///
  /// In he, this message translates to:
  /// **'ציוד'**
  String get equipment;

  /// No description provided for @viewPlan.
  ///
  /// In he, this message translates to:
  /// **'תוכנית הבישול'**
  String get viewPlan;

  /// No description provided for @startCooking.
  ///
  /// In he, this message translates to:
  /// **'התחל בישול'**
  String get startCooking;

  /// No description provided for @addFavorite.
  ///
  /// In he, this message translates to:
  /// **'הוספה למועדפים'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In he, this message translates to:
  /// **'הסרה מהמועדפים'**
  String get removeFavorite;

  /// No description provided for @rename.
  ///
  /// In he, this message translates to:
  /// **'שינוי שם'**
  String get rename;

  /// No description provided for @renameTitle.
  ///
  /// In he, this message translates to:
  /// **'שם חדש למתכון'**
  String get renameTitle;

  /// No description provided for @save.
  ///
  /// In he, this message translates to:
  /// **'שמירה'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In he, this message translates to:
  /// **'ביטול'**
  String get cancel;

  /// No description provided for @viewSource.
  ///
  /// In he, this message translates to:
  /// **'המתכון המקורי'**
  String get viewSource;

  /// No description provided for @deleteRecipe.
  ///
  /// In he, this message translates to:
  /// **'מחיקת המתכון'**
  String get deleteRecipe;

  /// No description provided for @deleteRecipeConfirm.
  ///
  /// In he, this message translates to:
  /// **'למחוק את המתכון? גם היסטוריית הבישול שלו תימחק.'**
  String get deleteRecipeConfirm;

  /// No description provided for @delete.
  ///
  /// In he, this message translates to:
  /// **'מחיקה'**
  String get delete;

  /// No description provided for @recipeDeleted.
  ///
  /// In he, this message translates to:
  /// **'המתכון נמחק'**
  String get recipeDeleted;

  /// No description provided for @undo.
  ///
  /// In he, this message translates to:
  /// **'בטל'**
  String get undo;

  /// No description provided for @cannotDeleteActive.
  ///
  /// In he, this message translates to:
  /// **'אי אפשר למחוק מתכון בזמן בישול. סיימו או הפסיקו את הבישול קודם.'**
  String get cannotDeleteActive;

  /// No description provided for @estimate.
  ///
  /// In he, this message translates to:
  /// **'הערכה'**
  String get estimate;

  /// No description provided for @estimateHint.
  ///
  /// In he, this message translates to:
  /// **'ערך משוער — המתכון המקורי לא ציין אותו'**
  String get estimateHint;

  /// No description provided for @prepTasks.
  ///
  /// In he, this message translates to:
  /// **'הכנות מראש'**
  String get prepTasks;

  /// No description provided for @steps.
  ///
  /// In he, this message translates to:
  /// **'שלבים'**
  String get steps;

  /// No description provided for @stepNumber.
  ///
  /// In he, this message translates to:
  /// **'שלב {number}'**
  String stepNumber(int number);

  /// No description provided for @afterSteps.
  ///
  /// In he, this message translates to:
  /// **'אחרי: {steps}'**
  String afterSteps(String steps);

  /// No description provided for @canRunInParallel.
  ///
  /// In he, this message translates to:
  /// **'אפשר במקביל לשלבים אחרים'**
  String get canRunInParallel;

  /// No description provided for @timerLabel.
  ///
  /// In he, this message translates to:
  /// **'טיימר: {label} ({duration})'**
  String timerLabel(String label, String duration);

  /// No description provided for @temperatureLabel.
  ///
  /// In he, this message translates to:
  /// **'טמפרטורה: {value}°'**
  String temperatureLabel(int value);

  /// No description provided for @leadTime.
  ///
  /// In he, this message translates to:
  /// **'כ-{minutes} דקות לפני שצריך'**
  String leadTime(int minutes);

  /// No description provided for @noPlan.
  ///
  /// In he, this message translates to:
  /// **'אין תוכנית בישול למתכון הזה'**
  String get noPlan;

  /// No description provided for @planActions.
  ///
  /// In he, this message translates to:
  /// **'תאשרו בזמן הבישול:'**
  String get planActions;

  /// No description provided for @activeSessionTitle.
  ///
  /// In he, this message translates to:
  /// **'כבר יש בישול פעיל'**
  String get activeSessionTitle;

  /// No description provided for @activeSessionBody.
  ///
  /// In he, this message translates to:
  /// **'כרגע מתבשל: {title}. אפשר להמשיך אותו, או להפסיק אותו ולהתחיל מחדש.'**
  String activeSessionBody(String title);

  /// No description provided for @goToActive.
  ///
  /// In he, this message translates to:
  /// **'המשך לבישול הפעיל'**
  String get goToActive;

  /// No description provided for @exactAlarmPromptTitle.
  ///
  /// In he, this message translates to:
  /// **'טיימרים שמתריעים בזמן'**
  String get exactAlarmPromptTitle;

  /// No description provided for @exactAlarmPromptBody.
  ///
  /// In he, this message translates to:
  /// **'כדי שהטיימרים יתריעו בדיוק בזמן, צריך לאשר לאפליקציה \"התראות ותזכורות\" בהגדרות הטלפון. בלי האישור, התראה עלולה להתעכב בכמה דקות.'**
  String get exactAlarmPromptBody;

  /// No description provided for @allowInSettings.
  ///
  /// In he, this message translates to:
  /// **'אישור בהגדרות'**
  String get allowInSettings;

  /// No description provided for @continueWithout.
  ///
  /// In he, this message translates to:
  /// **'להמשיך בלי'**
  String get continueWithout;

  /// No description provided for @abandonAndStart.
  ///
  /// In he, this message translates to:
  /// **'הפסק והתחל חדש'**
  String get abandonAndStart;

  /// No description provided for @cookingProgress.
  ///
  /// In he, this message translates to:
  /// **'{done} מתוך {total} שלבים הושלמו'**
  String cookingProgress(int done, int total);

  /// No description provided for @nowLabel.
  ///
  /// In he, this message translates to:
  /// **'עכשיו'**
  String get nowLabel;

  /// No description provided for @waitingForTimer.
  ///
  /// In he, this message translates to:
  /// **'ממתינים לטיימר: {label}'**
  String waitingForTimer(String label);

  /// No description provided for @startsTimer.
  ///
  /// In he, this message translates to:
  /// **'יפעיל טיימר: {label} ({duration})'**
  String startsTimer(String label, String duration);

  /// No description provided for @meanwhileTitle.
  ///
  /// In he, this message translates to:
  /// **'בינתיים אפשר'**
  String get meanwhileTitle;

  /// No description provided for @prepNeededNow.
  ///
  /// In he, this message translates to:
  /// **'נדרש עכשיו'**
  String get prepNeededNow;

  /// No description provided for @allSteps.
  ///
  /// In he, this message translates to:
  /// **'כל השלבים'**
  String get allSteps;

  /// No description provided for @stepLocked.
  ///
  /// In he, this message translates to:
  /// **'ממתין לשלבים קודמים'**
  String get stepLocked;

  /// No description provided for @stepReady.
  ///
  /// In he, this message translates to:
  /// **'מוכן להתחלה'**
  String get stepReady;

  /// No description provided for @stepInProgress.
  ///
  /// In he, this message translates to:
  /// **'בתהליך'**
  String get stepInProgress;

  /// No description provided for @stepWaiting.
  ///
  /// In he, this message translates to:
  /// **'ממתין לטיימר'**
  String get stepWaiting;

  /// No description provided for @stepDone.
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get stepDone;

  /// No description provided for @undoLastAction.
  ///
  /// In he, this message translates to:
  /// **'ביטול הפעולה האחרונה'**
  String get undoLastAction;

  /// No description provided for @actionDone.
  ///
  /// In he, this message translates to:
  /// **'✓ {label}'**
  String actionDone(String label);

  /// No description provided for @actionDoneWithTimer.
  ///
  /// In he, this message translates to:
  /// **'✓ {label} · טיימר {timer} הופעל ({duration})'**
  String actionDoneWithTimer(String label, String timer, String duration);

  /// No description provided for @actionAlreadyDone.
  ///
  /// In he, this message translates to:
  /// **'זה כבר סומן כבוצע'**
  String get actionAlreadyDone;

  /// No description provided for @actionNotAvailable.
  ///
  /// In he, this message translates to:
  /// **'אי אפשר לבצע את זה עכשיו'**
  String get actionNotAvailable;

  /// No description provided for @undoNotAllowed.
  ///
  /// In he, this message translates to:
  /// **'אי אפשר לבטל — כבר התחלתם שלב שתלוי בזה'**
  String get undoNotAllowed;

  /// No description provided for @timersTitle.
  ///
  /// In he, this message translates to:
  /// **'טיימרים'**
  String get timersTitle;

  /// No description provided for @timerFinished.
  ///
  /// In he, this message translates to:
  /// **'הזמן נגמר!'**
  String get timerFinished;

  /// No description provided for @pause.
  ///
  /// In he, this message translates to:
  /// **'השהיה'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In he, this message translates to:
  /// **'המשך'**
  String get resume;

  /// No description provided for @addMinute.
  ///
  /// In he, this message translates to:
  /// **'+ דקה'**
  String get addMinute;

  /// No description provided for @dismissTimer.
  ///
  /// In he, this message translates to:
  /// **'סגירת הטיימר'**
  String get dismissTimer;

  /// No description provided for @confirmActionTitle.
  ///
  /// In he, this message translates to:
  /// **'{label}?'**
  String confirmActionTitle(String label);

  /// No description provided for @confirmCheck.
  ///
  /// In he, this message translates to:
  /// **'לפני שממשיכים, בדקו:'**
  String get confirmCheck;

  /// No description provided for @confirmYes.
  ///
  /// In he, this message translates to:
  /// **'כן, {label}'**
  String confirmYes(String label);

  /// No description provided for @confirmNotYet.
  ///
  /// In he, this message translates to:
  /// **'עוד לא'**
  String get confirmNotYet;

  /// No description provided for @allStepsDone.
  ///
  /// In he, this message translates to:
  /// **'כל השלבים הושלמו! 🎉'**
  String get allStepsDone;

  /// No description provided for @goToFinish.
  ///
  /// In he, this message translates to:
  /// **'לסיום הבישול'**
  String get goToFinish;

  /// No description provided for @abandonCooking.
  ///
  /// In he, this message translates to:
  /// **'הפסקת הבישול'**
  String get abandonCooking;

  /// No description provided for @abandonConfirm.
  ///
  /// In he, this message translates to:
  /// **'להפסיק את הבישול? מה שעשיתם יישמר בהיסטוריה.'**
  String get abandonConfirm;

  /// No description provided for @abandonAction.
  ///
  /// In he, this message translates to:
  /// **'הפסקה'**
  String get abandonAction;

  /// No description provided for @sessionEnded.
  ///
  /// In he, this message translates to:
  /// **'הבישול הזה הסתיים'**
  String get sessionEnded;

  /// No description provided for @finishTitle.
  ///
  /// In he, this message translates to:
  /// **'סיום הבישול'**
  String get finishTitle;

  /// No description provided for @finishSummary.
  ///
  /// In he, this message translates to:
  /// **'סיימתם לבשל: {title}'**
  String finishSummary(String title);

  /// No description provided for @cookingTime.
  ///
  /// In he, this message translates to:
  /// **'זמן בישול: {duration}'**
  String cookingTime(String duration);

  /// No description provided for @minutesShort.
  ///
  /// In he, this message translates to:
  /// **'{minutes} דק\''**
  String minutesShort(int minutes);

  /// No description provided for @notesLabel.
  ///
  /// In he, this message translates to:
  /// **'הערות לפעם הבאה (לא חובה)'**
  String get notesLabel;

  /// No description provided for @saveAndFinish.
  ///
  /// In he, this message translates to:
  /// **'שמירה וסיום'**
  String get saveAndFinish;

  /// No description provided for @historyEmpty.
  ///
  /// In he, this message translates to:
  /// **'עוד לא בישלתם. בחרו מתכון מהרשימה והתחילו.'**
  String get historyEmpty;

  /// No description provided for @statusCompleted.
  ///
  /// In he, this message translates to:
  /// **'הושלם'**
  String get statusCompleted;

  /// No description provided for @statusAbandoned.
  ///
  /// In he, this message translates to:
  /// **'הופסק'**
  String get statusAbandoned;

  /// No description provided for @statusInProgress.
  ///
  /// In he, this message translates to:
  /// **'בתהליך'**
  String get statusInProgress;

  /// No description provided for @startedAt.
  ///
  /// In he, this message translates to:
  /// **'התחיל: {time}'**
  String startedAt(String time);

  /// No description provided for @endedAt.
  ///
  /// In he, this message translates to:
  /// **'הסתיים: {time}'**
  String endedAt(String time);

  /// No description provided for @notes.
  ///
  /// In he, this message translates to:
  /// **'הערות'**
  String get notes;

  /// No description provided for @actionsLog.
  ///
  /// In he, this message translates to:
  /// **'מה עשיתם'**
  String get actionsLog;

  /// No description provided for @approvedChanges.
  ///
  /// In he, this message translates to:
  /// **'שינויים שאושרו בתוכנית'**
  String get approvedChanges;

  /// No description provided for @noApprovedChanges.
  ///
  /// In he, this message translates to:
  /// **'לא בוצעו שינויים בתוכנית'**
  String get noApprovedChanges;

  /// No description provided for @cookAgain.
  ///
  /// In he, this message translates to:
  /// **'לבשל שוב'**
  String get cookAgain;

  /// No description provided for @settingsNotifications.
  ///
  /// In he, this message translates to:
  /// **'התראות טיימר'**
  String get settingsNotifications;

  /// No description provided for @notificationsOn.
  ///
  /// In he, this message translates to:
  /// **'ההתראות מאופשרות'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In he, this message translates to:
  /// **'ההתראות חסומות — טיימרים לא יתריעו'**
  String get notificationsOff;

  /// No description provided for @enableNotifications.
  ///
  /// In he, this message translates to:
  /// **'אפשר התראות'**
  String get enableNotifications;

  /// No description provided for @exactAlarmsOn.
  ///
  /// In he, this message translates to:
  /// **'תזמון מדויק מאופשר'**
  String get exactAlarmsOn;

  /// No description provided for @exactAlarmsOff.
  ///
  /// In he, this message translates to:
  /// **'תזמון מדויק כבוי — התראות עלולות להתעכב בכמה דקות'**
  String get exactAlarmsOff;

  /// No description provided for @enableExactAlarms.
  ///
  /// In he, this message translates to:
  /// **'אפשר תזמון מדויק'**
  String get enableExactAlarms;

  /// No description provided for @batteryTitle.
  ///
  /// In he, this message translates to:
  /// **'חיסכון בסוללה'**
  String get batteryTitle;

  /// No description provided for @batteryRestricted.
  ///
  /// In he, this message translates to:
  /// **'חיסכון בסוללה מגביל את האפליקציה. מומלץ לבטל את ההגבלה כדי שהטיימרים יתריעו בזמן.'**
  String get batteryRestricted;

  /// No description provided for @batteryOk.
  ///
  /// In he, this message translates to:
  /// **'חיסכון בסוללה לא מגביל את האפליקציה'**
  String get batteryOk;

  /// No description provided for @openBatterySettings.
  ///
  /// In he, this message translates to:
  /// **'פתיחת הגדרות הסוללה'**
  String get openBatterySettings;

  /// No description provided for @batteryVendorHint.
  ///
  /// In he, this message translates to:
  /// **'בטלפונים של שיאומי, סמסונג, וואווי ו-וואן פלוס יש לפעמים הגבלות נוספות. אם טיימר לא התריע, ודאו בהגדרות הסוללה של הטלפון שהאפליקציה מורשית לפעול ברקע.'**
  String get batteryVendorHint;

  /// No description provided for @testNotification.
  ///
  /// In he, this message translates to:
  /// **'שליחת התראת בדיקה (בעוד 10 שניות)'**
  String get testNotification;

  /// No description provided for @testNotificationScheduled.
  ///
  /// In he, this message translates to:
  /// **'התראת בדיקה תגיע בעוד 10 שניות'**
  String get testNotificationScheduled;

  /// No description provided for @serverAddress.
  ///
  /// In he, this message translates to:
  /// **'כתובת השרת (מצב פיתוח): {url}'**
  String serverAddress(String url);

  /// No description provided for @aboutTitle.
  ///
  /// In he, this message translates to:
  /// **'אודות'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In he, this message translates to:
  /// **'בזמן הבישול האפליקציה עובדת גם בלי אינטרנט: השלבים, הטיימרים וההתקדמות נשמרים במכשיר.'**
  String get aboutBody;

  /// No description provided for @refresh.
  ///
  /// In he, this message translates to:
  /// **'רענון'**
  String get refresh;
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
      <String>['he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
