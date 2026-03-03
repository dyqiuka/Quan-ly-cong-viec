import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';

// Import 3 tab màn hình chuẩn xác
import 'trang_chu_view.dart';
import '../calendar/man_hinh_lich.dart';
import '../settings/man_hinh_settings.dart';

class ManHinhChinh extends StatefulWidget {
  const ManHinhChinh({Key? key}) : super(key: key);

  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> {
  int _tabHienTai = 0;

  // Danh sách 3 màn hình tương ứng với 3 tab
  final List<Widget> _cacManHinh = [
    const TrangChuView(),    // Vị trí 0: Home
    const ManHinhLich(),     // Vị trí 1: Calendar
    const ManHinhSettings(), // Vị trí 2: Settings
  ];

  @override
  void initState() {
    super.initState();
    // Gọi hàm đồng bộ dữ liệu ngầm 1 lần duy nhất khi vừa vào App
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuanLyCongViecProvider>(context, listen: false).dongBoTuFirebaseVeMay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiển thị giao diện tùy thuộc vào việc người dùng đang bấm tab nào
      body: _cacManHinh[_tabHienTai],
      
      // Thanh Menu bên dưới
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabHienTai,
        onDestinationSelected: (int index) {
          setState(() {
            _tabHienTai = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: Colors.blue.shade600,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.calendar_today, color: Colors.white),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined, color: Colors.grey),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}