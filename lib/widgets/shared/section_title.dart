import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final TextAlign textAlign;

  const SectionTitle({
    super.key,
    required this.title,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
