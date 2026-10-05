import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ball.dart';

class BallWidget extends StatefulWidget {
  final Ball ball;
  final double size;

  const BallWidget({
    Key? key,
    required this.ball,
    required this.size,
  }) : super(key: key);

  @override
  State<BallWidget> createState() => _BallWidgetState();
}

class _BallWidgetState extends State<BallWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.ball.isMoving) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(BallWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ball.isSelected != oldWidget.ball.isSelected) {
      if (widget.ball.isSelected) {
        _controller.repeat(
            reverse: true, period: const Duration(milliseconds: 350));
      } else {
        if (!widget.ball.isPopping) {
          _controller.forward(from: 1.0);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double bounceY =
            widget.ball.isSelected ? _bounceAnimation.value : 0.0;
        final double scale =
            (widget.ball.isSelected || widget.ball.isPopping)
                ? 1.0
                : _scaleAnimation.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: widget.ball.isPopping ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInBack,
              child: AnimatedOpacity(
                opacity: widget.ball.isPopping ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Transform.translate(
                  offset: Offset(0, bounceY),
                  child: Transform.scale(
                    scale: scale,
                    child: _buildBall(),
                  ),
                ),
              ),
            ),
            if (widget.ball.isPopping)
              ShatterEffectWidget(color: widget.ball.color.color, size: widget.size),
          ],
        );
      },
    );
  }

  Widget _buildBall() {
    final double s = widget.size;
    final Color base = widget.ball.color.color;

    if (widget.ball.specialType == SpecialBallType.rainbow) {
      return _RainbowBall(size: s, isSelected: widget.ball.isSelected);
    }

    // Ghost preview (next balls) — smaller, translucent, no shadow
    if (widget.ball.isNext) {
      return _GhostBall(size: s, base: base);
    }

    return _MarbleBall(
      size: s,
      base: base,
      isSelected: widget.ball.isSelected,
      isBomb: widget.ball.specialType == SpecialBallType.bomb,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full marble ball — rich 3D glossy look
// ─────────────────────────────────────────────────────────────────────────────
class _MarbleBall extends StatelessWidget {
  final double size;
  final Color base;
  final bool isSelected;
  final bool isBomb;

  const _MarbleBall({
    required this.size,
    required this.base,
    required this.isSelected,
    required this.isBomb,
  });

  @override
  Widget build(BuildContext context) {
    // Derive shades
    final Color light = _lighten(base, 0.55);
    final Color mid   = _lighten(base, 0.15);
    final Color dark  = _darken(base, 0.30);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MarblePainter(
          light: light,
          mid: mid,
          base: base,
          dark: dark,
          isSelected: isSelected,
          isBomb: isBomb,
        ),
      ),
    );
  }
}

class _MarblePainter extends CustomPainter {
  final Color light, mid, base, dark;
  final bool isSelected;
  final bool isBomb;

  const _MarblePainter({
    required this.light,
    required this.mid,
    required this.base,
    required this.dark,
    required this.isSelected,
    required this.isBomb,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // ── No Drop shadow ────────────────────────────────────────────────────────
    // Classic 98 balls have built-in shadow on the texture, they don't cast 
    // a separate shadow onto the grid.

    // ── Main sphere body (smooth offset radial gradient) ─────────────────────
    // Classic 3D balls are often just a single, smooth radial gradient offset to the light source.
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.4, -0.4),
        radius: 0.9,
        colors: [
          Colors.white,             // Strong white highlight point
          _lighten(base, 0.3),
          base,                     // Base color
          _darken(base, 0.5),       // Deep shadow color
          Colors.black,             // Near black rim at the very edge
        ],
        stops: const [0.0, 0.2, 0.5, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    
    // Draw the ball body
    canvas.drawCircle(center, r * 0.90, bodyPaint);

    // ── Selection indicator ──────────────────────────────────────────────────

    // If selected, we draw a subtle bounding box or ring (handled by bouncing mostly)
    // The shadow blur increase (above) and the bouncing animation do the heavy lifting.

    // ── Bomb icon ────────────────────────────────────────────────────────────
    if (isBomb) {
      final tp = TextPainter(
        text: const TextSpan(text: '💣', style: TextStyle(fontSize: 16)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_MarblePainter old) =>
      old.isSelected != isSelected || old.base != base;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ghost ball — translucent preview for next placement
// ─────────────────────────────────────────────────────────────────────────────
class _GhostBall extends StatelessWidget {
  final double size;
  final Color base;

  const _GhostBall({required this.size, required this.base});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GhostPainter(base: base),
      ),
    );
  }
}

class _GhostPainter extends CustomPainter {
  final Color base;
  const _GhostPainter({required this.base});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Translucent fill
    final p = Paint()
      ..color = base.withValues(alpha: 0.30);
    canvas.drawCircle(center, r * 0.88, p);

    // Thin border
    canvas.drawCircle(
        center,
        r * 0.88,
        Paint()
          ..color = base.withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Small highlight
    canvas.drawCircle(
        Offset(r * 0.55, r * 0.45),
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_GhostPainter old) => old.base != base;
}

// ─────────────────────────────────────────────────────────────────────────────
// Rainbow ball
// ─────────────────────────────────────────────────────────────────────────────
class _RainbowBall extends StatelessWidget {
  final double size;
  final bool isSelected;

  const _RainbowBall({required this.size, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RainbowPainter(isSelected: isSelected)),
    );
  }
}

class _RainbowPainter extends CustomPainter {
  final bool isSelected;
  const _RainbowPainter({required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    // Shadow
    canvas.drawCircle(
        Offset(center.dx + 2, center.dy + 3),
        r * 0.88,
        Paint()
          ..color = Colors.black38
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

    // Rainbow sweep
    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF1744),
          Color(0xFFFF6D00),
          Color(0xFFFFEA00),
          Color(0xFF00E676),
          Color(0xFF2979FF),
          Color(0xFFD500F9),
          Color(0xFFFF1744),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r * 0.91, sweepPaint);

    // Gloss overlay
    canvas.drawOval(
        Rect.fromLTWH(r * 0.12, r * 0.10, r * 0.60, r * 0.44),
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.75),
              Colors.white.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(r * 0.12, r * 0.10, r * 0.60, r * 0.44)));
  }

  @override
  bool shouldRepaint(_RainbowPainter old) => old.isSelected != isSelected;
}

// ─────────────────────────────────────────────────────────────────────────────
// Color helpers
// ─────────────────────────────────────────────────────────────────────────────
Color _lighten(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

Color _darken(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

// ─────────────────────────────────────────────────────────────────────────────
// Shatter Particle Effect
// ─────────────────────────────────────────────────────────────────────────────

class ShatterEffectWidget extends StatefulWidget {
  final Color color;
  final double size;
  const ShatterEffectWidget({Key? key, required this.color, required this.size}) : super(key: key);

  @override
  State<ShatterEffectWidget> createState() => _ShatterEffectWidgetState();
}

class _ShatterEffectWidgetState extends State<ShatterEffectWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _particles = List.generate(10, (i) {
      final angle = (i / 10) * 2 * pi + (_rnd.nextDouble() - 0.5);
      return Particle(
        angle: angle,
        speed: widget.size * 0.8 + _rnd.nextDouble() * widget.size,
        size: widget.size * 0.15 + _rnd.nextDouble() * widget.size * 0.15,
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size * 2, widget.size * 2), // Allow particles to expand out
          painter: ShatterPainter(particles: _particles, progress: _controller.value, color: widget.color),
        );
      },
    );
  }
}

class Particle {
  final double angle;
  final double speed;
  final double size;
  Particle({required this.angle, required this.speed, required this.size});
}

class ShatterPainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;
  ShatterPainter({required this.particles, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Smooth fade out
    final opacity = (1.0 - progress).clamp(0.0, 1.0);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;
      
    for (final p in particles) {
      // Ease out distance
      final distance = p.speed * Curves.easeOutCubic.transform(progress);
      final x = center.dx + cos(p.angle) * distance;
      final y = center.dy + sin(p.angle) * distance;
      // Shrink particles as they fly
      final s = p.size * (1.0 - progress * 0.5);
      if (s > 0) {
        canvas.drawCircle(Offset(x, y), s, paint);
      }
    }
  }

  @override
  bool shouldRepaint(ShatterPainter old) => true;
}
