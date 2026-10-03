import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'qr_logic.dart';

IconData _icon(QrKind k) => switch (k) {
      QrKind.url => Icons.link,
      QrKind.wifi => Icons.wifi,
      QrKind.email => Icons.mail_outline,
      QrKind.phone => Icons.call_outlined,
      QrKind.sms => Icons.sms_outlined,
      QrKind.contact => Icons.person_outline,
      QrKind.text => Icons.notes,
    };

class QrResultSheet extends StatelessWidget {
  final QrParsed p;
  final bool isQr;
  const QrResultSheet({super.key, required this.p, required this.isQr});

  void _toast(BuildContext context, String m) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _open(BuildContext context) async {
    final u = p.openUri;
    if (u == null) return;
    var ok = false;
    try {
      ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) _toast(context, 'تعذر الفتح');
  }

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(ShareParams(text: p.raw));
    } catch (_) {
      _toast(context, 'تعذر فتح قائمة المشاركة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final title = (!isQr && p.kind == QrKind.text) ? 'باركود' : kindTitle(p.kind);
    final openLabel = p.openLabel;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon(p.kind), color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: t.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in p.rows) ...[
                        Text(r.$1,
                            style: t.textTheme.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                        SelectableText(r.$2,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: p.copyText));
                    _toast(context, 'تم النسخ');
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(p.copyLabel == 'نسخ' ? 'نسخ' : 'نسخ المهم'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('مشاركة'),
                ),
              ),
              if (openLabel != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _open(context),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(openLabel),
                  ),
                ),
              ],
            ]),
            if (p.copyLabel != 'نسخ')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('زر النسخ ينسخ: ${p.copyLabel.replaceFirst('نسخ ', '')}',
                    style: t.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}
