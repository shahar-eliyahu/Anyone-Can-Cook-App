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

  /// No description provided for @retry.
  ///
  /// In he, this message translates to:
  /// **'נסו שוב'**
  String get retry;

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

  /// No description provided for @undoLastAction.
  ///
  /// In he, this message translates to:
  /// **'ביטול הפעולה האחרונה'**
  String get undoLastAction;

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

  /// No description provided for @timerCheckDue.
  ///
  /// In he, this message translates to:
  /// **'זמן לבדוק!'**
  String get timerCheckDue;

  /// No description provided for @checkAtLabel.
  ///
  /// In he, this message translates to:
  /// **'לבדוק בערך ב-{time}'**
  String checkAtLabel(String time);

  /// No description provided for @rangeUntil.
  ///
  /// In he, this message translates to:
  /// **'טווח הזמן: עד {time}'**
  String rangeUntil(String time);

  /// No description provided for @removeMinute.
  ///
  /// In he, this message translates to:
  /// **'− דקה'**
  String get removeMinute;

  /// No description provided for @nextStepPreview.
  ///
  /// In he, this message translates to:
  /// **'אחרי זה: {title}'**
  String nextStepPreview(String title);

  /// No description provided for @tomorrowAt.
  ///
  /// In he, this message translates to:
  /// **'מחר ב-{time}'**
  String tomorrowAt(String time);

  /// No description provided for @dateAt.
  ///
  /// In he, this message translates to:
  /// **'{date} ב-{time}'**
  String dateAt(String date, String time);

  /// No description provided for @notifCheckTitle.
  ///
  /// In he, this message translates to:
  /// **'⏰ {label}: זמן לבדוק'**
  String notifCheckTitle(String label);

  /// No description provided for @notifCheckBody.
  ///
  /// In he, this message translates to:
  /// **'בדקו: {cue}'**
  String notifCheckBody(String cue);

  /// No description provided for @notifCheckBodyDefault.
  ///
  /// In he, this message translates to:
  /// **'לבשל כל אחד יכול · לחצו כדי לחזור לבישול'**
  String get notifCheckBodyDefault;

  /// No description provided for @notifPreheatBody.
  ///
  /// In he, this message translates to:
  /// **'בדקו שהתנור הגיע לחום'**
  String get notifPreheatBody;

  /// No description provided for @notifRangeEndTitle.
  ///
  /// In he, this message translates to:
  /// **'⏰ {label}: סוף טווח הזמן'**
  String notifRangeEndTitle(String label);

  /// No description provided for @notifRangeEndBodyDefault.
  ///
  /// In he, this message translates to:
  /// **'זה הזמן לבדוק שוב'**
  String get notifRangeEndBodyDefault;

  /// No description provided for @notifPrepTitle.
  ///
  /// In he, this message translates to:
  /// **'⏳ {task}'**
  String notifPrepTitle(String task);

  /// No description provided for @notifPrepBody.
  ///
  /// In he, this message translates to:
  /// **'בעוד כ-{minutes} דקות תצטרכו את זה'**
  String notifPrepBody(int minutes);

  /// No description provided for @notifTestTitle.
  ///
  /// In he, this message translates to:
  /// **'⏰ התראת בדיקה'**
  String get notifTestTitle;

  /// No description provided for @notifTestBody.
  ///
  /// In he, this message translates to:
  /// **'לבשל כל אחד יכול · ההתראות של הטיימרים עובדות'**
  String get notifTestBody;

  /// No description provided for @channelTimersName.
  ///
  /// In he, this message translates to:
  /// **'טיימרים לבישול'**
  String get channelTimersName;

  /// No description provided for @channelTimersDescription.
  ///
  /// In he, this message translates to:
  /// **'התראה כשהגיע הזמן לבדוק משהו שמתבשל'**
  String get channelTimersDescription;

  /// No description provided for @channelPrepName.
  ///
  /// In he, this message translates to:
  /// **'תזכורות הכנה'**
  String get channelPrepName;

  /// No description provided for @channelPrepDescription.
  ///
  /// In he, this message translates to:
  /// **'תזכורות שקטות להכנות לקראת השלב הבא'**
  String get channelPrepDescription;

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
  /// **'בדיקת התראות (תגיע בעוד 10 שניות)'**
  String get testNotification;

  /// No description provided for @testNotificationScheduled.
  ///
  /// In he, this message translates to:
  /// **'התראת הבדיקה תגיע בעוד 10 שניות'**
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

  /// No description provided for @importTitle.
  ///
  /// In he, this message translates to:
  /// **'ייבוא מתכון'**
  String get importTitle;

  /// No description provided for @importTabText.
  ///
  /// In he, this message translates to:
  /// **'טקסט'**
  String get importTabText;

  /// No description provided for @importTabPhoto.
  ///
  /// In he, this message translates to:
  /// **'תמונה'**
  String get importTabPhoto;

  /// No description provided for @importTabUrl.
  ///
  /// In he, this message translates to:
  /// **'קישור'**
  String get importTabUrl;

  /// No description provided for @importTextHint.
  ///
  /// In he, this message translates to:
  /// **'הדביקו או הקלידו כאן את המתכון'**
  String get importTextHint;

  /// No description provided for @importUrlHint.
  ///
  /// In he, this message translates to:
  /// **'https://…'**
  String get importUrlHint;

  /// No description provided for @importTakePhoto.
  ///
  /// In he, this message translates to:
  /// **'צילום'**
  String get importTakePhoto;

  /// No description provided for @importPickPhoto.
  ///
  /// In he, this message translates to:
  /// **'מהגלריה'**
  String get importPickPhoto;

  /// No description provided for @importPhotoNote.
  ///
  /// In he, this message translates to:
  /// **'התמונה נשמרת רק עד שתאשרו את התוכנית.'**
  String get importPhotoNote;

  /// No description provided for @importAnalyze.
  ///
  /// In he, this message translates to:
  /// **'ניתוח המתכון'**
  String get importAnalyze;

  /// No description provided for @importStageReading.
  ///
  /// In he, this message translates to:
  /// **'בודקים את המצרכים וההוראות…'**
  String get importStageReading;

  /// No description provided for @importStagePlanning.
  ///
  /// In he, this message translates to:
  /// **'מסדרים לך את שלבי הבישול…'**
  String get importStagePlanning;

  /// No description provided for @importStageSlow.
  ///
  /// In he, this message translates to:
  /// **'זה לוקח קצת יותר זמן מהרגיל…'**
  String get importStageSlow;

  /// No description provided for @importDuplicateTitle.
  ///
  /// In he, this message translates to:
  /// **'המתכון כבר יובא'**
  String get importDuplicateTitle;

  /// No description provided for @importDuplicateBody.
  ///
  /// In he, this message translates to:
  /// **'כבר ייבאתם את המתכון הזה: {title}. לפתוח אותו במקום לייבא שוב?'**
  String importDuplicateBody(String title);

  /// No description provided for @importOpenExisting.
  ///
  /// In he, this message translates to:
  /// **'פתיחת הקיים'**
  String get importOpenExisting;

  /// No description provided for @importAgain.
  ///
  /// In he, this message translates to:
  /// **'ייבוא מחדש'**
  String get importAgain;

  /// No description provided for @importNotRecipe.
  ///
  /// In he, this message translates to:
  /// **'לא זיהינו כאן מתכון.'**
  String get importNotRecipe;

  /// No description provided for @privacyTitle.
  ///
  /// In he, this message translates to:
  /// **'לפני הייבוא הראשון'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In he, this message translates to:
  /// **'כדי להכין את המתכון, הטקסט, הקישור או התמונה נשלחים לשירות בינה מלאכותית של Google. בשירות החינמי Google עשויה להשתמש במידע לשיפור המוצרים שלה. אל תשלחו מידע אישי. התמונה נשמרת במכשיר רק עד שתאשרו את התוכנית.'**
  String get privacyBody;

  /// No description provided for @privacyAccept.
  ///
  /// In he, this message translates to:
  /// **'הבנתי, להמשיך'**
  String get privacyAccept;

  /// No description provided for @draftsTitle.
  ///
  /// In he, this message translates to:
  /// **'ייבואים שלא הושלמו'**
  String get draftsTitle;

  /// No description provided for @draftDiscard.
  ///
  /// In he, this message translates to:
  /// **'מחיקה'**
  String get draftDiscard;

  /// No description provided for @clarifyTitle.
  ///
  /// In he, this message translates to:
  /// **'כמה שאלות קצרות'**
  String get clarifyTitle;

  /// No description provided for @clarifyIntro.
  ///
  /// In he, this message translates to:
  /// **'חסר במתכון מידע שחשוב לתוכנית. ענו על מה שאתם יודעים.'**
  String get clarifyIntro;

  /// No description provided for @clarifyRequired.
  ///
  /// In he, this message translates to:
  /// **'חשוב לבטיחות'**
  String get clarifyRequired;

  /// No description provided for @clarifyDontKnow.
  ///
  /// In he, this message translates to:
  /// **'לא יודע/ת'**
  String get clarifyDontKnow;

  /// No description provided for @clarifyContinue.
  ///
  /// In he, this message translates to:
  /// **'בניית התוכנית'**
  String get clarifyContinue;

  /// No description provided for @clarifyAnswerHint.
  ///
  /// In he, this message translates to:
  /// **'התשובה שלכם'**
  String get clarifyAnswerHint;

  /// No description provided for @reviewTitle.
  ///
  /// In he, this message translates to:
  /// **'בדיקת התוכנית'**
  String get reviewTitle;

  /// No description provided for @reviewIntro.
  ///
  /// In he, this message translates to:
  /// **'בדקו את המצרכים, הזמנים והטמפרטורות. אפשר לתקן כל ערך לפני האישור.'**
  String get reviewIntro;

  /// No description provided for @reviewEstimatesTitle.
  ///
  /// In he, this message translates to:
  /// **'מה הוערך'**
  String get reviewEstimatesTitle;

  /// No description provided for @reviewNoEstimates.
  ///
  /// In he, this message translates to:
  /// **'כל הערכים מופיעים במתכון המקורי.'**
  String get reviewNoEstimates;

  /// No description provided for @reviewAssumptions.
  ///
  /// In he, this message translates to:
  /// **'הנחות'**
  String get reviewAssumptions;

  /// No description provided for @reviewLimitations.
  ///
  /// In he, this message translates to:
  /// **'מה לא הצלחנו לקבוע בבטחה'**
  String get reviewLimitations;

  /// No description provided for @reviewWarnings.
  ///
  /// In he, this message translates to:
  /// **'שימו לב'**
  String get reviewWarnings;

  /// No description provided for @reviewSources.
  ///
  /// In he, this message translates to:
  /// **'מקורות'**
  String get reviewSources;

  /// No description provided for @reviewOriginalSource.
  ///
  /// In he, this message translates to:
  /// **'המתכון המקורי'**
  String get reviewOriginalSource;

  /// No description provided for @reviewFromSource.
  ///
  /// In he, this message translates to:
  /// **'מהמתכון המקורי: {text}'**
  String reviewFromSource(String text);

  /// No description provided for @reviewPhotoCheck.
  ///
  /// In he, this message translates to:
  /// **'התוכנית נבנתה מתמונה — בדקו שהכמויות והזמנים נקראו נכון.'**
  String get reviewPhotoCheck;

  /// No description provided for @reviewSafetyCheckbox.
  ///
  /// In he, this message translates to:
  /// **'בדקתי את הערכים המסומנים'**
  String get reviewSafetyCheckbox;

  /// No description provided for @reviewApprove.
  ///
  /// In he, this message translates to:
  /// **'אישור התוכנית'**
  String get reviewApprove;

  /// No description provided for @reviewCancelImport.
  ///
  /// In he, this message translates to:
  /// **'ביטול הייבוא'**
  String get reviewCancelImport;

  /// No description provided for @reviewOutdatedTitle.
  ///
  /// In he, this message translates to:
  /// **'התוכנית לא מעודכנת לשינויים במתכון'**
  String get reviewOutdatedTitle;

  /// No description provided for @reviewOutdatedBody.
  ///
  /// In he, this message translates to:
  /// **'שיניתם מצרכים או הוראות. צרו את התוכנית מחדש, או אשרו שבדקתם שהיא עדיין נכונה.'**
  String get reviewOutdatedBody;

  /// No description provided for @reviewRegenerate.
  ///
  /// In he, this message translates to:
  /// **'יצירת התוכנית מחדש'**
  String get reviewRegenerate;

  /// No description provided for @reviewStillCorrect.
  ///
  /// In he, this message translates to:
  /// **'בדקתי — התוכנית נכונה'**
  String get reviewStillCorrect;

  /// No description provided for @provenanceAnswered.
  ///
  /// In he, this message translates to:
  /// **'לפי תשובתך'**
  String get provenanceAnswered;

  /// No description provided for @provenanceReference.
  ///
  /// In he, this message translates to:
  /// **'לפי מקור בטיחות מזון'**
  String get provenanceReference;

  /// No description provided for @provenanceUser.
  ///
  /// In he, this message translates to:
  /// **'ערך שלך'**
  String get provenanceUser;

  /// No description provided for @editIngredient.
  ///
  /// In he, this message translates to:
  /// **'עריכת מצרך'**
  String get editIngredient;

  /// No description provided for @editName.
  ///
  /// In he, this message translates to:
  /// **'שם'**
  String get editName;

  /// No description provided for @editAmount.
  ///
  /// In he, this message translates to:
  /// **'כמות (כפי שתוצג)'**
  String get editAmount;

  /// No description provided for @editStep.
  ///
  /// In he, this message translates to:
  /// **'עריכת הוראה'**
  String get editStep;

  /// No description provided for @editTimer.
  ///
  /// In he, this message translates to:
  /// **'עריכת זמן'**
  String get editTimer;

  /// No description provided for @editTimerMinutes.
  ///
  /// In he, this message translates to:
  /// **'לבדוק אחרי (דקות)'**
  String get editTimerMinutes;

  /// No description provided for @editTimerMaxMinutes.
  ///
  /// In he, this message translates to:
  /// **'סוף הטווח (דקות, לא חובה)'**
  String get editTimerMaxMinutes;

  /// No description provided for @editTemperature.
  ///
  /// In he, this message translates to:
  /// **'עריכת טמפרטורה (°C)'**
  String get editTemperature;

  /// No description provided for @editRecipe.
  ///
  /// In he, this message translates to:
  /// **'עריכת המתכון והתוכנית'**
  String get editRecipe;

  /// No description provided for @recipeOutdatedBanner.
  ///
  /// In he, this message translates to:
  /// **'התוכנית לא מעודכנת לשינויים במתכון. ערכו אותה או צרו אותה מחדש לפני הבישול.'**
  String get recipeOutdatedBanner;

  /// No description provided for @errOffline.
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לאינטרנט. ייבוא מתכון חדש דורש חיבור; בישול של מתכון שמור עובד גם בלי.'**
  String get errOffline;

  /// No description provided for @errTimeout.
  ///
  /// In he, this message translates to:
  /// **'זה לקח יותר מדי זמן. נסו שוב בעוד רגע.'**
  String get errTimeout;

  /// No description provided for @errRateLimited.
  ///
  /// In he, this message translates to:
  /// **'הגעתם למגבלת הייבוא לשעה. נסו שוב מאוחר יותר.'**
  String get errRateLimited;

  /// No description provided for @errAiBusy.
  ///
  /// In he, this message translates to:
  /// **'הכנת מתכונים חדשים לא זמינה כרגע בגלל עומס זמני. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String get errAiBusy;

  /// No description provided for @errDailyLimit.
  ///
  /// In he, this message translates to:
  /// **'הגענו למגבלת הייבוא היומית של האפליקציה. נסו שוב מחר. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String get errDailyLimit;

  /// No description provided for @errTooLarge.
  ///
  /// In he, this message translates to:
  /// **'התוכן גדול מדי. נסו מתכון קצר יותר או תמונה קטנה יותר.'**
  String get errTooLarge;

  /// No description provided for @errUnsupportedImage.
  ///
  /// In he, this message translates to:
  /// **'סוג התמונה לא נתמך. נסו תמונת JPEG או PNG.'**
  String get errUnsupportedImage;

  /// No description provided for @errInvalidUrl.
  ///
  /// In he, this message translates to:
  /// **'הקישור לא תקין או לא נתמך.'**
  String get errInvalidUrl;

  /// No description provided for @errFetchFailed.
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו לפתוח את הדף. נסו להדביק את טקסט המתכון במקום.'**
  String get errFetchFailed;

  /// No description provided for @errSiteBlocked.
  ///
  /// In he, this message translates to:
  /// **'האתר לא מאפשר לקרוא את הדף. העתיקו את טקסט המתכון והדביקו אותו בלשונית \"טקסט\".'**
  String get errSiteBlocked;

  /// No description provided for @errNoRecipeFound.
  ///
  /// In he, this message translates to:
  /// **'לא מצאנו מתכון בדף. נסו להדביק את טקסט המתכון במקום.'**
  String get errNoRecipeFound;

  /// No description provided for @errUnsafeToPlan.
  ///
  /// In he, this message translates to:
  /// **'המתכון כולל שימורים ביתיים, שדורשים מתכון בדוק ומאומת. לא נבנה עבורם תוכנית על סמך הערכה.'**
  String get errUnsafeToPlan;

  /// No description provided for @errInvalidAiOutput.
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו לבנות תוכנית אמינה מהמתכון הזה. נסו שוב, או נסחו את המתכון בבירור.'**
  String get errInvalidAiOutput;

  /// No description provided for @errNotConfigured.
  ///
  /// In he, this message translates to:
  /// **'ייבוא מתכונים לא זמין כרגע. נסו שוב מאוחר יותר.'**
  String get errNotConfigured;

  /// No description provided for @errGeneric.
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש בייבוא. נסו שוב.'**
  String get errGeneric;

  /// No description provided for @errAiBusyRetryIn.
  ///
  /// In he, this message translates to:
  /// **'הכנת מתכונים חדשים לא זמינה כרגע בגלל עומס זמני. אפשר לנסות שוב בעוד כ-{minutes} דק\'. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String errAiBusyRetryIn(int minutes);

  /// No description provided for @errAiQuota.
  ///
  /// In he, this message translates to:
  /// **'הכנת מתכונים חדשים לא זמינה כרגע, כי הגענו למכסת השימוש היומית. נסו שוב מאוחר יותר. מה שהזנתם נשמר, והמתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String get errAiQuota;

  /// No description provided for @errAiUnavailable.
  ///
  /// In he, this message translates to:
  /// **'הכנת מתכונים חדשים לא זמינה כרגע. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String get errAiUnavailable;

  /// No description provided for @importRetry.
  ///
  /// In he, this message translates to:
  /// **'נסו שוב'**
  String get importRetry;

  /// No description provided for @importRestored.
  ///
  /// In he, this message translates to:
  /// **'שחזרנו את מה שהזנתם בניסיון הקודם.'**
  String get importRestored;

  /// No description provided for @importPlanFailedNote.
  ///
  /// In he, this message translates to:
  /// **'המתכון נקרא ונשמר. אפשר לנסות שוב לבנות את התוכנית בלי לקרוא אותו מחדש.'**
  String get importPlanFailedNote;

  /// No description provided for @stepPrimaryNext.
  ///
  /// In he, this message translates to:
  /// **'סיימתי — לשלב הבא'**
  String get stepPrimaryNext;

  /// No description provided for @stepPrimaryLast.
  ///
  /// In he, this message translates to:
  /// **'סיימתי'**
  String get stepPrimaryLast;

  /// No description provided for @stepPrimaryReady.
  ///
  /// In he, this message translates to:
  /// **'מוכן — לשלב הבא'**
  String get stepPrimaryReady;

  /// No description provided for @stepPrimaryReadyLast.
  ///
  /// In he, this message translates to:
  /// **'מוכן'**
  String get stepPrimaryReadyLast;

  /// No description provided for @stepNeedMoreTime.
  ///
  /// In he, this message translates to:
  /// **'צריך עוד זמן (+{minutes} דק\')'**
  String stepNeedMoreTime(int minutes);

  /// No description provided for @stepReadyEarly.
  ///
  /// In he, this message translates to:
  /// **'כבר מוכן? לשלב הבא'**
  String get stepReadyEarly;

  /// No description provided for @stepStartsTimer.
  ///
  /// In he, this message translates to:
  /// **'כשתלחצו, יתחיל טיימר של {duration}'**
  String stepStartsTimer(String duration);

  /// No description provided for @stepHelp.
  ///
  /// In he, this message translates to:
  /// **'עזרה בשלב הזה'**
  String get stepHelp;

  /// No description provided for @stepHideHelp.
  ///
  /// In he, this message translates to:
  /// **'הסתרת העזרה'**
  String get stepHideHelp;

  /// No description provided for @safetyCheckLabel.
  ///
  /// In he, this message translates to:
  /// **'בדקתי: {cue}'**
  String safetyCheckLabel(String cue);

  /// No description provided for @safetyCheckGeneric.
  ///
  /// In he, this message translates to:
  /// **'בדקתי שהמנה מוכנה'**
  String get safetyCheckGeneric;

  /// No description provided for @backButton.
  ///
  /// In he, this message translates to:
  /// **'חזרה'**
  String get backButton;

  /// No description provided for @timerOptions.
  ///
  /// In he, this message translates to:
  /// **'אפשרויות טיימר'**
  String get timerOptions;

  /// No description provided for @stepsCompletedTitle.
  ///
  /// In he, this message translates to:
  /// **'השלבים'**
  String get stepsCompletedTitle;

  /// No description provided for @stepNotDone.
  ///
  /// In he, this message translates to:
  /// **'לא הושלם'**
  String get stepNotDone;

  /// No description provided for @durationUnderMinute.
  ///
  /// In he, this message translates to:
  /// **'פחות מדקה'**
  String get durationUnderMinute;

  /// No description provided for @loadingShort.
  ///
  /// In he, this message translates to:
  /// **'…'**
  String get loadingShort;

  /// No description provided for @durationMinutes.
  ///
  /// In he, this message translates to:
  /// **'כ-{minutes} דק\''**
  String durationMinutes(int minutes);

  /// No description provided for @durationHour.
  ///
  /// In he, this message translates to:
  /// **'כשעה'**
  String get durationHour;

  /// No description provided for @durationHourMinutes.
  ///
  /// In he, this message translates to:
  /// **'כשעה ו-{minutes} דק\''**
  String durationHourMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In he, this message translates to:
  /// **'כ-{hours} שעות'**
  String durationHours(String hours);

  /// No description provided for @overviewTotalTime.
  ///
  /// In he, this message translates to:
  /// **'זמן כולל: {time}'**
  String overviewTotalTime(String time);

  /// No description provided for @overviewActiveTime.
  ///
  /// In he, this message translates to:
  /// **'עבודה בפועל: {time}'**
  String overviewActiveTime(String time);

  /// No description provided for @overviewChecklistIntro.
  ///
  /// In he, this message translates to:
  /// **'סמנו מה יש לכם. אם משהו חסר, נמצא יחד פתרון.'**
  String get overviewChecklistIntro;

  /// No description provided for @haveIt.
  ///
  /// In he, this message translates to:
  /// **'יש לי'**
  String get haveIt;

  /// No description provided for @missingIt.
  ///
  /// In he, this message translates to:
  /// **'חסר לי'**
  String get missingIt;

  /// No description provided for @haveAll.
  ///
  /// In he, this message translates to:
  /// **'יש לי הכול'**
  String get haveAll;

  /// No description provided for @findSolution.
  ///
  /// In he, this message translates to:
  /// **'פתרון'**
  String get findSolution;

  /// No description provided for @stillMissing.
  ///
  /// In he, this message translates to:
  /// **'עוד חסר: {items}'**
  String stillMissing(String items);

  /// No description provided for @insteadOf.
  ///
  /// In he, this message translates to:
  /// **'במקום {name}'**
  String insteadOf(String name);

  /// No description provided for @notUsed.
  ///
  /// In he, this message translates to:
  /// **'לא בשימוש'**
  String get notUsed;

  /// No description provided for @optionalItem.
  ///
  /// In he, this message translates to:
  /// **'לא חובה'**
  String get optionalItem;

  /// No description provided for @undoSubstitution.
  ///
  /// In he, this message translates to:
  /// **'ביטול ההחלפה'**
  String get undoSubstitution;

  /// No description provided for @startCookingCta.
  ///
  /// In he, this message translates to:
  /// **'מתחילים לבשל'**
  String get startCookingCta;

  /// No description provided for @saveToMyRecipes.
  ///
  /// In he, this message translates to:
  /// **'שמירה במתכונים שלי'**
  String get saveToMyRecipes;

  /// No description provided for @advancedEdit.
  ///
  /// In he, this message translates to:
  /// **'עריכה מתקדמת'**
  String get advancedEdit;

  /// No description provided for @attentionTitle.
  ///
  /// In he, this message translates to:
  /// **'שימו לב'**
  String get attentionTitle;

  /// No description provided for @attentionAck.
  ///
  /// In he, this message translates to:
  /// **'קראתי'**
  String get attentionAck;

  /// No description provided for @attentionPhoto.
  ///
  /// In he, this message translates to:
  /// **'המתכון נקרא מתמונה — כדאי לוודא שהכמויות נכונות.'**
  String get attentionPhoto;

  /// No description provided for @planOutdated.
  ///
  /// In he, this message translates to:
  /// **'התוכנית לא מעודכנת לשינויים שעשיתם. אפשר לטפל בזה בעריכה המתקדמת.'**
  String get planOutdated;

  /// No description provided for @cookingNowLocked.
  ///
  /// In he, this message translates to:
  /// **'המתכון בבישול עכשיו. אפשר לשנות אותו אחרי שתסיימו.'**
  String get cookingNowLocked;

  /// No description provided for @sheetTitle.
  ///
  /// In he, this message translates to:
  /// **'אין לכם {name}?'**
  String sheetTitle(String name);

  /// No description provided for @sheetNoteHint.
  ///
  /// In he, this message translates to:
  /// **'מה יש לכם במקום? (לא חובה)'**
  String get sheetNoteHint;

  /// No description provided for @sheetFind.
  ///
  /// In he, this message translates to:
  /// **'חפשו לי פתרון'**
  String get sheetFind;

  /// No description provided for @sheetSearching.
  ///
  /// In he, this message translates to:
  /// **'מחפשים פתרון…'**
  String get sheetSearching;

  /// No description provided for @sheetTryOther.
  ///
  /// In he, this message translates to:
  /// **'לחפש פתרון אחר'**
  String get sheetTryOther;

  /// No description provided for @verdictWorks.
  ///
  /// In he, this message translates to:
  /// **'אפשר להחליף'**
  String get verdictWorks;

  /// No description provided for @verdictChanges.
  ///
  /// In he, this message translates to:
  /// **'אפשר, והתוצאה תהיה מעט שונה'**
  String get verdictChanges;

  /// No description provided for @verdictNotRecommended.
  ///
  /// In he, this message translates to:
  /// **'לא מומלץ'**
  String get verdictNotRecommended;

  /// No description provided for @verdictNone.
  ///
  /// In he, this message translates to:
  /// **'אין לזה תחליף טוב'**
  String get verdictNone;

  /// No description provided for @useThis.
  ///
  /// In he, this message translates to:
  /// **'להשתמש בזה'**
  String get useThis;

  /// No description provided for @noThanks.
  ///
  /// In he, this message translates to:
  /// **'לא תודה'**
  String get noThanks;

  /// No description provided for @understood.
  ///
  /// In he, this message translates to:
  /// **'הבנתי'**
  String get understood;

  /// No description provided for @substitutionFailed.
  ///
  /// In he, this message translates to:
  /// **'לא הצלחנו להחיל את הפתרון. אפשר לנסות שוב, או לשנות ידנית בעריכה המתקדמת.'**
  String get substitutionFailed;

  /// No description provided for @draftCancel.
  ///
  /// In he, this message translates to:
  /// **'ביטול הייבוא'**
  String get draftCancel;

  /// No description provided for @fullPlan.
  ///
  /// In he, this message translates to:
  /// **'כל שלבי הבישול'**
  String get fullPlan;

  /// No description provided for @attentionSafetyEstimate.
  ///
  /// In he, this message translates to:
  /// **'זמן הבישול בשלב \"{title}\" הוא הערכה — בדקו מוכנות לפי הסימנים בשלב.'**
  String attentionSafetyEstimate(String title);

  /// No description provided for @remyTitle.
  ///
  /// In he, this message translates to:
  /// **'רמי — עוזר הבישול'**
  String get remyTitle;

  /// No description provided for @remyOpen.
  ///
  /// In he, this message translates to:
  /// **'רמי'**
  String get remyOpen;

  /// No description provided for @remyHint.
  ///
  /// In he, this message translates to:
  /// **'שאלו את רמי או כתבו פקודה'**
  String get remyHint;

  /// No description provided for @remyGreeting.
  ///
  /// In he, this message translates to:
  /// **'היי, אני רמי! אפשר לשאול אותי על הבישול, או לבקש: \"הבא\", \"חזרה\", \"כמה זמן נשאר?\", \"תוסיף 5 דקות\".'**
  String get remyGreeting;

  /// No description provided for @remyChipNow.
  ///
  /// In he, this message translates to:
  /// **'מה עכשיו?'**
  String get remyChipNow;

  /// No description provided for @remyChipTime.
  ///
  /// In he, this message translates to:
  /// **'כמה זמן נשאר?'**
  String get remyChipTime;

  /// No description provided for @remyChipHelp.
  ///
  /// In he, this message translates to:
  /// **'עזרה בשלב'**
  String get remyChipHelp;

  /// No description provided for @remySend.
  ///
  /// In he, this message translates to:
  /// **'שליחה'**
  String get remySend;

  /// No description provided for @remyApprove.
  ///
  /// In he, this message translates to:
  /// **'אישור'**
  String get remyApprove;

  /// No description provided for @remyReject.
  ///
  /// In he, this message translates to:
  /// **'לא, תודה'**
  String get remyReject;

  /// No description provided for @remyRejected.
  ///
  /// In he, this message translates to:
  /// **'בסדר, לא שיניתי כלום.'**
  String get remyRejected;

  /// No description provided for @remyThinking.
  ///
  /// In he, this message translates to:
  /// **'רמי חושב…'**
  String get remyThinking;

  /// No description provided for @remyProposalTitle.
  ///
  /// In he, this message translates to:
  /// **'הצעה של רמי'**
  String get remyProposalTitle;

  /// No description provided for @remyAllDone.
  ///
  /// In he, this message translates to:
  /// **'כל השלבים הושלמו! אפשר לסיים את הבישול.'**
  String get remyAllDone;

  /// No description provided for @remyStartFirst.
  ///
  /// In he, this message translates to:
  /// **'קודם צריך: \"{label}\". זה כבר קרה?'**
  String remyStartFirst(String label);

  /// No description provided for @remyFinishEarly.
  ///
  /// In he, this message translates to:
  /// **'הטיימר \"{label}\" עוד רץ (נשארו {time}). לסיים את השלב כבר עכשיו?'**
  String remyFinishEarly(String label, String time);

  /// No description provided for @remySafetyCheck.
  ///
  /// In he, this message translates to:
  /// **'לפני שממשיכים: {cue} בדקתם?'**
  String remySafetyCheck(String cue);

  /// No description provided for @remyConfirmAction.
  ///
  /// In he, this message translates to:
  /// **'לסמן \"{label}\"?'**
  String remyConfirmAction(String label);

  /// No description provided for @remyConfirmActionTimer.
  ///
  /// In he, this message translates to:
  /// **'לסמן \"{label}\" ולהפעיל טיימר של {time}?'**
  String remyConfirmActionTimer(String label, String time);

  /// No description provided for @remyConfirmExtend.
  ///
  /// In he, this message translates to:
  /// **'להוסיף {time} לטיימר \"{label}\"?'**
  String remyConfirmExtend(String time, String label);

  /// No description provided for @remyNothingToUndo.
  ///
  /// In he, this message translates to:
  /// **'אין עדיין מה לבטל.'**
  String get remyNothingToUndo;

  /// No description provided for @remyNoTimers.
  ///
  /// In he, this message translates to:
  /// **'אין טיימר פעיל כרגע.'**
  String get remyNoTimers;

  /// No description provided for @remyTimerLeft.
  ///
  /// In he, this message translates to:
  /// **'{label}: נשארו {time}.'**
  String remyTimerLeft(String label, String time);

  /// No description provided for @remyTimerDue.
  ///
  /// In he, this message translates to:
  /// **'{label}: הגיע הזמן לבדוק.'**
  String remyTimerDue(String label);

  /// No description provided for @remyTimerPausedLeft.
  ///
  /// In he, this message translates to:
  /// **'{label}: מושהה, נשארו {time}.'**
  String remyTimerPausedLeft(String label, String time);

  /// No description provided for @remyWhichTimer.
  ///
  /// In he, this message translates to:
  /// **'לאיזה טיימר? {labels}'**
  String remyWhichTimer(String labels);

  /// No description provided for @remyTooLong.
  ///
  /// In he, this message translates to:
  /// **'אפשר להוסיף עד שעה בכל פעם.'**
  String get remyTooLong;

  /// No description provided for @remyNow.
  ///
  /// In he, this message translates to:
  /// **'עכשיו: {title}. {instruction}'**
  String remyNow(String title, String instruction);

  /// No description provided for @remyTellMeWhen.
  ///
  /// In he, this message translates to:
  /// **'כשזה קורה, תגידו לי \"{label}\" ואפעיל את הטיימר.'**
  String remyTellMeWhen(String label);

  /// No description provided for @remyTellMeWhenGeneric.
  ///
  /// In he, this message translates to:
  /// **'כשזה קורה, תגידו לי ואסמן את זה.'**
  String get remyTellMeWhenGeneric;

  /// No description provided for @remyStepDone.
  ///
  /// In he, this message translates to:
  /// **'✓ סיימנו: {title}.'**
  String remyStepDone(String title);

  /// No description provided for @remyNextStep.
  ///
  /// In he, this message translates to:
  /// **'עכשיו: {title}.'**
  String remyNextStep(String title);

  /// No description provided for @remyTimerStarted.
  ///
  /// In he, this message translates to:
  /// **'⏱ הטיימר \"{label}\" התחיל — לבדוק בעוד {time}.'**
  String remyTimerStarted(String label, String time);

  /// No description provided for @remyMarked.
  ///
  /// In he, this message translates to:
  /// **'✓ סומן: {label}.'**
  String remyMarked(String label);

  /// No description provided for @remyUndone.
  ///
  /// In he, this message translates to:
  /// **'↩ חזרנו צעד אחד אחורה.'**
  String get remyUndone;

  /// No description provided for @remyExtended.
  ///
  /// In he, this message translates to:
  /// **'⏱ הוספתי {added} לטיימר \"{label}\". נשארו {left}.'**
  String remyExtended(String added, String label, String left);

  /// No description provided for @remyPausedDone.
  ///
  /// In he, this message translates to:
  /// **'⏸ הטיימר \"{label}\" הושהה.'**
  String remyPausedDone(String label);

  /// No description provided for @remyResumedDone.
  ///
  /// In he, this message translates to:
  /// **'▶ הטיימר \"{label}\" ממשיך.'**
  String remyResumedDone(String label);

  /// No description provided for @remyPatched.
  ///
  /// In he, this message translates to:
  /// **'✓ עדכנתי את השלבים הבאים: {summary}.'**
  String remyPatched(String summary);

  /// No description provided for @remyAlreadyDone.
  ///
  /// In he, this message translates to:
  /// **'זה כבר בוצע.'**
  String get remyAlreadyDone;

  /// No description provided for @remyNotPossible.
  ///
  /// In he, this message translates to:
  /// **'אי אפשר לעשות את זה עכשיו.'**
  String get remyNotPossible;

  /// No description provided for @remyChangeNotPossible.
  ///
  /// In he, this message translates to:
  /// **'את השינוי הזה כבר אי אפשר לעשות, כי השלב כבר התחיל.'**
  String get remyChangeNotPossible;

  /// No description provided for @remyOffline.
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לאינטרנט, אז אני לא יכול לענות על שאלות כרגע. פקודות כמו \"הבא\", \"חזרה\" ו\"כמה זמן נשאר?\" עובדות גם בלי אינטרנט.'**
  String get remyOffline;

  /// No description provided for @remyUnavailable.
  ///
  /// In he, this message translates to:
  /// **'אני לא זמין לשאלות כרגע. הבישול ממשיך כרגיל, ופקודות פשוטות עובדות.'**
  String get remyUnavailable;

  /// No description provided for @durHour.
  ///
  /// In he, this message translates to:
  /// **'שעה'**
  String get durHour;

  /// No description provided for @durHours.
  ///
  /// In he, this message translates to:
  /// **'{n} שעות'**
  String durHours(int n);

  /// No description provided for @durMinute.
  ///
  /// In he, this message translates to:
  /// **'דקה'**
  String get durMinute;

  /// No description provided for @durMinutes.
  ///
  /// In he, this message translates to:
  /// **'{n} דקות'**
  String durMinutes(int n);

  /// No description provided for @durSeconds.
  ///
  /// In he, this message translates to:
  /// **'{n} שניות'**
  String durSeconds(int n);

  /// No description provided for @durAnd.
  ///
  /// In he, this message translates to:
  /// **'{a} ו-{b}'**
  String durAnd(String a, String b);

  /// No description provided for @changesDuringCooking.
  ///
  /// In he, this message translates to:
  /// **'שינויים בזמן הבישול'**
  String get changesDuringCooking;

  /// No description provided for @remyNextPreview.
  ///
  /// In he, this message translates to:
  /// **'אחרי זה: {title}.'**
  String remyNextPreview(String title);

  /// No description provided for @remyLastStep.
  ///
  /// In he, this message translates to:
  /// **'זה השלב האחרון.'**
  String get remyLastStep;

  /// No description provided for @remyIngredientAmount.
  ///
  /// In he, this message translates to:
  /// **'{name}: {amount}.'**
  String remyIngredientAmount(String name, String amount);

  /// No description provided for @remyTemperature.
  ///
  /// In he, this message translates to:
  /// **'{title}: {value}°.'**
  String remyTemperature(String title, int value);

  /// No description provided for @remyNoTemperature.
  ///
  /// In he, this message translates to:
  /// **'בשלב הזה אין טמפרטורה מוגדרת.'**
  String get remyNoTemperature;

  /// No description provided for @remyStepIngredients.
  ///
  /// In he, this message translates to:
  /// **'בשלב הזה: {items}.'**
  String remyStepIngredients(String items);

  /// No description provided for @remyNoStepIngredients.
  ///
  /// In he, this message translates to:
  /// **'אין מצרכים מיוחדים בשלב הזה.'**
  String get remyNoStepIngredients;

  /// No description provided for @remyStepsLeft.
  ///
  /// In he, this message translates to:
  /// **'נשארו {left} שלבים מתוך {total}.'**
  String remyStepsLeft(int left, int total);

  /// No description provided for @remyDidntCatch.
  ///
  /// In he, this message translates to:
  /// **'לא הבנתי, אפשר לנסח שוב?'**
  String get remyDidntCatch;

  /// No description provided for @remyConfirmUndo.
  ///
  /// In he, this message translates to:
  /// **'לבטל את הפעולה האחרונה?'**
  String get remyConfirmUndo;

  /// No description provided for @remyConfirmPause.
  ///
  /// In he, this message translates to:
  /// **'להשהות את הטיימר \"{label}\"?'**
  String remyConfirmPause(String label);

  /// No description provided for @remyConfirmResume.
  ///
  /// In he, this message translates to:
  /// **'להמשיך את הטיימר \"{label}\"?'**
  String remyConfirmResume(String label);

  /// No description provided for @remyConfirmNext.
  ///
  /// In he, this message translates to:
  /// **'לסיים את \"{title}\" ולעבור לשלב הבא?'**
  String remyConfirmNext(String title);
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
