import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'converter_logic.dart';
import 'converter_page.dart';

Tool _conv(String id, String ar, String en, List<String> kw, IconData icon,
        List<Unit> units,
        {double minBase = 0, String? note}) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'convert',
      keywords: ['تحويل', 'محول', 'convert', 'converter', ...kw],
      icon: icon,
      builder: (_) => ConverterPage(
          title: ar, units: units, minBase: minBase, note: note),
    );

final List<Tool> converterTools = [
  _conv('conv_length', 'تحويل الطول', 'Length Converter',
      ['طول', 'متر', 'ميل', 'قدم', 'بوصة', 'length', 'meter', 'mile'],
      Icons.straighten, lengthUnits),
  _conv('conv_weight', 'تحويل الوزن', 'Weight Converter',
      ['وزن', 'كيلو', 'رطل', 'جرام', 'weight', 'kg', 'pound'],
      Icons.scale_outlined, weightUnits),
  _conv('conv_area', 'تحويل المساحة', 'Area Converter',
      ['مساحة', 'هكتار', 'فدان', 'area', 'acre'],
      Icons.crop_square, areaUnits,
      note: 'الفدان المصري = 4200.833 م². والأكر (acre) وحدة مختلفة'),
  _conv('conv_volume', 'تحويل الحجم', 'Volume Converter',
      ['حجم', 'لتر', 'جالون', 'volume', 'liter', 'gallon'],
      Icons.local_drink_outlined, volumeUnits),
  _conv('conv_temp', 'تحويل الحرارة', 'Temperature Converter',
      ['حرارة', 'درجة', 'سلزيوس', 'فهرنهايت', 'كلفن', 'temperature', 'celsius', 'fahrenheit', 'kelvin'],
      Icons.thermostat, tempUnits, minBase: -273.15),
  _conv('conv_speed', 'تحويل السرعة', 'Speed Converter',
      ['سرعة', 'كم', 'ميل', 'عقدة', 'speed', 'kmh', 'mph', 'knots'],
      Icons.speed, speedUnits),
  _conv('conv_pressure', 'تحويل الضغط', 'Pressure Converter',
      ['ضغط', 'باسكال', 'بار', 'pressure', 'psi', 'bar', 'pascal'],
      Icons.compress, pressureUnits),
  _conv('conv_energy', 'تحويل الطاقة', 'Energy Converter',
      ['طاقة', 'جول', 'كيلوواط', 'سعرة', 'سعرات', 'energy', 'joule', 'kwh', 'calorie'],
      Icons.bolt_outlined, energyUnits),
  _conv('conv_data', 'تحويل البيانات', 'Data Converter',
      ['بيانات', 'بايت', 'ميجا', 'جيجا', 'تخزين', 'data', 'byte', 'mb', 'gb', 'storage'],
      Icons.sd_storage_outlined, dataUnits,
      note: 'الحساب بالنظام الثنائي: 1 كيلوبايت = 1024 بايت'),
  _conv('conv_time', 'تحويل الوقت', 'Time Converter',
      ['وقت', 'ثانية', 'دقيقة', 'ساعة', 'يوم', 'أسبوع', 'time', 'hour', 'minute'],
      Icons.hourglass_bottom, timeUnits),
];
