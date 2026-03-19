import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThanhTienDoLuaWidget extends StatefulWidget {
  final double progressValue;

  const ThanhTienDoLuaWidget({Key? key, required this.progressValue}) : super(key: key);

  @override
  State<ThanhTienDoLuaWidget> createState() => _ThanhTienDoLuaWidgetState();
}

class _ThanhTienDoLuaWidgetState extends State<ThanhTienDoLuaWidget> with SingleTickerProviderStateMixin {
  late AnimationController _fireController;

  @override
  void initState() {
    super.initState();
    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFireActive = widget.progressValue >= 1.0; 

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 12,
        child: isFireActive
            ? AnimatedBuilder(
                animation: _fireController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RealisticFirePainter(_fireController.value),
                    child: Container(),
                  );
                },
              )
            : LinearProgressIndicator(
                value: widget.progressValue,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
      ),
    );
  }
}

class _RealisticFirePainter extends CustomPainter {
  final double animationValue;
  final math.Random random = math.Random();
  
  _RealisticFirePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    _drawFlamePart(canvas, size, Colors.black38.withOpacity(0.4), amplitude: 4.0, frequency: 1.0);
    _drawFlamePart(canvas, size, Colors.redAccent.withOpacity(0.7), amplitude: 8.0, frequency: 1.5, phaseOffset: size.width / 4);
    _drawFlamePart(canvas, size, Colors.orange.withOpacity(0.8), amplitude: 10.0, frequency: 2.5, phaseOffset: size.width / 2);
    _drawFlamePart(canvas, size, Colors.yellowAccent.withOpacity(0.9), amplitude: 12.0, frequency: 3.5, phaseOffset: size.width / 1);
  }

  void _drawFlamePart(Canvas canvas, Size size, Color color, {required double amplitude, required double frequency, double phaseOffset = 0.0}) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      
    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      double volatility = (random.nextDouble() * 0.4 + 0.8);
      double y = size.height / 2 + (amplitude * volatility) * math.sin((x / size.width) * frequency * math.pi * 2 + (animationValue * math.pi * 2) + phaseOffset);
      
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close(); 
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RealisticFirePainter oldDelegate) {
    return true; 
  }
}