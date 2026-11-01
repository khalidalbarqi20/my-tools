import 'package:flutter/foundation.dart' show kIsWeb;
import 'platform_info.dart';
import 'platform_rules.dart';

/// المنصة الحالية.
Plat get currentPlat => !kIsWeb ? Plat.app : (isIosWeb ? Plat.iosWeb : Plat.web);

bool isToolSupported(String id) => supportedOn(id, currentPlat);

String? toolCaution(String id) => cautionOn(id, currentPlat);
