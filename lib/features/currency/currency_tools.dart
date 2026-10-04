import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'currency_page.dart';

final List<Tool> currencyTools = [
  Tool(
    id: 'conv_currency',
    nameAr: 'تحويل العملات',
    nameEn: 'Currency Converter',
    category: 'convert',
    keywords: [
      'عملات', 'عملة', 'دولار', 'ريال', 'يورو', 'درهم', 'جنيه', 'صرف',
      'سعر الصرف', 'تحويل', 'محول', 'currency', 'dollar', 'euro', 'usd',
      'sar', 'exchange', 'exchange rate', 'forex',
    ],
    icon: Icons.currency_exchange,
    builder: (_) => const CurrencyPage(),
  ),
];
