import 'package:flutter/material.dart';
import 'package:mercurio_messenger/utils/theme.dart';

/// Simple Vector Logo Widget for Mercurio
/// Clean, minimalist design with orange on black
class MercurioLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const MercurioLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ]
            : null,
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: _MercurioLogoPainter(),
      ),
    );
  }
}

class _MercurioLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw shield/lock shape
    final path = Path();
    
    // Shield outline
    path.moveTo(center.dx, center.dy - radius);
    path.quadraticBezierTo(
      center.dx + radius, center.dy - radius * 0.5,
      center.dx + radius, center.dy + radius * 0.3,
    );
    path.quadraticBezierTo(
      center.dx + radius, center.dy + radius * 0.8,
      center.dx, center.dy + radius,
    );
    path.quadraticBezierTo(
      center.dx - radius, center.dy + radius * 0.8,
      center.dx - radius, center.dy + radius * 0.3,
    );
    path.quadraticBezierTo(
      center.dx - radius, center.dy - radius * 0.5,
      center.dx, center.dy - radius,
    );
    
    canvas.drawPath(path, paint);

    // Draw lock icon in center
    final lockSize = radius * 0.5;
    final lockTop = center.dy - lockSize * 0.3;
    
    // Lock shackle (arc)
    final shacklePath = Path();
    shacklePath.addArc(
      Rect.fromCenter(
        center: Offset(center.dx, lockTop),
        width: lockSize * 0.8,
        height: lockSize * 0.8,
      ),
      3.14, // π (180 degrees)
      3.14, // π (another 180 degrees)
    );
    canvas.drawPath(shacklePath, paint);
    
    // Lock body (rectangle with rounded corners)
    final lockBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + lockSize * 0.2),
        width: lockSize * 0.9,
        height: lockSize * 0.7,
      ),
      Radius.circular(size.width * 0.02),
    );
    canvas.drawRRect(lockBody, paint);
    
    // Keyhole
    final keyholePaint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(center.dx, center.dy + lockSize * 0.1),
      size.width * 0.025,
      keyholePaint,
    );
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + lockSize * 0.25),
        width: size.width * 0.02,
        height: lockSize * 0.2,
      ),
      keyholePaint,
    );

    // Draw three message dots around shield (representing secure communication)
    final dotPaint = Paint()
      ..color = AppTheme.secondaryAmber
      ..style = PaintingStyle.fill;
    
    final dotRadius = size.width * 0.025;
    final dotDistance = radius * 1.3;
    
    // Top right dot
    canvas.drawCircle(
      Offset(
        center.dx + dotDistance * 0.7,
        center.dy - dotDistance * 0.5,
      ),
      dotRadius,
      dotPaint,
    );
    
    // Right dot
    canvas.drawCircle(
      Offset(
        center.dx + dotDistance,
        center.dy + dotDistance * 0.2,
      ),
      dotRadius,
      dotPaint,
    );
    
    // Bottom right dot
    canvas.drawCircle(
      Offset(
        center.dx + dotDistance * 0.5,
        center.dy + dotDistance * 0.7,
      ),
      dotRadius,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
