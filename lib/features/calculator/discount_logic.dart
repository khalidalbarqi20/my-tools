import '../../core/num_parse.dart';

class DiscountResult {
  final double original, discount, finalPrice;
  const DiscountResult(this.original, this.discount, this.finalPrice);
}

/// يرجع null إذا كان الإدخال غير صالح.
DiscountResult? calcDiscount(String price, String percent) {
  final p = parseNum(price);
  final d = parseNum(percent);
  if (p == null || d == null || p < 0 || d < 0 || d > 100) return null;
  final disc = p * d / 100;
  return DiscountResult(p, disc, p - disc);
}
