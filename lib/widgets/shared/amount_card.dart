import 'package:flutter/material.dart';

class AmountCard extends StatelessWidget {
  final String title;
  final String amount;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? amountColor;
  final double? amountFontSize;

  const AmountCard({
    super.key,
    required this.title,
    required this.amount,
    this.gradient,
    this.backgroundColor,
    this.titleColor,
    this.amountColor,
    this.amountFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = gradient == null ? (backgroundColor ?? Colors.white) : null;
    final computedTitleColor = titleColor ??
        (gradient != null
            ? Colors.white70
            : (bgColor?.computeLuminance() ?? 1) > 0.5
                ? Colors.black87
                : Colors.white70);
    final computedAmountColor = amountColor ??
        (gradient != null
            ? Colors.white
            : (bgColor?.computeLuminance() ?? 1) > 0.5
                ? Colors.black
                : Colors.white);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: computedTitleColor)),
          const SizedBox(height: 10),
          Text(amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: amountFontSize ?? 26,
                  fontWeight: FontWeight.bold,
                  color: computedAmountColor)),
        ],
      ),
    );
  }
}
