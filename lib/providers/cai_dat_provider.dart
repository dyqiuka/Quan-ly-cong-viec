import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/dich_vu_thong_bao.dart'; 

class CaiDatProvider with ChangeNotifier {
  bool _isEnglish = false;
  bool _isDarkMode = false;
  bool _isNotifEnabled = true;

  bool get isEnglish => _isEnglish;
  bool get isDarkMode => _isDarkMode;
  bool get isNotifEnabled => _isNotifEnabled;

  CaiDatProvider() {
    _taiCaiDat();
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

  void doiThongBao(bool value) async {
    _isNotifEnabled = value;
    notifyListeners(); 
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotifEnabled', _isNotifEnabled);

    if (!_isNotifEnabled) {
      await DichVuThongBao().huyTatCaThongBao();
      debugPrint("Đã rà soát và tiêu diệt toàn bộ báo thức chạy ngầm!");
    }
  }

  void toggleLanguage() {
    doiNgonNgu(!_isEnglish);
  }

  void toggleTheme() {
    doiGiaoDien(!_isDarkMode);
  }

  Future<void> _taiCaiDat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isEnglish = prefs.getBool('isEnglish') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isNotifEnabled = prefs.getBool('isNotifEnabled') ?? true;
    
    notifyListeners(); 
  }
}