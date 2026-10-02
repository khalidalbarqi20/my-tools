import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'images_page.dart';
import 'merge_page.dart';
import 'pdf_ops.dart';
import 'pdf_preview_page.dart';
import 'single_pdf_tool.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'pdf',
      keywords: ['pdf', 'بي دي اف', 'ملف', ...kw],
      icon: icon,
      builder: b,
    );

const _rangeNote = 'أمثلة: 1-3,5 تعني الصفحات 1 و2 و3 و5.  8- تعني من الصفحة 8 للنهاية.';

final List<Tool> pdfTools = [
  _t('pdf_merge', 'دمج PDF', 'Merge PDF',
      ['دمج', 'ضم', 'جمع', 'merge', 'combine', 'join'],
      Icons.merge_type, (_) => const MergePage()),
  _t('pdf_split', 'تقسيم PDF', 'Split PDF',
      ['تقسيم', 'فصل', 'قص', 'split'],
      Icons.call_split,
      (_) => SinglePdfTool(
            title: 'تقسيم PDF',
            actionLabel: 'تقسيم',
            run: splitPdf,
            options: const [
              Opt.text('ranges', 'النطاقات', hint: 'مثال: 1-3,4-6 (كل نطاق يصير ملف)'),
              Opt.toggle('every', 'كل صفحة في ملف مستقل'),
            ],
            note: _rangeNote,
          )),
  _t('pdf_extract', 'استخراج وترتيب الصفحات', 'Extract / Reorder Pages',
      ['استخراج', 'ترتيب', 'إعادة ترتيب', 'صفحات', 'extract', 'reorder', 'pages'],
      Icons.content_copy,
      (_) => SinglePdfTool(
            title: 'استخراج وترتيب الصفحات',
            actionLabel: 'استخراج',
            run: extractPages,
            options: const [
              Opt.text('pages', 'أرقام الصفحات',
                  hint: 'مثال: 1-3,5 أو 3,1,2 لإعادة الترتيب'),
            ],
            note: '$_rangeNote\nالصفحات تظهر في الناتج بنفس ترتيب كتابتك، وبدون تكرار.',
          )),
  _t('pdf_delete', 'حذف صفحات PDF', 'Delete PDF Pages',
      ['حذف', 'إزالة', 'مسح', 'delete', 'remove', 'pages'],
      Icons.delete_outline,
      (_) => SinglePdfTool(
            title: 'حذف صفحات PDF',
            actionLabel: 'حذف',
            run: deletePages,
            options: const [
              Opt.text('pages', 'الصفحات المراد حذفها', hint: 'مثال: 2,4-6'),
            ],
            note: _rangeNote,
          )),
  _t('pdf_rotate', 'تدوير صفحات PDF', 'Rotate PDF',
      ['تدوير', 'لف', 'قلب', 'rotate', 'turn'],
      Icons.rotate_right,
      (_) => SinglePdfTool(
            title: 'تدوير صفحات PDF',
            actionLabel: 'تدوير',
            run: rotatePages,
            options: const [
              Opt.choice(
                  'angle',
                  'اتجاه التدوير',
                  [('90', '90° يمين'), ('180', '180°'), ('270', '90° يسار')],
                  initial: '90'),
              Opt.text('pages', 'الصفحات', hint: 'اتركه فارغًا لتدوير كل الصفحات'),
            ],
            note: _rangeNote,
          )),
  _t('pdf_to_images', 'PDF إلى صور', 'PDF to Images',
      ['صور', 'صورة', 'تحويل', 'png', 'image', 'images', 'convert'],
      Icons.photo_library_outlined,
      (_) => SinglePdfTool(
            title: 'PDF إلى صور',
            actionLabel: 'تحويل',
            run: pdfToImages,
            options: const [
              Opt.choice(
                  'dpi',
                  'الجودة',
                  [('100', 'عادية'), ('150', 'جيدة'), ('200', 'عالية')],
                  initial: '150'),
              Opt.text('pages', 'الصفحات', hint: 'اتركه فارغًا لكل الصفحات'),
            ],
            note: 'الحد الأقصى 30 صفحة في كل مرة. الصور تُحفظ بصيغة PNG.',
          )),
  _t('images_to_pdf', 'صور إلى PDF', 'Images to PDF',
      ['صور', 'صورة', 'تحويل', 'jpg', 'png', 'image', 'images', 'convert'],
      Icons.picture_as_pdf_outlined, (_) => const ImagesToPdfPage()),
  _t('pdf_preview', 'معاينة PDF', 'PDF Viewer',
      ['معاينة', 'عرض', 'قراءة', 'فتح', 'view', 'preview', 'open', 'reader'],
      Icons.visibility_outlined, (_) => const PdfPreviewPage()),
];
