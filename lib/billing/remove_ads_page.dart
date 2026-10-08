import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/display_card.dart';
import 'billing.dart';
import 'billing_logic.dart';

class RemoveAdsPage extends StatefulWidget {
  const RemoveAdsPage({super.key});
  @override
  State<RemoveAdsPage> createState() => _RemoveAdsPageState();
}

class _RemoveAdsPageState extends State<RemoveAdsPage> {
  List<AdFreeOffer> _offers = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Billing.message.value = null;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final o = await Billing.loadOffers();
    if (!mounted) return;
    setState(() {
      _offers = o;
      _loading = false;
    });
  }

  Future<void> _manage() async {
    try {
      await launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions'),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final cs = t.colorScheme;
    final muted = t.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('إزالة الإعلانات')),
      body: ListenableBuilder(
        listenable: Listenable.merge([Billing.adFree, Billing.busy, Billing.message]),
        builder: (context, _) {
          final free = Billing.adFree.value;
          final busy = Billing.busy.value;
          final msg = Billing.message.value;
          return ListView(padding: const EdgeInsets.all(20), children: [
            DisplayCard(
              child: Column(children: [
                Icon(free ? Icons.check_circle_outline : Icons.block,
                    size: 56, color: cs.primary),
                const SizedBox(height: 12),
                Text(free ? 'الإعلانات مزالة' : 'استمتع بتطبيق بدون إعلانات',
                    textAlign: TextAlign.center,
                    style: t.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  free
                      ? 'شكرًا لدعمك، يساعدنا على تطوير التطبيق وإضافة أدوات جديدة.'
                      : 'بدون بانر ولا إعلانات بينية في كل الأدوات، ودعم لاستمرار تطوير التطبيق.',
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            if (msg != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(msg, textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
              ),
            if (!Billing.supported)
              Text('الاشتراك متاح في تطبيق أندرويد المثبّت من Google Play فقط.',
                  textAlign: TextAlign.center, style: muted)
            else if (free) ...[
              OutlinedButton.icon(
                onPressed: _manage,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('إدارة الاشتراك أو إلغاؤه'),
              ),
              const SizedBox(height: 8),
              Text('الإدارة من Google Play: الملف الشخصي ثم المدفوعات والاشتراكات ثم الاشتراكات.',
                  textAlign: TextAlign.center, style: muted),
            ] else ...[
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_offers.isEmpty) ...[
                Text(
                  'الاشتراك غير متاح حاليًا. تأكد من اتصالك بالإنترنت، ومن أن التطبيق مثبّت من Google Play.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
              ] else
                for (final o in _offers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton(
                      onPressed: busy ? null : () => Billing.buy(o),
                      child: Text('اشترك: ${o.price}'),
                    ),
                  ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: busy ? null : Billing.restore,
                child: const Text('استعادة اشتراك سابق'),
              ),
              const SizedBox(height: 12),
              Text(
                'الاشتراك يتجدد تلقائيًا في نهاية كل فترة حتى تلغيه، ويُحاسَب من حسابك في Google Play. '
                'تلغيه في أي وقت من Google Play قبل موعد التجديد لتجنّب الرسوم التالية. '
                'بدون الاشتراك يبقى التطبيق مجانيًا بالكامل مع الإعلانات.',
                style: muted,
              ),
            ],
          ]);
        },
      ),
    );
  }
}
