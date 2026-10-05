import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'random_pages.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'random',
      keywords: ['عشوائي', 'random', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> randomTools = [
  _t('rand_number', 'رقم عشوائي', 'Random Number',
      ['رقم', 'أرقام', 'عدد', 'سحب', 'قرعة', 'number', 'generator', 'lottery'],
      Icons.numbers, (_) => const RandomNumberPage()),
  _t('rand_dice', 'رمي النرد', 'Dice',
      ['نرد', 'زهر', 'حجر', 'dice', 'roll', 'die'],
      Icons.casino_outlined, (_) => const DicePage()),
  _t('rand_coin', 'رمي العملة', 'Coin Flip',
      ['عملة', 'صورة', 'كتابة', 'قرعة', 'coin', 'flip', 'heads', 'tails'],
      Icons.monetization_on_outlined, (_) => const CoinPage()),
  _t('rand_picker', 'اختيار عشوائي', 'Random Picker',
      ['اختيار', 'اختر', 'قرعة', 'سحب', 'فائز', 'ترتيب', 'picker', 'choose', 'shuffle', 'draw'],
      Icons.how_to_vote_outlined, (_) => const PickerPage()),
  _t('rand_yesno', 'نعم / لا', 'Yes / No',
      ['نعم', 'لا', 'قرار', 'سؤال', 'yes', 'no', 'decision'],
      Icons.help_outline, (_) => const YesNoPage()),
  _t('rand_counter', 'العدّاد', 'Counter',
      ['عداد', 'عد', 'تسبيح', 'count', 'tally', 'clicker'],
      Icons.add_circle_outline, (_) => const CounterPage()),
];
