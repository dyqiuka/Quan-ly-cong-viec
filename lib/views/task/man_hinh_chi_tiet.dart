import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cong_viec.dart';
import '../../providers/quan_ly_cong_viec_provider.dart';
import 'man_hinh_nhap_lieu.dart';

class ManHinhChiTiet extends StatelessWidget {
  final CongViec congViec;

  const ManHinhChiTiet({Key? key, required this.congViec}) : super(key: key);

  Future<void> _xacNhanXoa(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc muốn xóa công việc này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Provider.of<QuanLyCongViecProvider>(context, listen: false)
                    .xoaCongViec(congViec.maCongViec!);
                Navigator.pop(dialogContext);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa công việc')),
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Hàm phụ trợ chọn màu cho Mức độ ưu tiên
  Color _layMauUuTien(String? mucDo) {
    if (mucDo == 'High') return Colors.red;
    if (mucDo == 'Medium') return Colors.orange;
    if (mucDo == 'Low') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuanLyCongViecProvider>();
    
    final itemMoi = provider.danhSachCongViec.firstWhere(
      (element) => element.maCongViec == congViec.maCongViec,
      orElse: () => congViec,
    );

    bool daHoanThanh = itemMoi.trangThai == 1;
    Color mauUuTien = _layMauUuTien(itemMoi.mucDoUuTien);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            // --- KHỐI THÔNG TIN CHÍNH (Tiêu đề, trạng thái, mô tả) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
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
                        child: Text(
                          itemMoi.tieuDe,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            decoration: daHoanThanh ? TextDecoration.lineThrough : null,
                            color: daHoanThanh ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: daHoanThanh ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      daHoanThanh ? 'Hoàn thành' : 'Đang tiến hành',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: daHoanThanh ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(thickness: 0.5),
                  ),
                  const Text(
                    'Mô tả công việc',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemMoi.noiDung.isEmpty ? 'Không có mô tả' : itemMoi.noiDung,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- KHỐI ƯU TIÊN VÀ DANH MỤC ---
            Row(
              children: [
                // Ô Ưu tiên
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: mauUuTien.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mức độ ưu tiên', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.flag, size: 16, color: mauUuTien),
                            const SizedBox(width: 6),
                            Text(
                              itemMoi.mucDoUuTien ?? 'Bình thường',
                              style: TextStyle(color: mauUuTien, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Ô Danh mục
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Danh mục', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.category, size: 16, color: Colors.purple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                itemMoi.danhMuc ?? 'Chưa phân loại',
                                style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- KHỐI THỜI GIAN (Hạn chót & Nhắc nhở) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Hạn chót
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.calendar_today_outlined, color: Colors.blue, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Thời hạn', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            itemMoi.ngayThucHien.isNotEmpty ? itemMoi.ngayThucHien : 'Chưa đặt',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Chỉ hiển thị phần Nhắc nhở nếu có dữ liệu
                  if (itemMoi.thoiGianNhacNho != null && itemMoi.thoiGianNhacNho!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(thickness: 0.5),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.alarm, color: Colors.amber, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Nhắc nhở', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              itemMoi.thoiGianNhacNho!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  itemMoi.trangThai = 1;
                  Provider.of<QuanLyCongViecProvider>(context, listen: false).capNhatCongViec(itemMoi);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tuyệt vời! Bạn đã hoàn thành công việc.')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline),
                    SizedBox(width: 10),
                    Text('Đánh dấu hoàn thành', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          )
        : null,
    );
  }
}