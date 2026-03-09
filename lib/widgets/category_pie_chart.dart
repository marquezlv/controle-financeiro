import 'dart:math';

import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final List<double> values;
  final List<Color> colors;
  final double size;

  const CategoryPieChart({
    super.key,
    required this.values,
    required this.colors,
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<double>(0, (prev, val) => prev + val);

    if (total == 0) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(
          'Sem dados',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PieChartPainter(values: values, colors: colors),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _PieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.fill;

    final total = values.fold<double>(0, (prev, val) => prev + val);
    if (total == 0) return;

    double startAngle = -pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
