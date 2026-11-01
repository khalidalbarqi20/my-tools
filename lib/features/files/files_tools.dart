import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'barcode_page.dart';
import 'md_page.dart';
import 'meta_page.dart';
import 'zip_page.dart';

final List<Tool> filesTools = [
  Tool(
    id: 'img_exif',
    nameAr: 'حذف بيانات الصور (EXIF)',
    nameEn: 'Remove Photo Metadata',
    category: 'image',
    keywords: ['exif', 'موقع', 'خصوصية', 'بيانات', 'gps', 'metadata', 'privacy', 'location', 'strip'],
    icon: Icons.privacy_tip_outlined,
    builder: (_) => const MetaPage(),
  ),
  Tool(
    id: 'conv_zip',
    nameAr: 'ضغط وفك ZIP',
    nameEn: 'ZIP Compress & Extract',
    category: 'convert',
    keywords: ['zip', 'ضغط', 'فك', 'أرشيف', 'ارشيف', 'مضغوط', 'compress', 'extract', 'unzip', 'archive'],
    icon: Icons.folder_zip_outlined,
    builder: (_) => const ZipPage(),
  ),
  Tool(
    id: 'qr_barcode',
    nameAr: 'مولد الباركود',
    nameEn: 'Barcode Generator',
    category: 'qr',
    keywords: ['باركود', 'شريط', 'barcode', 'code128', 'ean', 'ean13', 'upc', 'generate'],
    icon: Icons.view_week_outlined,
    builder: (_) => const BarcodePage(),
  ),
  Tool(
    id: 'text_markdown',
    nameAr: 'قارئ ومحرر Markdown',
    nameEn: 'Markdown Reader & Editor',
    category: 'text',
    keywords: ['markdown', 'md', 'ماركداون', 'تنسيق', 'محرر', 'readme', 'editor', 'preview'],
    icon: Icons.article_outlined,
    builder: (_) => const MarkdownPage(),
  ),
];
