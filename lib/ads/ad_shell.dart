import 'package:flutter/material.dart';
import '../billing/billing.dart';
import '../remote/remote_store.dart';
import 'ad_policy.dart';
import 'ads.dart';

/// يغلّف صفحة الأداة: بانر صغير أسفل الصفحة (لا فوق المحتوى أو النتائج)،
/// ويختفي عند ظهور لوحة المفاتيح أو في الأدوات المستثناة أو لمن اشترك بإزالة الإعلانات.
class AdShell extends StatelessWidget {
  final String toolId;
  final Widget child;
  const AdShell({super.key, required this.toolId, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Billing.adFree, RemoteStore.config]),
      builder: (context, _) {
        final free = Billing.adFree.value;
        final r = RemoteStore.config.value;
        final allowed = Ads.ready &&
            !free &&
            !noAdTools.contains(toolId) &&
            (r?.ads.banner ?? true) &&
            !(r?.noAdTools.contains(toolId) ?? false);
        final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: allowed && !keyboard,
                child: child,
              ),
            ),
            if (allowed)
              Visibility(
                visible: !keyboard,
                maintainState: true,
                child: SafeArea(top: false, child: Ads.banner()),
              ),
          ]),
        );
      },
    );
  }
}
