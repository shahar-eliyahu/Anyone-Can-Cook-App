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
  String get importComingSoon =>
      'ייבוא מתכונים חדשים (טקסט, תמונה וקישור) יתווסף בשלב הבא';

  @override
  String get backendConnecting => 'מתחבר לשרת…';

  @override
  String get backendWakingUp => 'השרת מתעורר… זה יכול לקחת עד דקה';

  @override
  String get backendOk => 'השרת מחובר ✓';

  @override
  String get aiModeDemo => 'מצב הדגמה (ללא בינה מלאכותית)';

  @override
  String get aiModeLive => 'בינה מלאכותית מחוברת';

  @override
  String get aiModeUnknown => 'מצב בינה מלאכותית לא ידוע';

  @override
  String get backendOffline => 'אין חיבור לשרת';

  @override
  String get offlineCookingNote => 'אפשר לבשל גם בלי חיבור';

  @override
  String get retry => 'נסו שוב';

  @override
  String databaseReady(int version) {
    return 'מסד הנתונים מוכן (גרסה $version)';
  }

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
  String get planActions => 'תאשרו בזמן הבישול:';

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
  String get nowLabel => 'עכשיו';

  @override
  String waitingForTimer(String label) {
    return 'ממתינים לטיימר: $label';
  }

  @override
  String startsTimer(String label, String duration) {
    return 'יפעיל טיימר: $label ($duration)';
  }

  @override
  String get meanwhileTitle => 'בינתיים אפשר';

  @override
  String get prepNeededNow => 'נדרש עכשיו';

  @override
  String get allSteps => 'כל השלבים';

  @override
  String get stepLocked => 'ממתין לשלבים קודמים';

  @override
  String get stepReady => 'מוכן להתחלה';

  @override
  String get stepInProgress => 'בתהליך';

  @override
  String get stepWaiting => 'ממתין לטיימר';

  @override
  String get stepDone => 'הושלם';

  @override
  String get undoLastAction => 'ביטול הפעולה האחרונה';

  @override
  String actionDone(String label) {
    return '✓ $label';
  }

  @override
  String actionDoneWithTimer(String label, String timer, String duration) {
    return '✓ $label · טיימר $timer הופעל ($duration)';
  }

  @override
  String get actionAlreadyDone => 'זה כבר סומן כבוצע';

  @override
  String get actionNotAvailable => 'אי אפשר לבצע את זה עכשיו';

  @override
  String get undoNotAllowed => 'אי אפשר לבטל — כבר התחלתם שלב שתלוי בזה';

  @override
  String get timersTitle => 'טיימרים';

  @override
  String get timerFinished => 'הזמן נגמר!';

  @override
  String get pause => 'השהיה';

  @override
  String get resume => 'המשך';

  @override
  String get addMinute => '+ דקה';

  @override
  String get dismissTimer => 'סגירת הטיימר';

  @override
  String confirmActionTitle(String label) {
    return '$label?';
  }

  @override
  String get confirmCheck => 'לפני שממשיכים, בדקו:';

  @override
  String confirmYes(String label) {
    return 'כן, $label';
  }

  @override
  String get confirmNotYet => 'עוד לא';

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
  String get actionsLog => 'מה עשיתם';

  @override
  String get approvedChanges => 'שינויים שאושרו בתוכנית';

  @override
  String get noApprovedChanges => 'לא בוצעו שינויים בתוכנית';

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
  String get testNotification => 'שליחת התראת בדיקה (בעוד 10 שניות)';

  @override
  String get testNotificationScheduled => 'התראת בדיקה תגיע בעוד 10 שניות';

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
}
