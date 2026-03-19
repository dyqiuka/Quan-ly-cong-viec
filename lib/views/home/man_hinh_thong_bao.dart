import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../providers/cai_dat_provider.dart';
import '../../models/cong_viec.dart';
import '../task/man_hinh_chi_tiet.dart';

class ManHinhThongBao extends StatefulWidget {
  const ManHinhThongBao({super.key});

  @override
  State<ManHinhThongBao> createState() => _ManHinhThongBaoState();
}

class _ManHinhThongBaoState extends State<ManHinhThongBao> {
  final TextEditingController _searchController = TextEditingController();
  String _tuKhoaTimKiem = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4FF);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? "Today's Notifications" : "Thông báo hôm nay",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _tuKhoaTimKiem = value.toLowerCase()),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: isEn ? "Search notifications..." : "Tìm kiếm thông báo...",
                hintStyle: TextStyle(color: subTextColor),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _tuKhoaTimKiem.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _tuKhoaTimKiem = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // DANH SÁCH THÔNG BÁO
          Expanded(
            child: Consumer<QuanLyCongViecProvider>(
              builder: (context, provider, child) {
                final now = DateTime.now();
                final todayStr = DateFormat('dd/MM/yyyy').format(now);

                // Lọc ra các công việc HÔM NAY và CÓ NHẮC NHỞ
                List<CongViec> dsThongBao = provider.danhSachCongViec.where((cv) {
                  bool isToday = cv.ngayThucHien.contains(todayStr);
                  bool hasReminder = cv.thoiGianNhacNho != null && cv.thoiGianNhacNho!.isNotEmpty;
                  return isToday && hasReminder;
                }).toList();

                // Lọc tiếp theo từ khóa tìm kiếm
                if (_tuKhoaTimKiem.isNotEmpty) {
                  dsThongBao = dsThongBao.where((cv) {
                    return cv.tieuDe.toLowerCase().contains(_tuKhoaTimKiem) || 
                           cv.noiDung.toLowerCase().contains(_tuKhoaTimKiem);
                  }).toList();
                }

                // Sắp xếp theo thời gian nhắc nhở (Gần nhất lên đầu)
                dsThongBao.sort((a, b) => a.thoiGianNhacNho!.compareTo(b.thoiGianNhacNho!));

                if (dsThongBao.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_paused_outlined, size: 64, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          isEn ? "No notifications today" : "Không có thông báo nào hôm nay",
                          style: TextStyle(color: subTextColor, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: dsThongBao.length,
                  itemBuilder: (context, index) {
                    final cv = dsThongBao[index];
                    bool daXong = cv.trangThai == 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: daXong ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            daXong ? Icons.check_circle : Icons.notifications_active, 
                            color: daXong ? Colors.green : Colors.orange
                          ),
                        ),
                        title: Text(
                          cv.tieuDe,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, decoration: daXong ? TextDecoration.lineThrough : null),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 14, color: subTextColor),
                              const SizedBox(width: 4),
                              Text(cv.thoiGianNhacNho!, style: TextStyle(color: subTextColor, fontSize: 13)),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}