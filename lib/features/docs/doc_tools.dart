import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'invoice_page.dart';
import 'scan_page.dart';

final List<Tool> docTools = [
  Tool(
    id: 'pdf_scan',
    nameAr: 'ماسح المستندات',
    nameEn: 'Document Scanner',
    category: 'pdf',
    keywords: ['مسح', 'ماسح', 'سكانر', 'تصوير', 'ورقة', 'مستند', 'scan', 'scanner', 'document', 'camera', 'pdf'],
    icon: Icons.document_scanner_outlined,
    builder: (_) => const ScanPage(),
  ),
  Tool(
    id: 'pdf_invoice',
    nameAr: 'مولد فاتورة PDF',
    nameEn: 'Invoice Generator',
    category: 'pdf',
    keywords: ['فاتورة', 'ايصال', 'إيصال', 'ضريبة', 'invoice', 'receipt', 'bill', 'vat', 'pdf'],
    icon: Icons.receipt_long_outlined,
    builder: (_) => const InvoicePage(),
  ),
];
