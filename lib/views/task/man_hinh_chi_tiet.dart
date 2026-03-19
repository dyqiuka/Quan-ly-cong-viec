import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cong_viec.dart';
import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../providers/cai_dat_provider.dart';
import 'man_hinh_nhap_lieu.dart';

class ManHinhChiTiet extends StatelessWidget {
  final CongViec congViec;

  const ManHinhChiTiet({super.key, required this.congViec});

  Future<void> _xacNhanXoa(BuildContext context) async {
    bool isEn = context.read<CaiDatProvider>().isEnglish;
    bool isDark = context.read<CaiDatProvider>().isDarkMode;

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEn ? 'Confirm Deletion' : 'Xác nhận xóa',
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isEn ? 'Are you sure you want to delete this task?' : 'Bạn có chắc muốn xóa công việc này không?',
            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isEn ? 'Cancel' : 'Hủy', style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Provider.of<QuanLyCongViecProvider>(context, listen: false)
                    .xoaCongViec(congViec.maCongViec!);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEn ? 'Task deleted' : 'Đã xóa công việc')),
                );
              },
              child: Text(isEn ? 'Delete' : 'Xóa', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Color _layMauUuTien(String? mucDo) {
    if (mucDo == 'High' || mucDo == 'Cao') return Colors.red;
    if (mucDo == 'Medium' || mucDo == 'Trung Bình') return Colors.orange;
    if (mucDo == 'Low' || mucDo == 'Thấp') return Colors.green;
    return Colors.grey;
  }

  String _dichDanhMuc(String? cat, bool isEn) {
    if (cat == null) return isEn ? 'Uncategorized' : 'Chưa phân loại';
    if (!isEn) return cat;
    switch (cat) {
      case "Học tập": return "Study";
      case "Công việc": return "Work";
      case "Cá nhân": return "Personal";
      case "Sức khỏe": return "Health";
      case "Khác": return "Other";
      default: return cat;
    }
  }

  String _dichUuTien(String? pri, bool isEn) {
    if (pri == null) return isEn ? 'Normal' : 'Bình thường';
    if (!isEn) return pri;
    switch (pri) {
      case "Thấp": return "Low";
      case "Trung Bình": return "Medium";
      case "Cao": return "High";
      default: return pri;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;
    final provider = context.watch<QuanLyCongViecProvider>();
    
    final itemMoi = provider.danhSachCongViec.firstWhere(
      (element) => element.maCongViec == congViec.maCongViec,
      orElse: () => congViec,
    );

    bool daHoanThanh = itemMoi.trangThai == 1;
    Color mauUuTien = _layMauUuTien(itemMoi.mucDoUuTien);

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? 'Task Details' : 'Chi tiết công việc',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold), 
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManHinhNhapLieu(congViec: itemMoi)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _xacNhanXoa(context), 
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        daHoanThanh ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: daHoanThanh ? Colors.green : Colors.blue,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        child: Hero(
                          tag: 'tieu_de_${itemMoi.maCongViec}', 
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              itemMoi.tieuDe,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                decoration: daHoanThanh ? TextDecoration.lineThrough : null,
                                color: daHoanThanh ? Colors.grey : textColor, 
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: daHoanThanh 
                          ? Colors.green.withValues(alpha: 0.15) 
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daHoanThanh 
                          ? (isEn ? 'Completed' : 'Hoàn thành') 
                          : (isEn ? 'In Progress' : 'Đang tiến hành'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: daHoanThanh ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 0.5, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                  ),
                  Text(
                    isEn ? 'Task Description' : 'Mô tả công việc',
                    style: TextStyle(fontSize: 15, color: subtitleColor, fontWeight: FontWeight.w600), 
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemMoi.noiDung.isEmpty 
                        ? (isEn ? 'No description' : 'Không có mô tả') 
                        : itemMoi.noiDung,
                    style: TextStyle(fontSize: 16, color: textColor, height: 1.6), 
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: mauUuTien.withValues(alpha: 0.15), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Priority' : 'Mức độ ưu tiên', 
                          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13)
                        ),
                        const SizedBox(height: 8),
                        
                        Hero(
                          tag: 'uu_tien_${itemMoi.maCongViec}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Row(
                              children: [
                                Icon(Icons.flag, size: 18, color: mauUuTien),
                                const SizedBox(width: 6),
                                Text(
                                  _dichUuTien(itemMoi.mucDoUuTien, isEn), 
                                  style: TextStyle(color: mauUuTien, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        )
                        
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn ? 'Category' : 'Danh mục', 
                          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700], fontSize: 13)
                        ),
                        const SizedBox(height: 8),
                        
                        Hero(
                          tag: 'danh_muc_${itemMoi.maCongViec}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Row(
                              children: [
                                const Icon(Icons.category, size: 18, color: Colors.purple),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _dichDanhMuc(itemMoi.danhMuc, isEn), 
                                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor, 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15), 
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? 'Deadline' : 'Thời hạn', 
                            style: TextStyle(color: subtitleColor, fontSize: 14)
                          ),
                          const SizedBox(height: 4),
                          
                          Hero(
                            tag: 'thoi_han_text_${itemMoi.maCongViec}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                itemMoi.ngayThucHien.isNotEmpty ? itemMoi.ngayThucHien : (isEn ? 'Not set' : 'Chưa đặt'),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                              ),
                            ),
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                  
                  if (itemMoi.thoiGianNhacNho != null && itemMoi.thoiGianNhacNho!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(thickness: 0.5, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15), 
                            borderRadius: BorderRadius.circular(12)
                          ),
                          child: const Icon(Icons.alarm, color: Colors.amber, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? 'Reminder' : 'Nhắc nhở', 
                              style: TextStyle(color: subtitleColor, fontSize: 14)
                            ),
                            const SizedBox(height: 4),
                            
                            Hero(
                              tag: 'nhac_nho_text_${itemMoi.maCongViec}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  itemMoi.thoiGianNhacNho!,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                                ),
                              ),
                            ),
                            
                          ],
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      
      bottomNavigationBar: !daHoanThanh 
        ? Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.05), 
                  blurRadius: 10, 
                  offset: const Offset(0, -2)
                )
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  itemMoi.trangThai = 1;
                  Provider.of<QuanLyCongViecProvider>(context, listen: false).capNhatCongViec(itemMoi);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEn ? 'Awesome! You have completed the task.' : 'Tuyệt vời! Bạn đã hoàn thành công việc.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 24), 
                    const SizedBox(width: 10),
                    Text(
                      isEn ? 'Mark as completed' : 'Đánh dấu hoàn thành', 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold) 
                    ),
                  ],
                ),
              ),
            ),
          )
        : null,
    );
  }
}