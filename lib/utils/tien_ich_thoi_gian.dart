import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TienIchThoiGian {
  // 1. Chuyển DateTime thành chuỗi dạng "Ngày/Tháng/Năm"
  static String dinhDangNgay(DateTime ngay) {
    return DateFormat('dd/MM/yyyy').format(ngay);
  }

  // 2. Chuyển chuỗi "dd/MM/yyyy" ngược lại thành DateTime (Dùng khi sửa công việc)
  static DateTime chuyenChuoiThanhNgay(String chuoiNgay) {
    try {
      return DateFormat('dd/MM/yyyy').parse(chuoiNgay);
    } catch (e) {
      return DateTime.now(); // Nếu lỗi thì trả về ngày hiện tại
    }
  }

  // 3. Hiển thị hộp thoại chọn ngày của hệ thống
  static Future<DateTime?> chonNgayThang(BuildContext context, {DateTime? ngayBanDau}) async {
    final DateTime? ngayDuocChon = await showDatePicker(
      context: context,
      initialDate: ngayBanDau ?? DateTime.now(),
      firstDate: DateTime(2000), // Cho phép lùi về năm 2000
      lastDate: DateTime(2100),  // Cho phép tới năm 2100
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Màu của bộ lịch
            ),
          ),
          child: child!,
        );
      },
    );
    return ngayDuocChon;
  }
}