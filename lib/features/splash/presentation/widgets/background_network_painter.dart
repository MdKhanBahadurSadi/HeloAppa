import 'dart:math';
import 'package:flutter/material.dart';

class BackgroundNetworkPainter extends CustomPainter {
  final double animationValue;

  BackgroundNetworkPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final random = Random(42);
    final List<Offset> points = [];
    final int rowCount = 8;
    final int colCount = 6;

    for (int i = 0; i <= rowCount; i++) {
      for (int j = 0; j <= colCount; j++) {
        double x = (size.width / colCount) * j;
        double y = (size.height / rowCount) * i;
        
        // Add some randomness and animation
        x += sin(animationValue * 2 * pi + (i + j)) * 10;
        y += cos(animationValue * 2 * pi + (i + j)) * 10;
        
        points.add(Offset(x, y));
      }
    }

    // Draw lines
    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        final distance = (points[i] - points[j]).distance;
        if (distance < size.width / 4) {
          paint.color = Colors.white.withOpacity(0.1 * (1 - distance / (size.width / 4)));
          canvas.drawLine(points[i], points[j], paint);
        }
      }
    }

    // Draw dots with glow
    for (var point in points) {
      glowPaint.color = const Color(0xFF6C63FF).withOpacity(0.3 * (0.5 + 0.5 * sin(animationValue * 2 * pi)));
      canvas.drawCircle(point, 4, glowPaint);
      canvas.drawCircle(point, 2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundNetworkPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
