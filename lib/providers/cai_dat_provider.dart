import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 BẮT BUỘC PHẢI IMPORT DỊCH VỤ THÔNG BÁO VÀO ĐÂY
import '../services/dich_vu_thong_bao.dart'; 

class CaiDatProvider with ChangeNotifier {
  bool _isEnglish = false;  // Mặc định là Tiếng Việt
  bool _isDarkMode = false; // Mặc định là Nền sáng
  bool _isNotifEnabled = true; // Mặc định là Bật thông báo

  // Cho phép các màn hình khác đọc trạng thái
  bool get isEnglish => _isEnglish;
  bool get isDarkMode => _isDarkMode;
  bool get isNotifEnabled => _isNotifEnabled;

  CaiDatProvider() {
    _taiCaiDat(); // Tự động load cài đặt cũ khi vừa mở app lên
  }

  void doiNgonNgu(bool value) async {
    _isEnglish = value;
    notifyListeners(); 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isEnglish', _isEnglish);
  }

  void doiGiaoDien(bool value) async {
    _isDarkMode = value;
    notifyListeners(); 
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  // 🛠️ HÀM CÔNG TẮC THÔNG BÁO (ĐÃ ĐƯỢC NÂNG CẤP)
  void doiThongBao(bool value) async {
    _isNotifEnabled = value;
    notifyListeners(); 
    
    // Lưu trạng thái Tắt/Bật vào bộ nhớ
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotifEnabled', _isNotifEnabled);

    // 🔥 NẾU NGƯỜI DÙNG TẮT CÔNG TẮC -> VÀO HỆ THỐNG ANDROID HỦY HẾT BÁO THỨC CŨ
    if (_isNotifEnabled == false) {
      await DichVuThongBao().huyTatCaThongBao();
      debugPrint("Đã rà soát và tiêu diệt toàn bộ báo thức chạy ngầm!");
    }
  }

  // ==========================================
  // CÁC HÀM BỔ SUNG
  // ==========================================

  void toggleLanguage() {
    doiNgonNgu(!_isEnglish);
  }

  void toggleTheme() {
    doiGiaoDien(!_isDarkMode);
  }

  // Hàm tải lại dữ liệu đã lưu khi vừa mở App
  Future<void> _taiCaiDat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isNotifEnabled = prefs.getBool('isNotifEnabled') ?? true;
    
    notifyListeners(); 
  }
}