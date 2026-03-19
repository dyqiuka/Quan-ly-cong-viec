import 'package:shared_preferences/shared_preferences.dart';

class DichVuCauHinh {
  static const String _keyCheDoToi = 'che_do_toi';

  Future<void> luuCheDoToi(bool laCheDoToi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyCheDoToi, laCheDoToi);
  }

  Future<bool> docCheDoToi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyCheDoToi) ?? false;
  }
}