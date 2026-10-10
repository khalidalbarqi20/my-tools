import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../gold/gold_page.dart';
import '../pdf/single_pdf_tool.dart' show Opt;
import '../text/text_tool_page.dart';
import 'hijri_logic.dart';
import 'tafqeet.dart';

final List<Tool> arabicTools = [
  Tool(
    id: 'text_num_words',
    nameAr: 'رقم إلى كلمات',
    nameEn: 'Number to Words',
    category: 'text',
    keywords: ['تفقيط', 'رقم', 'كلمات', 'كتابة الأرقام', 'عدد بالحروف', 'number to words', 'tafqeet', 'spell'],
    icon: Icons.spellcheck,
    builder: (_) => TextToolPage(
      title: 'رقم إلى كلمات',
      hint: 'اكتب الرقم، مثال: 1250',
      run: (s, o) => numberToWords(s),
    ),
  ),
  Tool(
    id: 'text_amount_words',
    nameAr: 'مبلغ إلى كلمات (تفقيط)',
    nameEn: 'Amount to Words',
    category: 'text',
    keywords: ['تفقيط', 'مبلغ', 'ريال', 'هللة', 'شيك', 'فاتورة', 'كتابة المبلغ', 'amount in words', 'check', 'cheque', 'invoice'],
    icon: Icons.receipt_long_outlined,
    builder: (_) => TextToolPage(
      title: 'مبلغ إلى كلمات (تفقيط)',
      hint: 'اكتب المبلغ، مثال: 1250.50',
      options: [
        Opt.choice('cur', 'العملة', [for (final c in tafqeetCurrencies) (c.$1, c.$2)], initial: 'sar'),
        const Opt.toggle('only', 'إضافة «فقط ... لا غير»'),
      ],
      run: (s, o) => amountToWords(s, o['cur'] ?? 'sar', only: o['only'] == 'true'),
    ),
  ),
  Tool(
    id: 'time_hijri',
    nameAr: 'تحويل التاريخ الهجري والميلادي',
    nameEn: 'Hijri Converter',
    category: 'time',
    keywords: ['هجري', 'ميلادي', 'تاريخ', 'تقويم', 'أم القرى', 'hijri', 'gregorian', 'calendar', 'umm al-qura'],
    icon: Icons.calendar_month_outlined,
    builder: (_) => TextToolPage(
      title: 'تحويل التاريخ الهجري والميلادي',
      hint: 'اكتب التاريخ: 2026-10-05 (سنة-شهر-يوم)\nأو اكتب «اليوم» لتاريخ اليوم',
      options: const [
        Opt.choice('dir', 'نوع التحويل', [('g2h', 'ميلادي ← هجري'), ('h2g', 'هجري ← ميلادي')], initial: 'g2h'),
      ],
      note: 'يعتمد تقويم أم القرى (من 1318 إلى 1500 هـ). قد يختلف يومًا عن رؤية الهلال الفعلية.',
      run: (s, o) => hijriConvert(s, toHijriDir: o['dir'] != 'h2g'),
    ),
  ),
  Tool(
    id: 'gold_price',
    nameAr: 'سعر الذهب',
    nameEn: 'Gold Price',
    category: 'calc',
    keywords: ['ذهب', 'عيار', 'جرام', 'اونصة', 'أونصة', 'سعر الذهب', 'مجوهرات', 'gold', 'karat', 'carat', 'ounce', 'gram'],
    icon: Icons.workspace_premium_outlined,
    builder: (_) => const GoldPage(),
  ),
];
