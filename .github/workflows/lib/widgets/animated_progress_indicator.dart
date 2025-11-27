import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedProgressIndicator extends StatefulWidget {
  final Color color;
  final double size;
  
  const AnimatedProgressIndicator({
    Key? key,
    this.color = Colors.red,
    this.size = 50.0,
  }) : super(key: key);

  @override
  State<AnimatedProgressIndicator> createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
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
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _LoadingPainter(
              animation: _controller,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _LoadingPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Indicador circular de fondo
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Arco animado
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -pi / 2; // -90 grados
    final sweepAngle = 2 * pi * animation.value; // Ángulo de barrido
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );
    
    // Punto indicador al final del arco
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final pointAngle = startAngle + sweepAngle;
    final pointX = center.dx + radius * cos(pointAngle);
    final pointY = center.dy + radius * sin(pointAngle);
    
    canvas.drawCircle(
      Offset(pointX, pointY),
      4.0,
      pointPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingPainter oldDelegate) {
    return animation != oldDelegate.animation ||
           color != oldDelegate.color;
  }
}