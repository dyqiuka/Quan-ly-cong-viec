import 'package:flutter_test/flutter_test.dart';
import 'package:btl/views/auth/man_hinh_dang_nhap.dart';
import 'package:btl/main.dart';

void main() {
  testWidgets('Kiểm tra khởi tạo ứng dụng', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(manHinhKhoiDau: ManHinhDangNhap()));

    
    expect(find.byType(ManHinhDangNhap), findsOneWidget);
  });
}