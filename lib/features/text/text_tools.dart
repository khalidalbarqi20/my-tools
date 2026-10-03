import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../pdf/single_pdf_tool.dart' show Opt;
import 'password_page.dart';
import 'text_logic.dart';
import 'text_tool_page.dart';
import 'wordcount_page.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'text',
      keywords: ['نص', 'نصوص', 'text', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> textTools = [
  _t('text_count', 'عداد الكلمات والأحرف', 'Word Counter',
      ['كلمات', 'أحرف', 'حروف', 'عد', 'جمل', 'count', 'words', 'characters'],
      Icons.format_list_numbered, (_) => const WordCountPage()),
  _t('text_clean', 'تنظيف النص', 'Clean Text',
      ['مسافات', 'أسطر فارغة', 'إزالة', 'تنسيق', 'clean', 'spaces', 'trim', 'empty lines'],
      Icons.cleaning_services_outlined,
      (_) => TextToolPage(
            title: 'تنظيف النص',
            hint: 'الصق النص المراد تنظيفه...',
            options: const [
              Opt.toggle('trim', 'حذف المسافات من بداية ونهاية كل سطر', on: true),
              Opt.toggle('spaces', 'تحويل المسافات المتكررة لمسافة واحدة', on: true),
              Opt.toggle('empty', 'حذف الأسطر الفارغة', on: true),
            ],
            run: (s, o) => cleanText(s,
                trimLines: o['trim'] == 'true',
                collapseSpaces: o['spaces'] == 'true',
                removeEmpty: o['empty'] == 'true'),
          )),
  _t('text_case', 'تغيير حالة الأحرف', 'Change Case',
      ['كبيرة', 'صغيرة', 'uppercase', 'lowercase', 'title', 'case', 'capital'],
      Icons.text_format,
      (_) => TextToolPage(
            title: 'تغيير حالة الأحرف',
            hint: 'اكتب النص الإنجليزي هنا...',
            options: const [
              Opt.choice(
                  'mode',
                  'الحالة',
                  [
                    ('upper', 'كبيرة'),
                    ('lower', 'صغيرة'),
                    ('title', 'عناوين'),
                    ('sentence', 'جمل'),
                  ],
                  initial: 'upper'),
            ],
            run: (s, o) => convertCase(s, o['mode'] ?? 'upper'),
            note: 'الأحرف الكبيرة والصغيرة تخص اللغات اللاتينية، ولا تؤثر على العربية.',
          )),
  _t('text_reverse', 'عكس النص', 'Reverse Text',
      ['عكس', 'قلب', 'معكوس', 'reverse', 'flip', 'mirror'],
      Icons.flip,
      (_) => TextToolPage(
            title: 'عكس النص',
            hint: 'اكتب النص هنا...',
            options: const [
              Opt.choice(
                  'mode',
                  'نوع العكس',
                  [('chars', 'الأحرف'), ('words', 'الكلمات'), ('lines', 'الأسطر')],
                  initial: 'chars'),
            ],
            run: (s, o) => reverseText(s, o['mode'] ?? 'chars'),
          )),
  _t('text_extract', 'استخراج أرقام وروابط', 'Extract Numbers & Links',
      ['استخراج', 'أرقام', 'روابط', 'بريد', 'إيميل', 'extract', 'numbers', 'links', 'urls', 'emails'],
      Icons.manage_search,
      (_) => TextToolPage(
            title: 'استخراج أرقام وروابط',
            hint: 'الصق النص الذي تريد الاستخراج منه...',
            options: const [
              Opt.choice(
                  'kind',
                  'استخراج',
                  [('numbers', 'أرقام'), ('links', 'روابط'), ('emails', 'بريد')],
                  initial: 'numbers'),
            ],
            run: (s, o) => (switch (o['kind']) {
              'links' => extractLinks(s),
              'emails' => extractEmails(s),
              _ => extractNumbers(s),
            })
                .join('\n'),
            summary: (out) => 'عدد النتائج: ${out.split('\n').length}',
            note: 'الأرقام العربية (١٢٣) تُحوَّل تلقائيًا للأرقام اللاتينية.',
          )),
  _t('text_lines', 'ترتيب الأسطر وحذف المكرر', 'Sort & Deduplicate Lines',
      ['ترتيب', 'فرز', 'تكرار', 'مكرر', 'قائمة', 'sort', 'duplicate', 'unique', 'lines'],
      Icons.sort_by_alpha,
      (_) => TextToolPage(
            title: 'ترتيب الأسطر وحذف المكرر',
            hint: 'اكتب كل عنصر في سطر...',
            options: const [
              Opt.toggle('sort', 'ترتيب أبجدي', on: true),
              Opt.toggle('desc', 'ترتيب عكسي'),
              Opt.toggle('unique', 'حذف الأسطر المكررة', on: true),
              Opt.toggle('ic', 'تجاهل حالة الأحرف', on: true),
            ],
            run: (s, o) => processLines(s,
                sort: o['sort'] == 'true',
                desc: o['desc'] == 'true',
                unique: o['unique'] == 'true',
                ignoreCase: o['ic'] == 'true'),
            summary: (out) => 'عدد الأسطر: ${out.split('\n').length}',
          )),
  _t('text_password', 'مولد كلمات المرور', 'Password Generator',
      ['كلمة مرور', 'باسورد', 'سر', 'أمان', 'password', 'generator', 'secure', 'random'],
      Icons.password, (_) => const PasswordPage()),
];
