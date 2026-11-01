import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_info.dart';

const _kDone = 'ios_install_done';

/// يظهر في الرئيسية لمستخدم آيفون/آيباد داخل المتصفح فقط، ويشرح طريقة تثبيت التطبيق.
class IosInstallBanner extends StatefulWidget {
  const IosInstallBanner({super.key});
  @override
  State<IosInstallBanner> createState() => _IosInstallBannerState();
}

class _IosInstallBannerState extends State<IosInstallBanner> {
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (!kIsWeb || !isIosWeb || isStandalone) return;
    try {
      final p = await SharedPreferences.getInstance();
      if (p.getBool(_kDone) == true) return;
    } catch (_) {}
    if (mounted) setState(() => _show = true);
  }

  Future<void> _dismiss() async {
    setState(() => _show = false);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_kDone, true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final t = Theme.of(context);
    final cs = t.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.ios_share, color: cs.onPrimaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text('ثبّت التطبيق على جهازك',
                  style: t.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800, color: cs.onPrimaryContainer)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
              '١) اضغط زر المشاركة في Safari (المربع والسهم للأعلى).\n'
              '٢) اختر «إضافة إلى الشاشة الرئيسية».\n'
              '٣) افتح التطبيق من أيقونته، فيشتغل بشاشة كاملة وبدون شريط المتصفح.',
              style: t.textTheme.bodyMedium
                  ?.copyWith(color: cs.onPrimaryContainer, height: 1.6)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: _dismiss, child: const Text('فهمت')),
          ),
        ]),
      ),
    );
  }
}
