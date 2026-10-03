import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'qr_generate_page.dart';
import 'qr_scan_page.dart';

final List<Tool> qrTools = [
  Tool(
    id: 'qr_scan',
    nameAr: 'قارئ QR والباركود',
    nameEn: 'QR & Barcode Scanner',
    category: 'qr',
    keywords: ['qr', 'كيو ار', 'باركود', 'مسح', 'قراءة', 'ماسح', 'كاميرا', 'scan', 'scanner', 'barcode', 'camera'],
    icon: Icons.qr_code_scanner,
    builder: (_) => const QrScanPage(),
  ),
  Tool(
    id: 'qr_generate',
    nameAr: 'مولد QR',
    nameEn: 'QR Generator',
    category: 'qr',
    keywords: ['qr', 'كيو ار', 'انشاء', 'إنشاء', 'توليد', 'رمز', 'واي فاي', 'wifi', 'generate', 'create', 'code'],
    icon: Icons.qr_code_2,
    builder: (_) => const QrGeneratePage(),
  ),
];
