// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'לבשל כל אחד יכול';

  @override
  String get kitchenTitle => 'המטבח שלי';

  @override
  String get continueCooking => 'המשך בישול';

  @override
  String get myRecipes => 'המתכונים שלי';

  @override
  String get favorites => 'מועדפים';

  @override
  String get cookingHistory => 'היסטוריית בישול';

  @override
  String get settings => 'הגדרות';

  @override
  String get newRecipe => 'מתכון חדש';

  @override
  String get noActiveSession => 'אין בישול פעיל כרגע';

  @override
  String get retry => 'נסו שוב';

  @override
  String get errorGeneric => 'משהו השתבש. נסו שוב.';

  @override
  String get allRecipes => 'הכל';

  @override
  String get searchRecipes => 'חיפוש מתכון';

  @override
  String get noRecipes => 'אין מתכונים עדיין';

  @override
  String get noFavorites => 'עוד לא סימנתם מתכונים כמועדפים';

  @override
  String get sampleRecipeLabel => 'מתכון לדוגמה';

  @override
  String get recipeNotFound => 'המתכון לא נמצא';

  @override
  String get ingredients => 'מצרכים';

  @override
  String get equipment => 'ציוד';

  @override
  String get viewPlan => 'תוכנית הבישול';

  @override
  String get startCooking => 'התחל בישול';

  @override
  String get addFavorite => 'הוספה למועדפים';

  @override
  String get removeFavorite => 'הסרה מהמועדפים';

  @override
  String get rename => 'שינוי שם';

  @override
  String get renameTitle => 'שם חדש למתכון';

  @override
  String get save => 'שמירה';

  @override
  String get cancel => 'ביטול';

  @override
  String get viewSource => 'המתכון המקורי';

  @override
  String get deleteRecipe => 'מחיקת המתכון';

  @override
  String get deleteRecipeConfirm =>
      'למחוק את המתכון? גם היסטוריית הבישול שלו תימחק.';

  @override
  String get delete => 'מחיקה';

  @override
  String get recipeDeleted => 'המתכון נמחק';

  @override
  String get undo => 'בטל';

  @override
  String get cannotDeleteActive =>
      'אי אפשר למחוק מתכון בזמן בישול. סיימו או הפסיקו את הבישול קודם.';

  @override
  String get estimate => 'הערכה';

  @override
  String get estimateHint => 'ערך משוער. המתכון המקורי לא ציין אותו.';

  @override
  String get prepTasks => 'הכנות מראש';

  @override
  String get steps => 'שלבים';

  @override
  String stepNumber(int number) {
    return 'שלב $number';
  }

  @override
  String afterSteps(String steps) {
    return 'אחרי: $steps';
  }

  @override
  String get canRunInParallel => 'אפשר במקביל לשלבים אחרים';

  @override
  String timerLabel(String label, String duration) {
    return 'טיימר: $label ($duration)';
  }

  @override
  String temperatureLabel(int value) {
    return 'טמפרטורה: $value מעלות';
  }

  @override
  String leadTime(int minutes) {
    return 'כ-$minutes דקות לפני שצריך';
  }

  @override
  String get noPlan => 'אין תוכנית בישול למתכון הזה';

  @override
  String get activeSessionTitle => 'כבר יש בישול פעיל';

  @override
  String activeSessionBody(String title) {
    return 'כרגע מתבשל: $title. אפשר להמשיך אותו, או להפסיק אותו ולהתחיל מחדש.';
  }

  @override
  String get goToActive => 'המשך לבישול הפעיל';

  @override
  String get exactAlarmPromptTitle => 'טיימרים שמתריעים בזמן';

  @override
  String get exactAlarmPromptBody =>
      'כדי שהטיימרים יתריעו בדיוק בזמן, צריך לאשר לאפליקציה \"התראות ותזכורות\" בהגדרות הטלפון. בלי האישור, התראה עלולה להתעכב בכמה דקות.';

  @override
  String get allowInSettings => 'אישור בהגדרות';

  @override
  String get continueWithout => 'להמשיך בלי';

  @override
  String get abandonAndStart => 'הפסק והתחל חדש';

  @override
  String cookingProgress(int done, int total) {
    return '$done מתוך $total שלבים הושלמו';
  }

  @override
  String get meanwhileTitle => 'בינתיים אפשר';

  @override
  String get prepNeededNow => 'נדרש עכשיו';

  @override
  String get allSteps => 'כל השלבים';

  @override
  String get undoLastAction => 'ביטול הפעולה האחרונה';

  @override
  String get undoNotAllowed => 'אי אפשר לבטל, כי כבר התחלתם שלב שתלוי בזה.';

  @override
  String get timersTitle => 'טיימרים';

  @override
  String get timerCheckDue => 'זמן לבדוק!';

  @override
  String checkAtLabel(String time) {
    return 'לבדוק בערך ב-$time';
  }

  @override
  String rangeUntil(String time) {
    return 'טווח הזמן: עד $time';
  }

  @override
  String get removeMinute => 'הורדת דקה';

  @override
  String nextStepPreview(String title) {
    return 'אחרי זה: $title';
  }

  @override
  String tomorrowAt(String time) {
    return 'מחר ב-$time';
  }

  @override
  String dateAt(String date, String time) {
    return '$date ב-$time';
  }

  @override
  String notifCheckTitle(String label) {
    return '⏰ $label: זמן לבדוק';
  }

  @override
  String notifCheckBody(String cue) {
    return 'בדקו: $cue';
  }

  @override
  String get notifCheckBodyDefault =>
      'לבשל כל אחד יכול · לחצו כדי לחזור לבישול';

  @override
  String get notifPreheatBody => 'בדקו שהתנור הגיע לחום';

  @override
  String notifRangeEndTitle(String label) {
    return '⏰ $label: סוף טווח הזמן';
  }

  @override
  String get notifRangeEndBodyDefault => 'זה הזמן לבדוק שוב';

  @override
  String notifPrepTitle(String task) {
    return '⏳ $task';
  }

  @override
  String notifPrepBody(int minutes) {
    return 'בעוד כ-$minutes דקות תצטרכו את זה';
  }

  @override
  String get notifTestTitle => '⏰ התראת בדיקה';

  @override
  String get notifTestBody => 'לבשל כל אחד יכול · ההתראות של הטיימרים עובדות';

  @override
  String get channelTimersName => 'טיימרים לבישול';

  @override
  String get channelTimersDescription => 'התראה כשהגיע הזמן לבדוק משהו שמתבשל';

  @override
  String get channelPrepName => 'תזכורות הכנה';

  @override
  String get channelPrepDescription => 'תזכורות שקטות להכנות לקראת השלב הבא';

  @override
  String get pause => 'השהיה';

  @override
  String get resume => 'המשך';

  @override
  String get addMinute => 'הוספת דקה';

  @override
  String get dismissTimer => 'סגירת הטיימר';

  @override
  String get allStepsDone => 'כל השלבים הושלמו!';

  @override
  String get goToFinish => 'לסיום הבישול';

  @override
  String get abandonCooking => 'הפסקת הבישול';

  @override
  String get abandonConfirm => 'להפסיק את הבישול? מה שעשיתם יישמר בהיסטוריה.';

  @override
  String get abandonAction => 'הפסקה';

  @override
  String get sessionEnded => 'הבישול הזה הסתיים';

  @override
  String get finishTitle => 'סיום הבישול';

  @override
  String finishSummary(String title) {
    return 'סיימתם לבשל: $title';
  }

  @override
  String cookingTime(String duration) {
    return 'זמן בישול: $duration';
  }

  @override
  String minutesShort(int minutes) {
    return '$minutes דק\'';
  }

  @override
  String get notesLabel => 'הערות לפעם הבאה (לא חובה)';

  @override
  String get saveAndFinish => 'שמירה וסיום';

  @override
  String get historyEmpty => 'כשתסיימו לבשל, הבישול יופיע כאן.';

  @override
  String get statusCompleted => 'הושלם';

  @override
  String get statusAbandoned => 'הופסק';

  @override
  String get statusInProgress => 'בתהליך';

  @override
  String startedAt(String time) {
    return 'התחיל: $time';
  }

  @override
  String endedAt(String time) {
    return 'הסתיים: $time';
  }

  @override
  String get notes => 'הערות';

  @override
  String get cookAgain => 'לבשל שוב';

  @override
  String get settingsNotifications => 'התראות טיימר';

  @override
  String get notificationsOn => 'ההתראות מאופשרות';

  @override
  String get notificationsOff => 'ההתראות חסומות, ולכן הטיימרים לא יתריעו';

  @override
  String get enableNotifications => 'אפשר התראות';

  @override
  String get exactAlarmsOn => 'תזמון מדויק מאופשר';

  @override
  String get exactAlarmsOff =>
      'התזמון המדויק כבוי, ולכן התראות עלולות להתעכב בכמה דקות';

  @override
  String get enableExactAlarms => 'אפשר תזמון מדויק';

  @override
  String get batteryTitle => 'חיסכון בסוללה';

  @override
  String get batteryRestricted =>
      'חיסכון בסוללה מגביל את האפליקציה. מומלץ לבטל את ההגבלה כדי שהטיימרים יתריעו בזמן.';

  @override
  String get batteryOk => 'חיסכון בסוללה לא מגביל את האפליקציה';

  @override
  String get openBatterySettings => 'פתיחת הגדרות הסוללה';

  @override
  String get batteryVendorHint =>
      'בטלפונים של שיאומי, סמסונג, וואווי ו-וואן פלוס יש לפעמים הגבלות נוספות. אם טיימר לא התריע, ודאו בהגדרות הסוללה של הטלפון שהאפליקציה מורשית לפעול ברקע.';

  @override
  String get testNotification => 'שליחת התראת בדיקה';

  @override
  String get testNotificationScheduled => 'התראת הבדיקה תגיע בעוד 10 שניות';

  @override
  String serverAddress(String url) {
    return 'כתובת השרת (מצב פיתוח): $url';
  }

  @override
  String get aboutTitle => 'אודות';

  @override
  String get aboutBody =>
      'בזמן הבישול האפליקציה עובדת גם בלי אינטרנט. השלבים, הטיימרים וההתקדמות נשמרים בטלפון.';

  @override
  String get refresh => 'רענון';

  @override
  String get importTitle => 'מתכון חדש';

  @override
  String get importTabText => 'טקסט';

  @override
  String get importTabPhoto => 'תמונה';

  @override
  String get importTabUrl => 'קישור';

  @override
  String get importTextHint => 'הדביקו או הקלידו כאן את המתכון';

  @override
  String get importUrlHint => 'https://…';

  @override
  String get importTakePhoto => 'צילום';

  @override
  String get importPickPhoto => 'מהגלריה';

  @override
  String get importPhotoNote => 'התמונה נשמרת רק עד שתאשרו את התוכנית.';

  @override
  String get importAnalyze => 'קריאת המתכון';

  @override
  String get importStageReading => 'רמי קורא את המתכון ובודק את המצרכים…';

  @override
  String get importStagePlanning => 'מכינים את תוכנית הבישול…';

  @override
  String get importStageSlow =>
      'זה לוקח קצת יותר זמן מהרגיל. אפשר להמשיך לחכות.';

  @override
  String get importDuplicateTitle => 'המתכון כבר יובא';

  @override
  String importDuplicateBody(String title) {
    return 'כבר ייבאתם את המתכון הזה: $title. לפתוח אותו במקום לייבא שוב?';
  }

  @override
  String get importOpenExisting => 'פתיחת הקיים';

  @override
  String get importAgain => 'ייבוא מחדש';

  @override
  String get importNotRecipe => 'לא זיהינו כאן מתכון.';

  @override
  String get privacyTitle => 'לפני הייבוא הראשון';

  @override
  String get privacyBody =>
      'כדי להכין את המתכון, הטקסט, הקישור או התמונה נשלחים לשירות בינה מלאכותית של Google. בשירות החינמי Google עשויה להשתמש במידע לשיפור המוצרים שלה. אל תשלחו מידע אישי. התמונה נשמרת במכשיר רק עד שתאשרו את התוכנית.';

  @override
  String get privacyAccept => 'הבנתי, להמשיך';

  @override
  String get draftsTitle => 'מתכונים שהתחלתם להוסיף';

  @override
  String get draftDiscard => 'מחיקה';

  @override
  String get clarifyTitle => 'כמה שאלות קצרות';

  @override
  String get clarifyIntro =>
      'חסר במתכון מידע שחשוב לתוכנית. ענו על מה שאתם יודעים, והשאר עלינו.';

  @override
  String get clarifyRequired => 'חשוב לבטיחות';

  @override
  String get clarifyDontKnow => 'לא בטוח/ה, תחליטו בשבילי';

  @override
  String get clarifyContinue => 'בניית התוכנית';

  @override
  String get clarifyAnswerHint => 'התשובה שלכם';

  @override
  String get reviewTitle => 'בדיקת התוכנית';

  @override
  String get reviewIntro =>
      'בדקו את המצרכים, הזמנים והטמפרטורות. אפשר לתקן כל ערך לפני האישור.';

  @override
  String get reviewEstimatesTitle => 'מה הוערך';

  @override
  String get reviewNoEstimates => 'כל הערכים מופיעים במתכון המקורי.';

  @override
  String get reviewAssumptions => 'הנחות';

  @override
  String get reviewLimitations => 'מה לא הצלחנו לקבוע בבטחה';

  @override
  String get reviewWarnings => 'שימו לב';

  @override
  String get reviewSources => 'מקורות';

  @override
  String get reviewOriginalSource => 'המתכון המקורי';

  @override
  String reviewFromSource(String text) {
    return 'מהמתכון המקורי: $text';
  }

  @override
  String get reviewPhotoCheck =>
      'התוכנית נבנתה מתמונה. בדקו שהכמויות והזמנים נקראו נכון.';

  @override
  String get reviewSafetyCheckbox => 'בדקתי את הערכים המסומנים';

  @override
  String get reviewApprove => 'אישור התוכנית';

  @override
  String get reviewCancelImport => 'ביטול הייבוא';

  @override
  String get reviewOutdatedTitle => 'התוכנית לא מעודכנת לשינויים במתכון';

  @override
  String get reviewOutdatedBody =>
      'שיניתם מצרכים או הוראות. צרו את התוכנית מחדש, או אשרו שבדקתם שהיא עדיין נכונה.';

  @override
  String get reviewRegenerate => 'יצירת התוכנית מחדש';

  @override
  String get reviewStillCorrect => 'בדקתי, התוכנית נכונה';

  @override
  String get provenanceAnswered => 'לפי תשובתך';

  @override
  String get provenanceReference => 'לפי מקור בטיחות מזון';

  @override
  String get provenanceUser => 'ערך שלך';

  @override
  String get editIngredient => 'עריכת מצרך';

  @override
  String get editName => 'שם';

  @override
  String get editAmount => 'כמות (כפי שתוצג)';

  @override
  String get editStep => 'עריכת הוראה';

  @override
  String get editTimer => 'עריכת זמן';

  @override
  String get editTimerMinutes => 'לבדוק אחרי (דקות)';

  @override
  String get editTimerMaxMinutes => 'סוף הטווח (דקות, לא חובה)';

  @override
  String get editTemperature => 'עריכת טמפרטורה (°C)';

  @override
  String get editRecipe => 'עריכת המתכון והתוכנית';

  @override
  String get recipeOutdatedBanner =>
      'התוכנית לא מעודכנת לשינויים במתכון. ערכו אותה או צרו אותה מחדש לפני הבישול.';

  @override
  String get errOffline =>
      'אין חיבור לאינטרנט. ייבוא מתכון חדש דורש חיבור; בישול של מתכון שמור עובד גם בלי.';

  @override
  String get errTimeout => 'זה לקח יותר מדי זמן. נסו שוב בעוד רגע.';

  @override
  String get errRateLimited => 'הגעתם למגבלת הייבוא לשעה. נסו שוב מאוחר יותר.';

  @override
  String get errAiBusy =>
      'הכנת מתכונים חדשים לא זמינה כרגע בגלל עומס זמני. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.';

  @override
  String get errDailyLimit =>
      'הגענו למגבלת הייבוא היומית של האפליקציה. נסו שוב מחר. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.';

  @override
  String get errTooLarge =>
      'התוכן גדול מדי. נסו מתכון קצר יותר או תמונה קטנה יותר.';

  @override
  String get errUnsupportedImage =>
      'סוג התמונה לא נתמך. נסו תמונת JPEG או PNG.';

  @override
  String get errInvalidUrl => 'הקישור לא תקין או לא נתמך.';

  @override
  String get errFetchFailed =>
      'לא הצלחנו לפתוח את הדף. נסו להדביק את טקסט המתכון במקום.';

  @override
  String get errSiteBlocked =>
      'האתר לא מאפשר לקרוא את הדף. העתיקו את טקסט המתכון והדביקו אותו בלשונית \"טקסט\".';

  @override
  String get errNoRecipeFound =>
      'לא מצאנו מתכון בדף. נסו להדביק את טקסט המתכון במקום.';

  @override
  String get errUnsafeToPlan =>
      'המתכון כולל שימורים ביתיים, שדורשים מתכון בדוק ומאומת. לא נבנה עבורם תוכנית על סמך הערכה.';

  @override
  String get errInvalidAiOutput =>
      'לא הצלחנו לבנות תוכנית אמינה מהמתכון הזה. נסו שוב, או נסחו את המתכון בבירור.';

  @override
  String get errNotConfigured =>
      'ייבוא מתכונים לא זמין כרגע. נסו שוב מאוחר יותר.';

  @override
  String get errGeneric => 'משהו השתבש בייבוא. נסו שוב.';

  @override
  String errAiBusyRetryIn(int minutes) {
    return 'הכנת מתכונים חדשים לא זמינה כרגע בגלל עומס זמני. אפשר לנסות שוב בעוד כ-$minutes דק\'. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.';
  }

  @override
  String get errAiQuota =>
      'הכנת מתכונים חדשים לא זמינה כרגע, כי הגענו למכסת השימוש היומית. נסו שוב מאוחר יותר. מה שהזנתם נשמר, והמתכונים השמורים והבישול ממשיכים לעבוד כרגיל.';

  @override
  String get errAiUnavailable =>
      'הכנת מתכונים חדשים לא זמינה כרגע. נסו שוב בעוד כמה דקות. המתכונים השמורים והבישול ממשיכים לעבוד כרגיל.';

  @override
  String get importRetry => 'נסו שוב';

  @override
  String get importRestored => 'שחזרנו את מה שהזנתם בניסיון הקודם.';

  @override
  String get importPlanFailedNote =>
      'המתכון נקרא ונשמר. אפשר לנסות שוב לבנות את התוכנית בלי לקרוא אותו מחדש.';

  @override
  String get stepPrimaryNext => 'סיימתי, לשלב הבא';

  @override
  String get stepPrimaryLast => 'סיימתי';

  @override
  String get stepPrimaryReady => 'מוכן, לשלב הבא';

  @override
  String get stepPrimaryReadyLast => 'מוכן';

  @override
  String stepNeedMoreTime(int minutes) {
    return 'צריך עוד זמן (+$minutes דק\')';
  }

  @override
  String get stepReadyEarly => 'כבר מוכן? לשלב הבא';

  @override
  String stepStartsTimer(String duration) {
    return 'כשתלחצו, יתחיל טיימר של $duration';
  }

  @override
  String get stepHelp => 'עזרה בשלב הזה';

  @override
  String get stepHideHelp => 'הסתרת העזרה';

  @override
  String safetyCheckLabel(String cue) {
    return 'בדקתי: $cue';
  }

  @override
  String get safetyCheckGeneric => 'בדקתי שהמנה מוכנה';

  @override
  String get backButton => 'חזרה';

  @override
  String get timerOptions => 'אפשרויות טיימר';

  @override
  String get stepsCompletedTitle => 'השלבים';

  @override
  String get stepNotDone => 'לא הושלם';

  @override
  String get durationUnderMinute => 'פחות מדקה';

  @override
  String get loadingShort => '…';

  @override
  String durationMinutes(int minutes) {
    return 'כ-$minutes דק\'';
  }

  @override
  String get durationHour => 'כשעה';

  @override
  String durationHourMinutes(int minutes) {
    return 'כשעה ו-$minutes דק\'';
  }

  @override
  String durationHours(String hours) {
    return 'כ-$hours שעות';
  }

  @override
  String overviewTotalTime(String time) {
    return 'זמן כולל: $time';
  }

  @override
  String overviewActiveTime(String time) {
    return 'עבודה בפועל: $time';
  }

  @override
  String get overviewChecklistIntro =>
      'סמנו מה יש לכם. אם משהו חסר, נמצא יחד פתרון.';

  @override
  String get haveIt => 'יש לי';

  @override
  String get missingIt => 'חסר לי';

  @override
  String get haveAll => 'יש לי הכול';

  @override
  String get findSolution => 'פתרון';

  @override
  String stillMissing(String items) {
    return 'עוד חסר: $items';
  }

  @override
  String insteadOf(String name) {
    return 'במקום $name';
  }

  @override
  String get notUsed => 'לא בשימוש';

  @override
  String get optionalItem => 'לא חובה';

  @override
  String get undoSubstitution => 'ביטול ההחלפה';

  @override
  String get startCookingCta => 'מתחילים לבשל';

  @override
  String get saveToMyRecipes => 'שמירה במתכונים שלי';

  @override
  String get advancedEdit => 'עריכה מתקדמת';

  @override
  String get attentionTitle => 'שימו לב';

  @override
  String get attentionAck => 'קראתי';

  @override
  String get attentionPhoto =>
      'המתכון נקרא מתמונה. כדאי לוודא שהכמויות נכונות.';

  @override
  String get planOutdated =>
      'התוכנית לא מעודכנת לשינויים שעשיתם. אפשר לטפל בזה בעריכה המתקדמת.';

  @override
  String get cookingNowLocked =>
      'המתכון בבישול עכשיו. אפשר לשנות אותו אחרי שתסיימו.';

  @override
  String sheetTitle(String name) {
    return 'אין לכם $name?';
  }

  @override
  String get sheetNoteHint => 'מה יש לכם במקום? (לא חובה)';

  @override
  String get sheetFind => 'חפשו לי פתרון';

  @override
  String get sheetSearching => 'מחפשים פתרון…';

  @override
  String get sheetTryOther => 'לחפש פתרון אחר';

  @override
  String get verdictWorks => 'אפשר להחליף';

  @override
  String get verdictChanges => 'אפשר, והתוצאה תהיה מעט שונה';

  @override
  String get verdictNotRecommended => 'לא מומלץ';

  @override
  String get verdictNone => 'אין לזה תחליף טוב';

  @override
  String get useThis => 'להשתמש בזה';

  @override
  String get noThanks => 'לא תודה';

  @override
  String get understood => 'הבנתי';

  @override
  String get substitutionFailed =>
      'לא הצלחנו להחיל את הפתרון. אפשר לנסות שוב, או לשנות ידנית בעריכה המתקדמת.';

  @override
  String get draftCancel => 'ביטול הייבוא';

  @override
  String get fullPlan => 'כל שלבי הבישול';

  @override
  String attentionSafetyEstimate(String title) {
    return 'זמן הבישול בשלב \"$title\" הוא הערכה. בדקו מוכנות לפי הסימנים בשלב.';
  }

  @override
  String get remyTitle => 'רמי, העוזר שלך לבישול';

  @override
  String get remyOpen => 'רמי';

  @override
  String get remyHint => 'כתבו לרמי…';

  @override
  String get remyGreeting =>
      'היי, אני רמי! אפשר לשאול אותי על הבישול, או לבקש: \"הבא\", \"חזרה\", \"כמה זמן נשאר?\", \"תוסיף 5 דקות\".';

  @override
  String get remyChipNow => 'מה עכשיו?';

  @override
  String get remyChipTime => 'כמה זמן נשאר?';

  @override
  String get remyChipHelp => 'עזרה בשלב';

  @override
  String get remySend => 'שליחה';

  @override
  String get remyApprove => 'אישור';

  @override
  String get remyReject => 'לא, תודה';

  @override
  String get remyRejected => 'בסדר, לא שיניתי כלום.';

  @override
  String get remyThinking => 'רמי חושב…';

  @override
  String get remyProposalTitle => 'הצעה של רמי';

  @override
  String get remyAllDone => 'כל השלבים הושלמו! אפשר לסיים את הבישול.';

  @override
  String remyStartFirst(String label) {
    return 'קודם צריך: \"$label\". זה כבר קרה?';
  }

  @override
  String remyFinishEarly(String label, String time) {
    return 'הטיימר \"$label\" עוד רץ (נשארו $time). לסיים את השלב כבר עכשיו?';
  }

  @override
  String remySafetyCheck(String cue) {
    return 'לפני שממשיכים: $cue בדקתם?';
  }

  @override
  String remyConfirmAction(String label) {
    return 'לסמן \"$label\"?';
  }

  @override
  String remyConfirmActionTimer(String label, String time) {
    return 'לסמן \"$label\" ולהפעיל טיימר של $time?';
  }

  @override
  String remyConfirmExtend(String time, String label) {
    return 'להוסיף $time לטיימר \"$label\"?';
  }

  @override
  String get remyNothingToUndo => 'אין עדיין מה לבטל.';

  @override
  String get remyNoTimers => 'אין טיימר פעיל כרגע.';

  @override
  String remyTimerLeft(String label, String time) {
    return '$label: נשארו $time.';
  }

  @override
  String remyTimerDue(String label) {
    return '$label: הגיע הזמן לבדוק.';
  }

  @override
  String remyTimerPausedLeft(String label, String time) {
    return '$label: מושהה, נשארו $time.';
  }

  @override
  String remyWhichTimer(String labels) {
    return 'לאיזה טיימר? $labels';
  }

  @override
  String get remyTooLong => 'אפשר להוסיף עד שעה בכל פעם.';

  @override
  String remyNow(String title, String instruction) {
    return 'עכשיו: $title. $instruction';
  }

  @override
  String remyTellMeWhen(String label) {
    return 'כשזה קורה, תגידו לי \"$label\" ואפעיל את הטיימר.';
  }

  @override
  String get remyTellMeWhenGeneric => 'כשזה קורה, תגידו לי ואסמן את זה.';

  @override
  String remyStepDone(String title) {
    return '✓ סיימנו: $title.';
  }

  @override
  String remyNextStep(String title) {
    return 'עכשיו: $title.';
  }

  @override
  String remyTimerStarted(String label, String time) {
    return '⏱ הטיימר \"$label\" התחיל. לבדוק בעוד $time.';
  }

  @override
  String remyMarked(String label) {
    return '✓ סומן: $label.';
  }

  @override
  String get remyUndone => '↩ חזרנו צעד אחד אחורה.';

  @override
  String remyExtended(String added, String label, String left) {
    return '⏱ הוספתי $added לטיימר \"$label\". נשארו $left.';
  }

  @override
  String remyPausedDone(String label) {
    return '⏸ הטיימר \"$label\" הושהה.';
  }

  @override
  String remyResumedDone(String label) {
    return '▶ הטיימר \"$label\" ממשיך.';
  }

  @override
  String remyPatched(String summary) {
    return '✓ עדכנתי את השלבים הבאים: $summary.';
  }

  @override
  String get remyAlreadyDone => 'זה כבר בוצע.';

  @override
  String get remyNotPossible => 'אי אפשר לעשות את זה עכשיו.';

  @override
  String get remyChangeNotPossible =>
      'את השינוי הזה כבר אי אפשר לעשות, כי השלב כבר התחיל.';

  @override
  String get remyOffline =>
      'אין חיבור לאינטרנט, אז אני לא יכול לענות על שאלות כרגע. פקודות כמו \"הבא\", \"חזרה\" ו\"כמה זמן נשאר?\" עובדות גם בלי אינטרנט.';

  @override
  String get remyUnavailable =>
      'אני לא זמין לשאלות כרגע. הבישול ממשיך כרגיל, ופקודות פשוטות עובדות.';

  @override
  String get durHour => 'שעה';

  @override
  String durHours(int n) {
    return '$n שעות';
  }

  @override
  String get durMinute => 'דקה';

  @override
  String durMinutes(int n) {
    return '$n דקות';
  }

  @override
  String durSeconds(int n) {
    return '$n שניות';
  }

  @override
  String durAnd(String a, String b) {
    return '$a ו-$b';
  }

  @override
  String get changesDuringCooking => 'שינויים בזמן הבישול';

  @override
  String remyNextPreview(String title) {
    return 'אחרי זה: $title.';
  }

  @override
  String get remyLastStep => 'זה השלב האחרון.';

  @override
  String remyIngredientAmount(String name, String amount) {
    return '$name: $amount.';
  }

  @override
  String remyTemperature(String title, int value) {
    return '$title: $value מעלות.';
  }

  @override
  String get remyNoTemperature => 'בשלב הזה אין טמפרטורה מוגדרת.';

  @override
  String remyStepIngredients(String items) {
    return 'בשלב הזה: $items.';
  }

  @override
  String get remyNoStepIngredients => 'אין מצרכים מיוחדים בשלב הזה.';

  @override
  String remyStepsLeft(int left, int total) {
    return 'נשארו $left שלבים מתוך $total.';
  }

  @override
  String get remyDidntCatch => 'לא הבנתי, אפשר לנסח שוב?';

  @override
  String get remyConfirmUndo => 'לבטל את הפעולה האחרונה?';

  @override
  String remyConfirmPause(String label) {
    return 'להשהות את הטיימר \"$label\"?';
  }

  @override
  String remyConfirmResume(String label) {
    return 'להמשיך את הטיימר \"$label\"?';
  }

  @override
  String remyConfirmNext(String title) {
    return 'לסיים את \"$title\" ולעבור לשלב הבא?';
  }

  @override
  String get voiceMic => 'דיבור עם רמי';

  @override
  String get voiceTapToSpeak => 'לחצו על המיקרופון ודברו';

  @override
  String get voicePreparing => 'מכינים את המיקרופון…';

  @override
  String get voiceListening => 'מקשיב…';

  @override
  String get voiceProcessing => 'רגע…';

  @override
  String get voiceSpeaking => 'רמי מדבר…';

  @override
  String get voiceStop => 'עצירה';

  @override
  String get voiceContinuous => 'שיחה רציפה';

  @override
  String get voicePermissionDenied =>
      'כדי לדבר עם רמי צריך לאשר גישה למיקרופון. אפשר לאשר בהגדרות הטלפון, או פשוט להקליד.';

  @override
  String get voiceUnavailable =>
      'זיהוי דיבור לא זמין בטלפון הזה. אפשר להקליד לרמי.';

  @override
  String get voiceHebrewUnsupported =>
      'זיהוי דיבור בעברית לא זמין בטלפון הזה. אפשר להקליד לרמי.';

  @override
  String get voiceNetwork =>
      'זיהוי הדיבור בטלפון הזה צריך חיבור לאינטרנט. אפשר להקליד, ופקודות הבישול עובדות גם בלי אינטרנט.';

  @override
  String get voiceNoSpeech => 'לא שמעתי. אפשר לנסות שוב.';

  @override
  String get voiceError =>
      'משהו השתבש בזיהוי הדיבור. אפשר לנסות שוב או להקליד.';

  @override
  String get voiceNoHebrewVoice =>
      'אין בטלפון קול עברי להקראה, אז התשובות יופיעו כטקסט.';

  @override
  String get menu => 'תפריט';

  @override
  String get homeGreeting => 'מה מבשלים היום?';

  @override
  String get newRecipeSubtitle => 'מטקסט, מתמונה או מקישור';

  @override
  String get allRecipesLink => 'לכל המתכונים';

  @override
  String get homeEmptyRecipes =>
      'עוד אין כאן מתכונים. אפשר להתחיל מ\"מתכון חדש\".';

  @override
  String get cookingNowTitle => 'מבשלים עכשיו';

  @override
  String stepOfTotal(Object current, Object total) {
    return 'שלב $current מתוך $total';
  }

  @override
  String get continueCookingCta => 'המשך לבשל';

  @override
  String get recipesSearchEmpty => 'לא מצאנו מתכון כזה';

  @override
  String get importIntro => 'איך המתכון אצלכם?';

  @override
  String get importLeave => 'יציאה';

  @override
  String get importLeaveNote =>
      'אפשר לצאת מהמסך. כשהמתכון יהיה מוכן, הוא יחכה לכם במטבח.';

  @override
  String get overviewReady => 'הכול מוכן. אפשר להתחיל לבשל!';

  @override
  String get overviewWhatYouNeed => 'מה צריך';

  @override
  String get overviewMore => 'פעולות למתכון';

  @override
  String get remyAsk => 'שאלו את רמי';

  @override
  String get remySheetSubtitle => 'אפשר לכתוב או לדבר';

  @override
  String get remyPrepGreeting =>
      'היי, אני רמי! אפשר לשאול אותי על המתכון, על מצרך שחסר או על תחליף. כשתתחילו לבשל, אלווה אתכם בכל שלב.';

  @override
  String get remyPrepChipFirst => 'במה מתחילים?';

  @override
  String get remyPrepChipTime => 'כמה זמן זה לוקח?';

  @override
  String get remyPrepChipMissing => 'חסר לי מצרך';

  @override
  String get remyPrepNotYet =>
      'את זה עושים כשמתחילים לבשל. בינתיים אפשר לשאול אותי על המתכון.';

  @override
  String remyPrepFirstStep(Object title, Object instruction) {
    return 'מתחילים ב: $title. $instruction';
  }

  @override
  String remyPrepTotalTime(Object total, Object active) {
    return 'המתכון לוקח בערך $total, מתוכם $active עבודה בפועל.';
  }

  @override
  String get remyPrepMissing =>
      'סמנו \"חסר לי\" ליד המצרך ברשימה, ואציע לכם תחליף מתאים.';

  @override
  String get remyListeningTitle => 'מקשיב לכם';

  @override
  String get remyTypeInstead => 'להקליד במקום';

  @override
  String get remyClose => 'סגירה';

  @override
  String get stepIngredientsTitle => 'מה צריך לשלב הזה';

  @override
  String get finishCelebrate => 'בתאבון!';

  @override
  String get finishBackHome => 'חזרה למטבח';

  @override
  String get historyEmptyTitle => 'עוד אין היסטוריה';

  @override
  String get settingsTimersReady => 'הטיימרים יתריעו בזמן';

  @override
  String get settingsAboutVersionless =>
      'לבשל כל אחד יכול עוזרת לבשל צעד אחר צעד, עם טיימרים, תזכורות ורמי לצידכם.';

  @override
  String get fontLicense => 'הגופן Heebo מופץ ברישיון SIL Open Font License.';

  @override
  String get timerPaused => 'מושהה';

  @override
  String timerRunningUntil(Object time) {
    return 'עד $time';
  }

  @override
  String get progressLabel => 'התקדמות הבישול';

  @override
  String get prepTaskDone => 'בוצע';

  @override
  String get remyAmountUnknown => 'הכמות לא צוינה';

  @override
  String remyPrepStepCount(int count) {
    return 'במתכון יש $count שלבים.';
  }
}
