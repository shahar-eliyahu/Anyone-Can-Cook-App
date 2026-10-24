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

  /// No description provided for @recheckIn.
  ///
  /// In he, this message translates to:
  /// **'עוד לא — לבדוק שוב בעוד {minutes} דק\''**
  String recheckIn(int minutes);

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
  /// **'קוראים את המתכון…'**
  String get importStageReading;

  /// No description provided for @importStagePlanning.
  ///
  /// In he, this message translates to:
  /// **'בונים תוכנית בישול…'**
  String get importStagePlanning;

  /// No description provided for @importStageSlow.
  ///
  /// In he, this message translates to:
  /// **'זה לוקח קצת זמן — ייתכן שהשרת מתעורר.'**
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
  /// **'כדי לנתח את המתכון, הטקסט, הקישור או התמונה נשלחים לשירות בינה מלאכותית (Gemini של Google). בגרסה החינמית של השירות Google עשויה להשתמש במידע לשיפור המוצרים שלה. אל תשלחו מידע אישי. התמונה נשמרת במכשיר רק עד שתאשרו את התוכנית.'**
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

  /// No description provided for @draftResume.
  ///
  /// In he, this message translates to:
  /// **'להמשיך'**
  String get draftResume;

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

  /// No description provided for @reviewSave.
  ///
  /// In he, this message translates to:
  /// **'שמירת השינויים'**
  String get reviewSave;

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

  /// No description provided for @provenanceInferred.
  ///
  /// In he, this message translates to:
  /// **'הערכה'**
  String get provenanceInferred;

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

  /// No description provided for @rangeMinutes.
  ///
  /// In he, this message translates to:
  /// **'{from}–{to} דק\''**
  String rangeMinutes(int from, int to);

  /// No description provided for @minutesValue.
  ///
  /// In he, this message translates to:
  /// **'{minutes} דק\''**
  String minutesValue(int minutes);

  /// No description provided for @errOffline.
  ///
  /// In he, this message translates to:
  /// **'אין חיבור לאינטרנט. ייבוא מתכון חדש דורש חיבור; בישול של מתכון שמור עובד גם בלי.'**
  String get errOffline;

  /// No description provided for @errTimeout.
  ///
  /// In he, this message translates to:
  /// **'השרת לא הגיב בזמן. נסו שוב בעוד רגע.'**
  String get errTimeout;

  /// No description provided for @errRateLimited.
  ///
  /// In he, this message translates to:
  /// **'הגעתם למגבלת הייבוא לשעה. נסו שוב מאוחר יותר.'**
  String get errRateLimited;

  /// No description provided for @errAiBusy.
  ///
  /// In he, this message translates to:
  /// **'ניתוח מתכונים עם בינה מלאכותית לא זמין כרגע בגלל עומס זמני. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
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
  /// **'השרת עדיין לא מוגדר לייבוא מתכונים.'**
  String get errNotConfigured;

  /// No description provided for @errGeneric.
  ///
  /// In he, this message translates to:
  /// **'משהו השתבש בייבוא. נסו שוב.'**
  String get errGeneric;

  /// No description provided for @errAiBusyRetryIn.
  ///
  /// In he, this message translates to:
  /// **'ניתוח מתכונים עם בינה מלאכותית לא זמין כרגע בגלל עומס זמני. אפשר לנסות שוב בעוד כ-{minutes} דק\'. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String errAiBusyRetryIn(int minutes);

  /// No description provided for @errAiQuota.
  ///
  /// In he, this message translates to:
  /// **'מכסת השימוש היומית בשירות הבינה המלאכותית נוצלה, ולכן ייבוא מתכונים חדשים לא זמין כרגע. נסו שוב מאוחר יותר. מה שהזנתם נשמר, והמתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
  String get errAiQuota;

  /// No description provided for @errAiUnavailable.
  ///
  /// In he, this message translates to:
  /// **'שירות הבינה המלאכותית לא זמין כרגע. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.'**
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
