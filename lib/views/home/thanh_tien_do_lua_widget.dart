import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'dart:math' as math; // 🔥 Thêm thư viện toán học để mô phỏng sự ngẫu nhiên

class ThanhTienDoLuaWidget extends StatefulWidget {
  final double progressValue; // Nhận giá trị từ 0.0 đến 1.0

  const ThanhTienDoLuaWidget({Key? key, required this.progressValue}) : super(key: key);

  @override
  State<ThanhTienDoLuaWidget> createState() => _ThanhTienDoLuaWidgetState();
}

// 🔥 Sử dụng SingleTickerProviderStateMixin để làm động cơ cho hoạt hình lửa
class _ThanhTienDoLuaWidgetState extends State<ThanhTienDoLuaWidget> with SingleTickerProviderStateMixin {
  late AnimationController _fireController;

  @override
  void initState() {
    super.initState();
    // Động cơ lửa giờ được quản lý riêng trong Widget này, chạy liên tục
    _fireController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFireActive = widget.progressValue >= 1.0; // Bật lửa khi đạt 100%

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 12,
        child: isFireActive
            ? AnimatedBuilder(
                animation: _fireController,
                builder: (context, child) {
                  return CustomPaint(
                    // 🔥 SỬA: Dùng Họa sĩ ngọn lửa chân thực mới
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

// 🔥🔥 SỬA TOÀN BỘ: BỘ VẼ LỬA 2D CHÂN THỰC MỚI (CustomPainter)
class _RealisticFirePainter extends CustomPainter {
  final double animationValue;
  final math.Random random = math.Random();
  _RealisticFirePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Vẽ lớp khói nền (xám/đen) - Sóng thấp, chậm
    _drawFlamePart(canvas, size, Colors.black38.withOpacity(0.4), amplitude: 4.0, frequency: 1.0);
    // 2. Vẽ dải lửa đỏ - Sóng cao, chậm
    _drawFlamePart(canvas, size, Colors.redAccent.withOpacity(0.7), amplitude: 8.0, frequency: 1.5, phaseOffset: size.width / 4);
    // 3. Vẽ lõi lửa cam-vàng rực rỡ - Hỗn loạn nhất
    _drawFlamePart(canvas, size, Colors.orange.withOpacity(0.8), amplitude: 10.0, frequency: 2.5, phaseOffset: size.width / 2);
    // 4. Vẽ điểm trắng-vàng - Sóng cao, nhanh, hẹp
    _drawFlamePart(canvas, size, Colors.yellowAccent.withOpacity(0.9), amplitude: 12.0, frequency: 3.5, phaseOffset: size.width / 1);
  }

  // Hàm vẽ một dải lửa với sự hỗn loạn ngẫu nhiên
  void _drawFlamePart(Canvas canvas, Size size, Color color, {required double amplitude, required double frequency, double phaseOffset = 0.0}) {
    final paint = Paint()..color = color..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    final path = Path();
    
    path.moveTo(0, size.height); // Bắt đầu ở góc đáy trái

    // Vẽ đường cong sóng hỗn loạn dựa trên hàm Sin và sự ngẫu nhiên
    for (double x = 0; x <= size.width; x++) {
      // Công thức sóng: baseline + amplitude * sin(frequency * x + thời gian + pha) * sự hỗn loạn ngẫu nhiên
      double volatility = (random.nextDouble() * 0.4 + 0.8); // Hỗn loạn từ 80% đến 120%
      double y = size.height / 2 + (amplitude * volatility) * math.sin((x / size.width) * frequency * math.pi * 2 + (animationValue * math.pi * 2) + phaseOffset);
      
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height); // Điểm cuối ở góc đáy phải
    path.close(); // Đóng hình
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RealisticFirePainter oldDelegate) {
    // Luôn vẽ lại để tạo hoạt hình hỗn loạn
    return true; 
  }
}