// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '我的記帳本';

  @override
  String get settings => '設定';

  @override
  String get language => '語言';

  @override
  String get languageFollowSystem => '跟隨系統';

  @override
  String get languageFollowSystemHint => '手機設為中文時使用繁體中文，其他語言則使用英文。';
}
