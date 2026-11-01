import 'package:flutter/material.dart';
import '../../core/tool.dart';
import 'network_pages.dart';

Tool _t(String id, String ar, String en, List<String> kw, IconData icon,
        WidgetBuilder b) =>
    Tool(
      id: id,
      nameAr: ar,
      nameEn: en,
      category: 'network',
      keywords: ['شبكة', 'انترنت', 'إنترنت', 'network', 'internet', ...kw],
      icon: icon,
      builder: b,
    );

final List<Tool> networkTools = [
  _t('net_ip', 'عنوان IP وموقعي', 'My IP & Location',
      ['ايبي', 'عنوان', 'موقع', 'مزود', 'ip', 'location', 'isp', 'address'],
      Icons.public, (_) => const IpPage()),
  _t('net_ping', 'زمن الاستجابة والتذبذب', 'Latency & Jitter',
      ['بنق', 'تأخير', 'تذبذب', 'ping', 'latency', 'jitter', 'lag'],
      Icons.network_ping, (_) => const PingPage()),
  _t('net_speed', 'سرعة الإنترنت', 'Speed Test',
      ['سرعة', 'تحميل', 'رفع', 'speed', 'download', 'upload', 'bandwidth'],
      Icons.speed, (_) => const SpeedPage()),
  _t('net_dns', 'استعلام DNS', 'DNS Lookup',
      ['نطاق', 'دومين', 'سجلات', 'dns', 'domain', 'mx', 'txt', 'nslookup'],
      Icons.dns_outlined, (_) => const DnsPage()),
  _t('net_site', 'هل الموقع شغال؟', 'Is Site Up?',
      ['موقع', 'يعمل', 'شغال', 'فحص', 'site', 'website', 'up', 'down', 'status'],
      Icons.travel_explore, (_) => const SiteCheckPage()),
];
