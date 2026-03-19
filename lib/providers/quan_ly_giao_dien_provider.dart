import 'package:flutter/material.dart';
import '../services/dich_vu_cau_hinh.dart';

class QuanLyGiaoDienProvider with ChangeNotifier {
  final DichVuCauHinh _dichVuCauHinh = DichVuCauHinh();
  
  bool _laCheDoToi = false;
  bool get laCheDoToi => _laCheDoToi;

  QuanLyGiaoDienProvider() {
    taiGiaoDienTuCauHinh();
  }

  Future<void> taiGiaoDienTuCauHinh() async {
    _laCheDoToi = await _dichVuCauHinh.docCheDoToi();
    notifyListeners();
  }

  void doiGiaoDien(bool giaTriMoi) {
    _laCheDoToi = giaTriMoi;
    _dichVuCauHinh.luuCheDoToi(giaTriMoi);
    notifyListeners();
  }
}