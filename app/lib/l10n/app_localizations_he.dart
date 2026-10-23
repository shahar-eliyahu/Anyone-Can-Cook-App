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
  String get comingSoon => 'בקרוב';

  @override
  String get noActiveSession => 'אין בישול פעיל כרגע';

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
  String get retry => 'נסו שוב';

  @override
  String databaseReady(int version) {
    return 'מסד הנתונים מוכן (גרסה $version)';
  }
}
