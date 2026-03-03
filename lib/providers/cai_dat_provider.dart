import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CaiDatProvider with ChangeNotifier {
  bool _isEnglish = false;  // Mặc định là Tiếng Việt (false)
  bool _isDarkMode = false; // Mặc định là Nền sáng (false)

  // Cho phép các màn hình khác đọc trạng thái
  bool get isEnglish => _isEnglish;
  bool get isDarkMode => _isDarkMode;

  CaiDatProvider() {
    _taiCaiDat(); // Tự động load cài đặt cũ khi vừa mở app lên
  }

  // Hàm gạt công tắc Ngôn ngữ (Code gốc của bạn)
  void doiNgonNgu(bool value) async {
    _isEnglish = value;
    notifyListeners(); // Hét lên cho toàn bộ App biết để vẽ lại chữ!
    
    // Lưu lựa chọn vào bộ nhớ máy
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isEnglish', _isEnglish);
  }

  // Hàm gạt công tắc Dark Mode (Code gốc của bạn)
  void doiGiaoDien(bool value) async {
    _isDarkMode = value;
    notifyListeners(); // Hét lên cho toàn bộ App biết để đổi màu!
    
    // Lưu lựa chọn vào bộ nhớ máy
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  // ==========================================
  // 🔥 CÁC HÀM BỔ SUNG ĐỂ KHÔNG BỊ BÁO LỖI
  // ==========================================

  // Hàm đảo ngược trạng thái ngôn ngữ (Dùng cho trang Hồ sơ)
  void toggleLanguage() {
    doiNgonNgu(!_isEnglish);
  }

  // Hàm đảo ngược trạng thái Dark Mode (Dùng cho trang Hồ sơ)
  void toggleTheme() {
    doiGiaoDien(!_isDarkMode);
  }

  // Hàm tải lại dữ liệu đã lưu khi vừa mở App
  Future<void> _taiCaiDat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners(); // Hét lên để app cập nhật ngay từ lúc khởi động
  }
}