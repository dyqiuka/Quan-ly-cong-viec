import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/quan_ly_cong_viec_provider.dart';
import 'providers/quan_ly_giao_dien_provider.dart';
import 'views/auth/man_hinh_dang_nhap.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/cai_dat_provider.dart';
void main() async {
  // Bắt buộc phải có lệnh này khi thao tác với Native (SQLite, SharedPrefs) hoặc Firebase trước khi chạy App
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  // Khởi tạo Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
  } catch (e) {
    debugPrint("Lỗi khởi tạo Firebase: $e");
    // Ghi chú: Nếu bạn chưa chạy lệnh 'flutterfire configure' trên máy, 
    // app vẫn sẽ mở lên được nhưng chức năng đăng nhập sẽ báo lỗi.
  }

  runApp(
    // Bọc toàn bộ ứng dụng bằng MultiProvider để quản lý trạng thái tập trung (MVVM)
    MultiProvider(
      providers: [
        // 1. Provider quản lý Công Việc (tự động gọi taiDuLieu khi khởi tạo)
        ChangeNotifierProvider(
          create: (_) => QuanLyCongViecProvider()..taiDuLieuTuSQLite(),
        ),
        // 2. Provider quản lý Giao Diện Sáng/Tối
        ChangeNotifierProvider(
          create: (_) => QuanLyGiaoDienProvider(),
        ),
        ChangeNotifierProvider(create: (_) => CaiDatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sử dụng Consumer ở ngay thư mục gốc để lắng nghe thay đổi bật/tắt Dark Mode
    return Consumer<QuanLyGiaoDienProvider>(
      builder: (context, providerGiaoDien, child) {
        return MaterialApp(
          title: 'Quản Lý Công Việc',
          debugShowCheckedModeBanner: false, // Tắt dải băng chữ DEBUG ở góc phải màn hình
          
          // ==========================================
          // CẤU HÌNH GIAO DIỆN SÁNG (LIGHT THEME)
          // ==========================================
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.grey.shade50, // Nền xám nhạt cho dịu mắt
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          
          // ==========================================
          // CẤU HÌNH GIAO DIỆN TỐI (DARK THEME)
          // ==========================================
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey,
            scaffoldBackgroundColor: const Color(0xFF121212), // Màu nền đen chuẩn của Material Design
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1F1F1F),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            cardColor: const Color(0xFF1E1E1E), // Màu nền của các thẻ (Card) công việc
          ),
          
          // ==========================================
          // ĐIỀU KHIỂN CHẾ ĐỘ HIỂN THỊ
          // ==========================================
          themeMode: providerGiaoDien.laCheDoToi ? ThemeMode.dark : ThemeMode.light,
          
          // Màn hình đầu tiên xuất hiện khi khởi động ứng dụng
          home: const ManHinhDangNhap(), 
        );
      },
    );
  }
}