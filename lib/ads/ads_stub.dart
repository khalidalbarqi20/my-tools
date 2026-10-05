import 'package:flutter/widgets.dart';

/// نسخة الويب (لا توجد إعلانات في المعاينة).
class Ads {
  static bool get ready => false;
  static Future<void> init() async {}
  static Widget banner() => const SizedBox.shrink();
  static void onToolClosed(String toolId) {}
}
