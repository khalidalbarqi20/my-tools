import 'package:flutter/material.dart';
import '../../core/tool.dart';
import '../pdf/single_pdf_tool.dart' show Opt;
import 'crop_page.dart';
import 'image_ops.dart';
import 'image_tool_page.dart';
import 'info_page.dart';
import 'palette_page.dart';
import 'rotate_page.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'image',
      keywords: ['صورة', 'صور', 'image', 'photo', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> imageTools = [
  _t('img_compress', 'ضغط الصور', 'Compress Images',
      ['ضغط', 'تصغير حجم', 'تقليل حجم', 'جودة', 'compress', 'reduce', 'quality', 'size'],
      Icons.compress,
      (_) => ImageToolPage(
            title: 'ضغط الصور',
            actionLabel: 'ضغط',
            run: compressOne,
            summary: true,
            options: const [
              Opt.choice('q', 'الجودة',
                  [('85', 'عالية'), ('70', 'متوسطة'), ('50', 'أعلى ضغط')],
                  initial: '70'),
              Opt.choice('side', 'أقصى بعد للصورة',
                  [('0', 'الأصلي'), ('2048', '2048'), ('1280', '1280')],
                  initial: '0'),
              Opt.choice('fmt', 'الصيغة', [('jpg', 'JPG'), ('webp', 'WebP')],
                  initial: 'jpg'),
            ],
            note: 'يمكنك اختيار حتى 20 صورة دفعة واحدة. إذا كانت الصورة مضغوطة أصلًا قد يكون الناتج أكبر.',
          )),
  _t('img_resize', 'تغيير حجم الصورة', 'Resize Image',
      ['تغيير حجم', 'أبعاد', 'عرض', 'ارتفاع', 'resize', 'scale', 'dimensions'],
      Icons.photo_size_select_large,
      (_) => ImageToolPage(
            title: 'تغيير حجم الصورة',
            actionLabel: 'تغيير الحجم',
            run: resizeOne,
            summary: true,
            options: const [
              Opt.text('w', 'العرض (بكسل)', hint: 'اتركه فارغًا لحسابه تلقائيًا'),
              Opt.text('h', 'الارتفاع (بكسل)', hint: 'اتركه فارغًا لحسابه تلقائيًا'),
              Opt.toggle('keep', 'الحفاظ على النسبة', on: true),
              Opt.choice('fmt', 'الصيغة', [('jpg', 'JPG'), ('png', 'PNG')],
                  initial: 'jpg'),
            ],
            note: 'الحد الأقصى 8000 بكسل للبعد الواحد.',
          )),
  _t('img_convert', 'تحويل صيغة الصور', 'Convert Image Format',
      ['تحويل', 'صيغة', 'jpg', 'png', 'webp', 'convert', 'format'],
      Icons.transform,
      (_) => ImageToolPage(
            title: 'تحويل صيغة الصور',
            actionLabel: 'تحويل',
            run: convertOne,
            options: const [
              Opt.choice('fmt', 'التحويل إلى',
                  [('jpg', 'JPG'), ('png', 'PNG'), ('webp', 'WebP')],
                  initial: 'jpg'),
            ],
            note: 'التحويل إلى JPG يستبدل الشفافية بخلفية سوداء.',
          )),
  _t('img_crop', 'قص الصورة', 'Crop Image', ['قص', 'اقتطاع', 'crop', 'cut'],
      Icons.crop, (_) => const CropPage()),
  _t('img_rotate', 'تدوير وقلب الصورة', 'Rotate & Flip Image',
      ['تدوير', 'قلب', 'عكس', 'rotate', 'flip', 'mirror'],
      Icons.rotate_90_degrees_ccw, (_) => const RotatePage()),
  _t('img_palette', 'استخراج الألوان', 'Color Palette',
      ['ألوان', 'لون', 'لوحة', 'hex', 'palette', 'colors', 'color'],
      Icons.palette_outlined, (_) => const PalettePage()),
  _t('img_info', 'معلومات الصورة', 'Image Info',
      ['معلومات', 'خصائص', 'أبعاد', 'حجم', 'info', 'details', 'metadata'],
      Icons.info_outline, (_) => const ImageInfoPage()),
];
