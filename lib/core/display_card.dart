import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DisplayCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const DisplayCard(
      {super.key, required this.child, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: softBorder(context)),
      ),
      child: child,
    );
  }
}

class TimeRing extends StatelessWidget {
  final double value;
  final Color color;
  final Widget child;
  const TimeRing(
      {super.key, required this.value, required this.color, required this.child});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            strokeWidth: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
        child,
      ]),
    );
  }
}
