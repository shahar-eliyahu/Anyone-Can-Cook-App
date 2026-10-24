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
  String get estimateHint => 'ערך משוער — המתכון המקורי לא ציין אותו';

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
    return 'טמפרטורה: $value°';
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
  String get undoNotAllowed => 'אי אפשר לבטל — כבר התחלתם שלב שתלוי בזה';

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
  String get removeMinute => '− דקה';

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
  String get addMinute => '+ דקה';

  @override
  String get dismissTimer => 'סגירת הטיימר';

  @override
  String get allStepsDone => 'כל השלבים הושלמו! 🎉';

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
  String get historyEmpty => 'עוד לא בישלתם. בחרו מתכון מהרשימה והתחילו.';

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
  String get notificationsOff => 'ההתראות חסומות — טיימרים לא יתריעו';

  @override
  String get enableNotifications => 'אפשר התראות';

  @override
  String get exactAlarmsOn => 'תזמון מדויק מאופשר';

  @override
  String get exactAlarmsOff =>
      'תזמון מדויק כבוי — התראות עלולות להתעכב בכמה דקות';

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
  String get testNotification => 'בדיקת התראות (תגיע בעוד 10 שניות)';

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
      'בזמן הבישול האפליקציה עובדת גם בלי אינטרנט: השלבים, הטיימרים וההתקדמות נשמרים במכשיר.';

  @override
  String get refresh => 'רענון';

  @override
  String get importTitle => 'ייבוא מתכון';

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
  String get importAnalyze => 'ניתוח המתכון';

  @override
  String get importStageReading => 'בודקים את המצרכים וההוראות…';

  @override
  String get importStagePlanning => 'מסדרים לך את שלבי הבישול…';

  @override
  String get importStageSlow => 'זה לוקח קצת יותר זמן מהרגיל…';

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
  String get draftsTitle => 'ייבואים שלא הושלמו';

  @override
  String get draftDiscard => 'מחיקה';

  @override
  String get clarifyTitle => 'כמה שאלות קצרות';

  @override
  String get clarifyIntro =>
      'חסר במתכון מידע שחשוב לתוכנית. ענו על מה שאתם יודעים.';

  @override
  String get clarifyRequired => 'חשוב לבטיחות';

  @override
  String get clarifyDontKnow => 'לא יודע/ת';

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
      'התוכנית נבנתה מתמונה — בדקו שהכמויות והזמנים נקראו נכון.';

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
  String get reviewStillCorrect => 'בדקתי — התוכנית נכונה';

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
  String get stepPrimaryNext => 'סיימתי — לשלב הבא';

  @override
  String get stepPrimaryLast => 'סיימתי';

  @override
  String get stepPrimaryReady => 'מוכן — לשלב הבא';

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
}
