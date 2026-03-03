import 'package:flutter/material.dart';
import '../../models/cong_viec.dart';

class ItemCongViecWidget extends StatelessWidget {
  final CongViec congViec;
  final VoidCallback onChon; // Bấm vào thẻ để xem chi tiết/sửa
  final Function(bool?) onDoiTrangThai; // Bấm vào ô checkbox

  const ItemCongViecWidget({
    Key? key,
    required this.congViec,
    required this.onChon,
    required this.onDoiTrangThai,
  }) : super(key: key);

  // Hàm chọn màu theo mức độ ưu tiên
  Color _layMauUuTien(String? mucDo) {
    if (mucDo == 'High') return Colors.red;
    if (mucDo == 'Medium') return Colors.orange;
    if (mucDo == 'Low') return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    bool daHoanThanh = congViec.trangThai == 1;
    Color mauUuTien = _layMauUuTien(congViec.mucDoUuTien);

    return Card(
      // Giữ nguyên lề và bóng đổ của bạn
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: daHoanThanh ? 0 : 2,
      color: daHoanThanh ? Colors.grey.shade100 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: daHoanThanh ? Colors.grey.shade300 : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias, // Giữ cho vạch màu bo góc theo viền Card
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            // Vạch màu ưu tiên hiển thị ở mép trái
            left: BorderSide(
              color: daHoanThanh ? Colors.grey.shade400 : mauUuTien,
              width: 5, 
            ),
          ),
        ),
        // Giữ nguyên ListTile của bạn
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          
          // Nút Checkbox bên trái
          leading: Checkbox(
            value: daHoanThanh,
            activeColor: Colors.green, // Khi check đổi màu xanh lá cho đẹp
            shape: const CircleBorder(), 
            onChanged: onDoiTrangThai,
          ),
          
          // Tiêu đề công việc (Gộp thêm Danh mục lên trên)
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hiện danh mục và lá cờ ưu tiên
              Row(
                children: [
                  Text(
                    congViec.danhMuc ?? 'Công việc',
                    style: TextStyle(
                      fontSize: 12,
                      color: daHoanThanh ? Colors.grey : Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!daHoanThanh) ...[
                    Icon(Icons.flag, size: 14, color: mauUuTien),
                    const SizedBox(width: 4),
                    Text(
                      congViec.mucDoUuTien ?? 'Medium',
                      style: TextStyle(fontSize: 12, color: mauUuTien, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              // Tiêu đề gốc của bạn
              Text(
                congViec.tieuDe,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: daHoanThanh ? TextDecoration.lineThrough : null,
                  color: daHoanThanh ? Colors.grey : Colors.black87,
                ),
              ),
            ],
          ),
          
          // Ngày thực hiện (Gộp thêm icon chuông nhắc nhở)
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: daHoanThanh ? Colors.grey : Colors.blue),
                const SizedBox(width: 6),
                Text(
                  congViec.ngayThucHien,
                  style: TextStyle(
                    color: daHoanThanh ? Colors.grey : Colors.black54,
                  ),
                ),
                // Báo hiệu chuông nếu có cài nhắc nhở
                if (congViec.thoiGianNhacNho != null && congViec.thoiGianNhacNho!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.alarm, size: 14, color: daHoanThanh ? Colors.grey : Colors.amber.shade700),
                ]
              ],
            ),
          ),
          
          // Bấm vào thẻ
          onTap: onChon,
        ),
      ),
    );
  }
}