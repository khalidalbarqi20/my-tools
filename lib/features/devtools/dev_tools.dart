import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../htmlrun/html_editor_page.dart';
import 'dev_pages.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'devtools',
      keywords: ['مطور', 'أمان', 'developer', 'security', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> devTools = [
  _t('sec_hash', 'بصمة الملفات والنصوص (SHA)', 'SHA Hash',
      ['هاش', 'بصمة', 'تشفير', 'hash', 'sha256', 'sha1', 'checksum'],
      Icons.fingerprint, (_) => const HashPage()),
  _t('sec_password', 'فحص كلمة المرور', 'Password Checker',
      ['باسورد', 'قوة', 'تسريب', 'password', 'strength', 'leak', 'hibp', 'pwned'],
      Icons.password, (_) => const PasswordPage()),
  _t('sec_jwt', 'فك JWT', 'JWT Decoder',
      ['توكن', 'رمز', 'jwt', 'token', 'decode'],
      Icons.vpn_key_outlined, (_) => const JwtPage()),
  _t('sec_timestamp', 'محول الطابع الزمني', 'Timestamp Converter',
      ['وقت', 'تاريخ', 'unix', 'epoch', 'timestamp', 'date'],
      Icons.schedule, (_) => const TimestampPage()),
  _t('sec_diff', 'مقارنة نصين', 'Text Diff',
      ['فرق', 'اختلاف', 'diff', 'compare', 'text'],
      Icons.compare_arrows, (_) => const DiffPage()),
  _t('sec_html_editor', 'محرر HTML بمعاينة', 'HTML Editor',
      ['كود', 'برمجة', 'صفحة', 'قالب', 'html', 'code', 'editor', 'preview', 'template'],
      Icons.code, (_) => const HtmlEditorPage()),
];
