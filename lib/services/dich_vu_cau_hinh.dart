import 'package:shared_preferences/shared_preferences.dart';

class DichVuCauHinh {
  static const String _keyCheDoToi = 'che_do_toi';

  // Lưu trạng thái vào bộ nhớ
  Future<void> luuCheDoToi(bool laCheDoToi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheDoToi, laCheDoToi);
  }

  // Đọc trạng thái từ bộ nhớ (Mặc định là false - giao diện sáng)
  Future<bool> docCheDoToi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCheDoToi) ?? false;
  }
}