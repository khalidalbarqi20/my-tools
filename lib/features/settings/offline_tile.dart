import 'package:flutter/material.dart';
import 'offline_engines.dart';

/// «تنزيل المحركات للعمل بدون إنترنت» — يظهر في نسخة الويب فقط.
class OfflineEnginesTile extends StatefulWidget {
  const OfflineEnginesTile({super.key});
  @override
  State<OfflineEnginesTile> createState() => _OfflineEnginesTileState();
}

class _OfflineEnginesTileState extends State<OfflineEnginesTile> {
  bool _busy = false;

  Future<void> _run() async {
    final model = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تنزيل للعمل بدون إنترنت'),
        content: const Text(
            'محرك الفيديو والصوت حجمه نحو ٣٠ ميجابايت. إزالة الخلفية تحتاج نموذجًا إضافيًا بحجم نحو ٤٥ ميجابايت. اختر ما تريد تنزيله (يفضّل أن تكون على واي فاي).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('الفيديو فقط')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('الكل')),
        ],
      ),
    );
    if (model == null) return;
    setState(() => _busy = true);
    String msg;
    try {
      await prefetchEngines(withModel: model);
      msg = 'تم التنزيل، الأدوات الثقيلة تعمل الآن بدون إنترنت';
    } catch (_) {
      msg = 'تعذر التنزيل. تأكد من الاتصال وحاول مرة أخرى.';
    }
    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!offlineSupported) return const SizedBox.shrink();
    return ListTile(
      leading: _busy
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_for_offline_outlined),
      title: const Text('تنزيل المحركات للعمل بدون إنترنت'),
      subtitle: const Text('الفيديو والصوت وإزالة الخلفية'),
      onTap: _busy ? null : _run,
    );
  }
}
