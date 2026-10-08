import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_info.dart';
import 'remote_model.dart';
import 'remote_store.dart';

/// بوابة فوق التطبيق: صيانة، إجبار التحديث، وإشعار يظهر مرة واحدة.
class RemoteGate extends StatefulWidget {
  final Widget child;
  const RemoteGate({super.key, required this.child});
  @override
  State<RemoteGate> createState() => _RemoteGateState();
}

class _RemoteGateState extends State<RemoteGate> {
  @override
  void initState() {
    super.initState();
    RemoteStore.config.addListener(_announce);
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void dispose() {
    RemoteStore.config.removeListener(_announce);
    super.dispose();
  }

  Future<void> _announce() async {
    final c = RemoteStore.config.value;
    final a = c?.announcement;
    if (c == null || a == null || !a.enabled) return;
    if (a.title.isEmpty && a.body.isEmpty) return;
    if (c.maintenance.enabled || kAppBuild < c.update.minBuild) return;
    if (await RemoteStore.announcementSeen(a.id)) return;
    if (!mounted) return;
    await RemoteStore.markAnnouncementSeen(a.id);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: a.title.isEmpty ? null : Text(a.title),
        content: a.body.isEmpty ? null : Text(a.body),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسنًا'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RemoteConfig?>(
      valueListenable: RemoteStore.config,
      builder: (context, c, _) {
        if (c != null && c.maintenance.enabled) {
          return _Blocked(
            icon: Icons.build_circle_outlined,
            title: 'التطبيق تحت الصيانة',
            message: c.maintenance.message.isEmpty
                ? 'نعمل على تحسينات سريعة، نعود قريبًا.'
                : c.maintenance.message,
          );
        }
        if (c != null && kAppBuild < c.update.minBuild) {
          return _Blocked(
            icon: Icons.system_update_outlined,
            title: 'يلزم تحديث التطبيق',
            message: c.update.message.isEmpty
                ? 'هذه النسخة لم تعد مدعومة. حدّث التطبيق من Google Play للمتابعة.'
                : c.update.message,
            url: c.update.url,
          );
        }
        // تغيّر رقم النسخة = إعادة بناء الواجهة لتظهر الأدوات والأقسام الجديدة.
        return KeyedSubtree(key: ValueKey(c?.version ?? 0), child: widget.child);
      },
    );
  }
}

class _Blocked extends StatelessWidget {
  final IconData icon;
  final String title, message, url;
  const _Blocked({required this.icon, required this.title, required this.message, this.url = ''});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 72, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: t.textTheme.bodyLarge),
              if (url.isNotEmpty) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  child: const Text('تحديث الآن'),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
