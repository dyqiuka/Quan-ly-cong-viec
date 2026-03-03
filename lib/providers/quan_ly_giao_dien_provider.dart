import 'package:flutter/material.dart';
import '../services/dich_vu_cau_hinh.dart';

class QuanLyGiaoDienProvider with ChangeNotifier {
  final DichVuCauHinh _dichVuCauHinh = DichVuCauHinh();
  
  bool _laCheDoToi = false;
  bool get laCheDoToi => _laCheDoToi;

  QuanLyGiaoDienProvider() {
    taiGiaoDienTuCauHinh(); // Tự động đọc dữ liệu khi mở app
  }

  // Lấy dữ liệu đã lưu
  Future<void> taiGiaoDienTuCauHinh() async {
    _laCheDoToi = await _dichVuCauHinh.docCheDoToi();
    notifyListeners();
  }

  // Hàm đổi giao diện khi người dùng bấm nút gạt
  void doiGiaoDien(bool giaTriMoi) {
    _laCheDoToi = giaTriMoi;
    _dichVuCauHinh.luuCheDoToi(giaTriMoi); // Lưu xuống bộ nhớ
    notifyListeners(); // Ra lệnh cho toàn App đổi màu
  }
}