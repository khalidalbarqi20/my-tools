import 'package:flutter/widgets.dart';

class MediaPreview extends StatelessWidget {
  final String path;
  final bool video, gif;
  const MediaPreview({super.key, required this.path, required this.video, this.gif = false});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class TrimPicker extends StatelessWidget {
  final String path;
  final bool video;
  final void Function(double start, double? end) onChanged;
  const TrimPicker({super.key, required this.path, required this.video, required this.onChanged});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
