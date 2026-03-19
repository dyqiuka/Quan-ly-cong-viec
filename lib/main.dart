import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'providers/quan_ly_cong_viec_provider.dart';
import 'providers/quan_ly_giao_dien_provider.dart';
import 'providers/cai_dat_provider.dart';
import 'services/dich_vu_thong_bao.dart';
import 'views/auth/man_hinh_dang_nhap.dart';
import 'views/home/man_hinh_chinh.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, 
    );
  } catch (e) {
    debugPrint("Lỗi khởi tạo Firebase: $e");
  }
  
  await DichVuThongBao().khoiTao(); 

  User? nguoiDungHienTai = FirebaseAuth.instance.currentUser;
  
  Widget manHinhDauTien = nguoiDungHienTai != null 
      ? const ManHinhChinh() 
      : const ManHinhDangNhap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuanLyCongViecProvider()..taiDuLieuTuSQLite()),
        ChangeNotifierProvider(create: (_) => QuanLyGiaoDienProvider()),
        ChangeNotifierProvider(create: (_) => CaiDatProvider()),
      ],
      child: MyApp(manHinhKhoiDau: manHinhDauTien),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget manHinhKhoiDau; 

  const MyApp({super.key, required this.manHinhKhoiDau});

  @override
  Widget build(BuildContext context) {
    return Consumer<CaiDatProvider>(
      builder: (context, providerCaiDat, child) {
        return MaterialApp(
          title: 'Quản Lý Công Việc',
          debugShowCheckedModeBanner: false, 
          
          theme: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            scaffoldBackgroundColor: Colors.grey.shade50, 
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
          
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: Colors.blueGrey,
            scaffoldBackgroundColor: const Color(0xFF121212), 
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
            cardColor: const Color(0xFF1E1E1E), 
          ),
          
          themeMode: providerCaiDat.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: manHinhKhoiDau, 
        );
      },
    );
  }
}