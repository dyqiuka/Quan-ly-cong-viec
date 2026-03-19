import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cai_dat_provider.dart';
import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../services/dich_vu_thong_bao.dart';
import 'trang_chu_view.dart';
import '../calendar/man_hinh_lich.dart';
import '../settings/man_hinh_settings.dart';
import '../task/man_hinh_chi_tiet.dart';

class ManHinhChinh extends StatefulWidget {
  const ManHinhChinh({super.key});

  @override
  State<ManHinhChinh> createState() => _ManHinhChinhState();
}

class _ManHinhChinhState extends State<ManHinhChinh> with SingleTickerProviderStateMixin {
  int _tabHienTai = 0;
  StreamSubscription? _thongBaoSubscription;
  late PageController _pageController;

  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Widget> _cacManHinh = [
    const TrangChuView(),    
    const ManHinhLich(),     
    const ManHinhSettings(), 
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabHienTai);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _entranceController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    
    _entranceController.forward(); 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuanLyCongViecProvider>(context, listen: false).dongBoTuFirebaseVeMay();

      if (DichVuThongBao.veChoXuLy != null) {
        String tenCV = DichVuThongBao.veChoXuLy!;
        DichVuThongBao.veChoXuLy = null; 
        _moTrangChiTietTuTen(tenCV); 
      }
    });

    _thongBaoSubscription = DichVuThongBao.streamNhanPayload.stream.listen((String? tenCV) {
      if (tenCV != null && tenCV.isNotEmpty && mounted) {
        _moTrangChiTietTuTen(tenCV);
      }
    });
  }

  @override
  void dispose() {
    _thongBaoSubscription?.cancel();
    _pageController.dispose();
    _entranceController.dispose(); 
    super.dispose();
  }

  void _moTrangChiTietTuTen(String payloadDauVao) async { 
    final provider = Provider.of<QuanLyCongViecProvider>(context, listen: false);
    final isEn = Provider.of<CaiDatProvider>(context, listen: false).isEnglish;
    
    int soLanCho = 0;
    while (provider.danhSachCongViec.isEmpty && soLanCho < 30) {
      await Future.delayed(const Duration(milliseconds: 100));
      soLanCho++;
    }

    if (provider.danhSachCongViec.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEn 
              ? '⏳ Data loading too slow, please open task manually!' 
              : '⏳ Dữ liệu chưa tải kịp, vui lòng tự mở từ danh sách!'),
          ),
        );
      }
      return; 
    }

    try {
      final congViecCanMo = provider.danhSachCongViec.firstWhere(
        (cv) => cv.tieuDe == payloadDauVao || cv.maCongViec == payloadDauVao,
      );
      
      if (mounted) {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: congViecCanMo))
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(isEn 
              ? '❌ Error: Cannot find task with ID/Name "$payloadDauVao"' 
              : '❌ Lỗi: Không tìm thấy việc có mã/tên là "$payloadDauVao"'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _tabHienTai = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            children: _cacManHinh,
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _tabHienTai,
          onDestinationSelected: (int index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            );
          },
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          indicatorColor: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
          elevation: 0,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: isDark ? Colors.grey : Colors.black54),
              selectedIcon: const Icon(Icons.home, color: Colors.blueAccent),
              label: isEn ? 'Home' : 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined, color: isDark ? Colors.grey : Colors.black54),
              selectedIcon: const Icon(Icons.calendar_month, color: Colors.blueAccent),
              label: isEn ? 'Calendar' : 'Lịch',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: isDark ? Colors.grey : Colors.black54),
              selectedIcon: const Icon(Icons.settings, color: Colors.blueAccent),
              label: isEn ? 'Settings' : 'Cài đặt',
            ),
          ],
        ),
      ),
    );
  }
}