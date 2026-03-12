import 'package:flutter/material.dart';

class ColorPicker extends StatefulWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSVColor _hsvColor;

  @override
  void initState() {
    super.initState();
    _hsvColor = HSVColor.fromColor(widget.color);
  }

  @override
  void didUpdateWidget(ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      _hsvColor = HSVColor.fromColor(widget.color);
    }
  }

  void _onHueChanged(double hue) {
    setState(() {
      _hsvColor = _hsvColor.withHue(hue);
      widget.onColorChanged(_hsvColor.toColor());
    });
  }

  void _onSaturationValueChanged(Offset localPos, Size size) {
    final saturation = (localPos.dx.clamp(0, size.width)) / size.width;
    final value = 1 - (localPos.dy.clamp(0, size.height)) / size.height;

    setState(() {
      _hsvColor = _hsvColor.withSaturation(saturation).withValue(value);
      widget.onColorChanged(_hsvColor.toColor());
    });
  }

  @override
  Widget build(BuildContext context) {
    final hueColor = HSVColor.fromAHSV(1, _hsvColor.hue, 1, 1).toColor();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selecione a cor', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, 180);
            return GestureDetector(
              onPanDown: (event) =>
                  _onSaturationValueChanged(event.localPosition, size),
              onPanUpdate: (event) =>
                  _onSaturationValueChanged(event.localPosition, size),
              child: Stack(
                children: [
                  Container(
                    width: size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.white, hueColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  Container(
                    width: size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Colors.transparent, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_hsvColor.saturation * size.width) - 10,
                    top: ((1 - _hsvColor.value) * size.height) - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.25 * 255).round()),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 10,
                  trackShape: const RoundedRectSliderTrackShape(),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  thumbColor: HSVColor.fromAHSV(
                    1,
                    _hsvColor.hue,
                    1,
                    1,
                  ).toColor(),
                  overlayColor: Colors.white.withOpacity(0.2),
                ),
                child: Slider(
                  value: _hsvColor.hue,
                  min: 0,
                  max: 360,
                  onChanged: _onHueChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
