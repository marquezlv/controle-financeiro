import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class CategoryPieChart extends StatefulWidget {
  final List<double> values;
  final List<Color> colors;
  final List<String>? labels;
  final double size;
  final String? centerText;
  final TextStyle? centerTextStyle;
  final Duration tooltipDuration;

  const CategoryPieChart({
    super.key,
    required this.values,
    required this.colors,
    this.labels,
    this.size = 160,
    this.centerText,
    this.centerTextStyle,
    this.tooltipDuration = const Duration(seconds: 2),
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int? _activeIndex;
  Offset? _tapPosition;
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  int? _hitTestSlice(Offset localPosition, Size size, double strokeWidth) {
    final total = widget.values.fold<double>(0, (prev, val) => prev + val);
    if (total == 0) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final offset = localPosition - center;
    final distance = offset.distance;
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius - strokeWidth;

    if (distance < innerRadius || distance > outerRadius) return null;

    var angle = atan2(offset.dy, offset.dx);
    angle += pi / 2;
    if (angle < 0) angle += 2 * pi;

    double startAngle = 0;
    for (var i = 0; i < widget.values.length; i++) {
      final sweep = (widget.values[i] / total) * 2 * pi;
      if (angle >= startAngle && angle < startAngle + sweep) return i;
      startAngle += sweep;
    }
    return null;
  }

  void _showTooltip(int index, Offset localPosition) {
    _tooltipTimer?.cancel();
    setState(() {
      _activeIndex = index;
      _tapPosition = localPosition;
    });
    _tooltipTimer = Timer(widget.tooltipDuration, () {
      if (mounted) setState(() { _activeIndex = null; _tapPosition = null; });
    });
  }

  void _hideTooltip() {
    _tooltipTimer?.cancel();
    setState(() { _activeIndex = null; _tapPosition = null; });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.values.fold<double>(0, (prev, val) => prev + val);

    if (total == 0) {
      return Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        child: Text('Sem dados', style: TextStyle(color: Colors.grey[600])),
      );
    }

    final strokeWidth = widget.size * 0.18;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final index = _hitTestSlice(
              details.localPosition, Size(widget.size, widget.size), strokeWidth);
          if (index == null) { _hideTooltip(); return; }
          _showTooltip(index, details.localPosition);
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _PieChartPainter(
                values: widget.values,
                colors: widget.colors,
                strokeWidth: strokeWidth,
              ),
            ),
            if (widget.centerText != null)
              Text(
                widget.centerText!,
                textAlign: TextAlign.center,
                style: widget.centerTextStyle ??
                    TextStyle(
                      fontSize: widget.size * 0.10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            if (_activeIndex != null && _tapPosition != null)
              _buildTooltip(context, _activeIndex!, _tapPosition!, total, strokeWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltip(
      BuildContext context, int index, Offset tapPos, double total, double strokeWidth) {
    final label = (widget.labels != null && index < widget.labels!.length)
        ? widget.labels![index]
        : 'Item ${index + 1}';
    final percent = (widget.values[index] / total) * 100;

    const tooltipWidth = 140.0;
    const tooltipHeight = 48.0;

    final left = (tapPos.dx - tooltipWidth / 2).clamp(0.0, widget.size - tooltipWidth);
    final placeAbove = tapPos.dy > (widget.size / 2);
    final top = (placeAbove ? tapPos.dy - tooltipHeight - 8 : tapPos.dy + 8)
        .clamp(0.0, widget.size - tooltipHeight);

    return Positioned(
      left: left,
      top: top,
      width: tooltipWidth,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(10),
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  _PieChartPainter({
    required this.values,
    required this.colors,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (prev, val) => prev + val);
    if (total == 0) return;

    final rect = Rect.fromLTWH(
        strokeWidth / 2, strokeWidth / 2,
        size.width - strokeWidth, size.height - strokeWidth);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
