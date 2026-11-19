import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Renders the structured visual aids that accompany questions.
///
/// The server only sends a small, typed description (for example
/// `{'type': 'fraction_bar', 'data': {'numerator': 3, 'denominator': 4}}`),
/// so visuals are safe to serialise and fast to draw.
class MathVisual extends StatelessWidget {
  const MathVisual({
    super.key,
    required this.type,
    required this.data,
    this.height = 150,
    this.dark = false,
    this.scale = 1,
  });

  final String type;
  final Map<String, dynamic> data;
  final double height;
  final bool dark;

  /// Enlarges object/array pictures for younger children without changing
  /// the layout of the other visual types.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final visual = _build();
    if (visual == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.045),
                AppColors.surface,
              ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.25)
              : AppColors.outline,
          width: 1.5,
        ),
      ),
      child: Center(child: visual),
    );
  }

  int _int(String key, [int fallback = 0]) {
    final value = data[key];
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  List<int> _intList(String key) {
    final value = data[key];
    if (value is List) {
      return value
          .map(
            (item) => item is num ? item.toInt() : int.tryParse('$item') ?? 0,
          )
          .where((item) => item > 0)
          .toList(growable: false);
    }
    return const [];
  }

  Widget? _build() {
    switch (type) {
      case 'objects':
        return _ObjectsVisual(
          emoji: '${data['emoji'] ?? '🍎'}',
          groups: _intList('groups'),
          operator: '${data['operator'] ?? ''}',
          scale: scale,
        );
      case 'array':
        return _ArrayVisual(
          rows: _int('rows', 1),
          cols: _int('cols', 1),
          emoji: '${data['emoji'] ?? '🍬'}',
          scale: scale,
        );
      case 'number_line':
        return _NumberLineVisual(
          min: _int('min', 0),
          max: math.max(_int('max', 10), _int('min', 0) + 1),
          start: _int('start'),
          jump: _int('jump'),
          scale: scale,
        );
      case 'fraction_bar':
        return _FractionBarVisual(
          numerator: _int('numerator', 1),
          denominator: math.max(_int('denominator', 4), 2),
        );
      case 'shape':
        return _ShapeVisual(
          shape: '${data['shape'] ?? 'square'}',
          width: _int('width', 0),
          heightValue: _int('height', 0),
          scale: scale,
        );
      case 'volume':
        return _VolumeVisual(
          length: _int('length', 3),
          width: _int('width', 2),
          heightValue: _int('height', 2),
        );
      case 'coordinate':
        return _CoordinateVisual(x: _int('x'), y: _int('y'));
      case 'angle':
        return _AngleVisual(degrees: _int('degrees', 90));
      case 'ruler':
        return _RulerVisual(
          blue: _int('blue', 5),
          red: _int('red', 3),
          unit: '${data['unit'] ?? 'units'}',
        );
      case 'clock':
        return _ClockVisual(hour: _int('hour'), minute: _int('minute'));
      case 'base_ten':
        return _BaseTenVisual(
          hundreds: _int('hundreds'),
          tens: _int('tens'),
          ones: _int('ones'),
        );
      case 'bar_model':
        return _BarModelVisual(
          parts: _intList('parts'),
          total: _int('total', 10),
        );
      default:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Objects and arrays
// ---------------------------------------------------------------------------

class _ObjectsVisual extends StatelessWidget {
  const _ObjectsVisual({
    required this.emoji,
    required this.groups,
    required this.operator,
    required this.scale,
  });

  final String emoji;
  final List<int> groups;
  final String operator;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final shown = groups.isEmpty ? const [3] : groups;
    final glow = AppColors.forAvatar('#FFCA00');
    final emojiSize = (20 * scale).clamp(20.0, 40.0);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10 * scale,
      runSpacing: 10 * scale,
      children: [
        for (var index = 0; index < shown.length; index++) ...[
          if (index > 0 && operator.isNotEmpty && operator != 'vs')
            Text(
              operator,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.inkSoft,
                fontSize: 20 * scale,
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 8 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(
                color: glow.withValues(alpha: 0.35),
                width: 1.5 * scale,
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2 * scale,
              runSpacing: 2 * scale,
              children: [
                for (var i = 0; i < shown[index].clamp(1, 20); i++)
                  Text(
                    emoji,
                    style: TextStyle(fontSize: emojiSize, height: 1.2),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ArrayVisual extends StatelessWidget {
  const _ArrayVisual({
    required this.rows,
    required this.cols,
    required this.emoji,
    required this.scale,
  });

  final int rows;
  final int cols;
  final String emoji;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final safeRows = rows.clamp(1, 6);
    final safeCols = cols.clamp(1, 6);
    final size = (safeCols > 4 ? 17.0 : 22.0) * scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < safeRows; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var col = 0; col < safeCols; col++)
                Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: Text(
                    emoji,
                    style: TextStyle(fontSize: size, height: 1.1),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          '$safeRows × $safeCols',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Number line
// ---------------------------------------------------------------------------

class _NumberLineVisual extends StatelessWidget {
  const _NumberLineVisual({
    required this.min,
    required this.max,
    required this.start,
    required this.jump,
    required this.scale,
  });

  final int min;
  final int max;
  final int start;
  final int jump;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: (84 * scale).clamp(84.0, 140.0),
      width: double.infinity,
      child: CustomPaint(
        painter: _NumberLinePainter(
          min: min,
          max: max,
          start: start,
          jump: jump,
        ),
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({
    required this.min,
    required this.max,
    required this.start,
    required this.jump,
  });

  final int min;
  final int max;
  final int start;
  final int jump;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 16.0;
    final y = size.height * 0.58;
    final width = size.width - pad * 2;
    final range = math.max(max - min, 1);
    double xFor(int value) => pad + width * (value - min) / range;

    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pad, y), Offset(size.width - pad, y), line);

    final step = range <= 10 ? 1 : (range / 10).ceil();
    final tick = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1.6;
    for (var value = min; value <= max; value += step) {
      final x = xFor(value);
      canvas.drawLine(Offset(x, y - 5), Offset(x, y + 5), tick);
      _label(canvas, '$value', Offset(x, y + 12), 9, AppColors.inkSoft);
    }

    final startX = xFor(start.clamp(min, max));
    final endX = xFor((start + jump).clamp(min, max));
    final arrow = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final startPoint = Offset(startX, y - 6);
    final endPoint = Offset(endX, y - 6);
    final midY = y - 34;
    final path = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..quadraticBezierTo(
        (startPoint.dx + endPoint.dx) / 2,
        midY,
        endPoint.dx,
        endPoint.dy,
      );
    canvas.drawPath(path, arrow);
    canvas.drawCircle(startPoint, 5.5, Paint()..color = AppColors.primary);
    canvas.drawCircle(endPoint, 5.5, Paint()..color = AppColors.mintDark);

    final label = jump >= 0 ? '+$jump' : '$jump';
    _label(
      canvas,
      label,
      Offset((startPoint.dx + endPoint.dx) / 2, midY - 15),
      11,
      AppColors.primary,
      centered: true,
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset position,
    double size,
    Color color, {
    bool centered = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        position.dx - (centered ? painter.width / 2 : 0),
        position.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_NumberLinePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Fractions and bar models
// ---------------------------------------------------------------------------

class _FractionBarVisual extends StatelessWidget {
  const _FractionBarVisual({
    required this.numerator,
    required this.denominator,
  });

  final int numerator;
  final int denominator;

  @override
  Widget build(BuildContext context) {
    final safeDenominator = denominator.clamp(2, 12);
    final shaded = numerator.clamp(0, safeDenominator);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Row(
            children: [
              for (var i = 0; i < safeDenominator; i++)
                Expanded(
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: i < shaded ? AppColors.primary : AppColors.surface,
                      border: Border(
                        right: i == safeDenominator - 1
                            ? BorderSide.none
                            : BorderSide(color: AppColors.outline, width: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$numerator / $denominator',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.primaryDark),
        ),
      ],
    );
  }
}

class _BarModelVisual extends StatelessWidget {
  const _BarModelVisual({required this.parts, required this.total});

  final List<int> parts;
  final int total;

  @override
  Widget build(BuildContext context) {
    final known = parts.isEmpty ? 0 : parts.first;
    final segments = [
      (value: known, shaded: true),
      (value: math.max(total - known, 0), shaded: false),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (final segment in segments)
              Expanded(
                flex: math.max(segment.value, 1),
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: segment.shaded
                        ? AppColors.yellow
                        : AppColors.surfaceSoft,
                    border: Border.all(color: AppColors.outline, width: 1.5),
                  ),
                  child: Text(
                    segment.shaded ? '${segment.value}' : '?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Total: $total',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shapes, volume, coordinates and angles
// ---------------------------------------------------------------------------

class _ShapeVisual extends StatelessWidget {
  const _ShapeVisual({
    required this.shape,
    required this.width,
    required this.heightValue,
    required this.scale,
  });

  final String shape;
  final int width;
  final int heightValue;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final ratio = (width > 0 && heightValue > 0)
        ? (width / heightValue).clamp(0.4, 2.5)
        : 1.0;
    return SizedBox(
      height: (110 * scale).clamp(110.0, 180.0),
      width: (220 * (1 + (scale - 1) * 0.25)).clamp(220.0, 300.0),
      child: CustomPaint(
        painter: _ShapePainter(shape: shape, ratio: ratio.toDouble()),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.shape, required this.ratio});

  final String shape;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = Color.alphaBlend(
        AppColors.primary.withValues(alpha: 0.18),
        AppColors.surface,
      )
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final rawRadius = math.min(size.width, size.height) / 2 - 8;
    final radius = rawRadius * math.min(1, ratio <= 1 ? ratio + 0.35 : 1);
    final rect = Rect.fromCenter(
      center: center,
      width: math.min(size.width - 16, radius * 2 * ratio),
      height: math.min(size.height - 16, radius * 2),
    );

    switch (shape) {
      case 'circle':
        final radius = math.min(size.width, size.height) / 2 - 10;
        canvas.drawCircle(center, radius, fill);
        canvas.drawCircle(center, radius, stroke);
        break;
      case 'rectangle':
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(rounded, fill);
        canvas.drawRRect(rounded, stroke);
        break;
      case 'triangle':
        final h = rect.height;
        final path = Path()
          ..moveTo(center.dx, rect.top)
          ..lineTo(rect.right, rect.top + h)
          ..lineTo(rect.left, rect.top + h)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 'pentagon':
        _polygon(canvas, center, rect.width * 0.48, 5, fill, stroke);
        break;
      case 'hexagon':
        _polygon(canvas, center, rect.width * 0.5, 6, fill, stroke);
        break;
      default:
        final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(rounded, fill);
        canvas.drawRRect(rounded, stroke);
        break;
    }
  }

  void _polygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / sides;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) => true;
}

class _VolumeVisual extends StatelessWidget {
  const _VolumeVisual({
    required this.length,
    required this.width,
    required this.heightValue,
  });

  final int length;
  final int width;
  final int heightValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 210,
      child: CustomPaint(
        painter: _VolumePainter(
          length: length,
          width: width,
          height: heightValue,
        ),
      ),
    );
  }
}

class _VolumePainter extends CustomPainter {
  _VolumePainter({
    required this.length,
    required this.width,
    required this.height,
  });

  final int length;
  final int width;
  final int height;

  @override
  void paint(Canvas canvas, Size size) {
    final depth = 28.0;
    final front = Rect.fromLTWH(
      16,
      34,
      size.width - depth - 40,
      size.height - depth - 44,
    );
    final top = Path()
      ..moveTo(front.left, front.top)
      ..lineTo(front.left + depth, front.top - depth)
      ..lineTo(front.right + depth, front.top - depth)
      ..lineTo(front.right, front.top)
      ..close();
    final side = Path()
      ..moveTo(front.right, front.top)
      ..lineTo(front.right + depth, front.top - depth)
      ..lineTo(front.right + depth, front.bottom - depth)
      ..lineTo(front.right, front.bottom)
      ..close();

    final fill = Paint()
      ..color = Color.alphaBlend(
        AppColors.mint.withValues(alpha: 0.22),
        AppColors.surface,
      );
    final stroke = Paint()
      ..color = AppColors.mintDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawPath(top, fill);
    canvas.drawPath(side, fill);
    canvas.drawRect(front, fill);
    canvas.drawPath(top, stroke);
    canvas.drawPath(side, stroke);
    canvas.drawRect(front, stroke);

    _label(canvas, '${length}u', Offset(front.center.dx, front.bottom + 12));
    _label(canvas, '${width}u', Offset(front.left - 12, front.center.dy));
    _label(canvas, '${height}u', Offset(front.right + 20, front.center.dy));
  }

  void _label(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.mintDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_VolumePainter oldDelegate) => true;
}

class _CoordinateVisual extends StatelessWidget {
  const _CoordinateVisual({required this.x, required this.y});

  final int x;
  final int y;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 150,
      child: CustomPaint(
        painter: _CoordinatePainter(x: x, y: y),
      ),
    );
  }
}

class _CoordinatePainter extends CustomPainter {
  _CoordinatePainter({required this.x, required this.y});

  final int x;
  final int y;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 22.0;
    final grid = size.width - pad;
    final step = grid / 5;
    final axis = Paint()
      ..color = AppColors.inkSoft
      ..strokeWidth = 1.4;
    final gridLine = Paint()
      ..color = AppColors.outline
      ..strokeWidth = 1;

    for (var i = 0; i <= 5; i++) {
      final offset = pad + step * i;
      canvas.drawLine(
        Offset(offset, 6),
        Offset(offset, size.height - pad),
        gridLine,
      );
      canvas.drawLine(
        Offset(pad, size.height - pad - step * i),
        Offset(size.width - 6, size.height - pad - step * i),
        gridLine,
      );
    }
    canvas.drawLine(Offset(pad, 6), Offset(pad, size.height - pad), axis);
    canvas.drawLine(
      Offset(pad, size.height - pad),
      Offset(size.width - 6, size.height - pad),
      axis,
    );

    final safeX = x.clamp(0, 5);
    final safeY = y.clamp(0, 5);
    final point = Offset(pad + step * safeX, size.height - pad - step * safeY);
    canvas.drawCircle(point, 6, Paint()..color = AppColors.pink);
    canvas.drawCircle(
      point,
      6,
      Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final painter = TextPainter(
      text: TextSpan(
        text: '($safeX, $safeY)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.pinkDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        (point.dx + 10 + painter.width > size.width)
            ? point.dx - painter.width - 8
            : point.dx + 10,
        point.dy - painter.height - 8,
      ),
    );
  }

  @override
  bool shouldRepaint(_CoordinatePainter oldDelegate) => true;
}

class _AngleVisual extends StatelessWidget {
  const _AngleVisual({required this.degrees});

  final int degrees;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: 180,
      child: CustomPaint(painter: _AnglePainter(degrees: degrees)),
    );
  }
}

class _AnglePainter extends CustomPainter {
  _AnglePainter({required this.degrees});

  final int degrees;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(28, size.height - 22);
    final radius = math.min(size.width - 50, size.height - 40);
    final stroke = Paint()
      ..color = AppColors.purple
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx + radius, center.dy), stroke);
    final angle = -degrees * math.pi / 180;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ),
      stroke,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.45),
      0,
      -degrees * math.pi / 180,
      false,
      Paint()
        ..color = AppColors.purpleDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawCircle(center, 4, Paint()..color = AppColors.ink);
    final painter = TextPainter(
      text: TextSpan(
        text: '$degrees°',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.purpleDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx + radius * 0.5, center.dy - radius * 0.5 - 7),
    );
  }

  @override
  bool shouldRepaint(_AnglePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Measurement
// ---------------------------------------------------------------------------

class _RulerVisual extends StatelessWidget {
  const _RulerVisual({
    required this.blue,
    required this.red,
    required this.unit,
  });

  final int blue;
  final int red;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final maxUnits = math.max(math.max(blue, red), 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Segment(
          length: blue,
          maxUnits: maxUnits,
          color: AppColors.primary,
          label: 'Blue: $blue $unit',
        ),
        const SizedBox(height: 10),
        _Segment(
          length: red,
          maxUnits: maxUnits,
          color: AppColors.pink,
          label: 'Red: $red $unit',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < maxUnits; i++)
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.inkSoft,
                        width: i == 0 ? 2 : 1,
                      ),
                      bottom: BorderSide(
                        color: AppColors.inkSoft,
                        width: i == 0 ? 2 : 1,
                      ),
                      top: i == 0
                          ? BorderSide(color: AppColors.inkSoft, width: 2)
                          : BorderSide.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.length,
    required this.maxUnits,
    required this.color,
    required this.label,
  });

  final int length;
  final int maxUnits;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 12,
            color: AppColors.surfaceSoft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: length / maxUnits,
              child: Container(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClockVisual extends StatelessWidget {
  const _ClockVisual({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 130,
      child: CustomPaint(
        painter: _ClockPainter(hour: hour, minute: minute),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    canvas.drawCircle(center, radius, Paint()..color = AppColors.surface);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * math.pi / 6;
      final inner = Offset(
        center.dx + (radius - 8) * math.cos(angle),
        center.dy + (radius - 8) * math.sin(angle),
      );
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppColors.inkSoft
          ..strokeWidth = i % 3 == 0 ? 2.5 : 1.4,
      );
    }

    final hourAngle =
        -math.pi / 2 + ((hour % 12) + minute / 60.0) * math.pi / 6;
    final minuteAngle = -math.pi / 2 + (minute % 60) * math.pi / 30;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.5 * math.cos(hourAngle),
        center.dy + radius * 0.5 * math.sin(hourAngle),
      ),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * 0.76 * math.cos(minuteAngle),
        center.dy + radius * 0.76 * math.sin(minuteAngle),
      ),
      Paint()
        ..color = AppColors.pink
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 4, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Place value
// ---------------------------------------------------------------------------

class _BaseTenVisual extends StatelessWidget {
  const _BaseTenVisual({
    required this.hundreds,
    required this.tens,
    required this.ones,
  });

  final int hundreds;
  final int tens;
  final int ones;

  @override
  Widget build(BuildContext context) {
    final safeHundreds = hundreds.clamp(0, 4);
    final safeTens = tens.clamp(0, 9);
    final safeOnes = ones.clamp(0, 9);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < safeHundreds; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: const _HundredBlock(),
            ),
          if (safeTens > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 6),
              child: Wrap(
                spacing: 3,
                children: [
                  for (var i = 0; i < safeTens; i++)
                    Container(
                      width: 9,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (safeOnes > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Wrap(
                spacing: 3,
                runSpacing: 3,
                children: [
                  for (var i = 0; i < safeOnes; i++)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        border: Border.all(
                          color: AppColors.yellowDark,
                          width: 1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HundredBlock extends StatelessWidget {
  const _HundredBlock();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 0.6,
          crossAxisSpacing: 0.6,
        ),
        itemCount: 100,
        itemBuilder: (context, index) => Container(color: AppColors.primary),
      ),
    );
  }
}
