import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../providers/cai_dat_provider.dart'; 
import '../../models/cong_viec.dart';
import '../home/item_cong_viec_widget.dart';
import '../task/man_hinh_chi_tiet.dart';
import '../task/man_hinh_nhap_lieu.dart';

class ManHinhLich extends StatefulWidget {
  const ManHinhLich({Key? key}) : super(key: key);

  @override
  State<ManHinhLich> createState() => _ManHinhLichState();
}

class _ManHinhLichState extends State<ManHinhLich> {
  DateTime _focusedDay = DateTime.now();
  String _cheDoXem = 'Month'; 

  List<CongViec> _layCongViecTheoNgay(List<CongViec> tatCaCongViec, DateTime ngay) {
    String chuoiNgayChon = DateFormat('dd/MM/yyyy').format(ngay);
    return tatCaCongViec.where((cv) => cv.ngayThucHien.contains(chuoiNgayChon)).toList();
  }

  void _chuyenTrang(int huong) {
    setState(() {
      if (_cheDoXem == 'Month') {
        _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + huong, 1);
      } else if (_cheDoXem == 'Week') {
        _focusedDay = _focusedDay.add(Duration(days: 7 * huong));
      } else {
        _focusedDay = _focusedDay.add(Duration(days: huong));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final caiDat = Provider.of<CaiDatProvider>(context);
    final isEng = caiDat.isEnglish;
    final isDark = caiDat.isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subTextColor = isDark ? Colors.white54 : Colors.grey.shade500;
    
    final myLocale = isEng ? 'en_US' : 'vi_VN';

    return Scaffold(
      backgroundColor: bgColor, 
      body: Consumer<QuanLyCongViecProvider>(
        builder: (context, provider, child) {
          final tatCaCongViec = provider.danhSachCongViec;
          final tongSoViecNgay = _layCongViecTheoNgay(tatCaCongViec, _focusedDay).length;

          return Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 180,
                    padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isEng ? "Calendar" : "Lịch công việc", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          isEng ? "$tongSoViecNgay scheduled tasks" : "Có $tongSoViecNgay công việc trong ngày", 
                          style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: -40, top: -20,
                    child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05))),
                  )
                ],
              ),

              Transform.translate(
                offset: const Offset(0, -25),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Row(
                    children: ['Day', 'Week', 'Month'].map((mode) {
                      bool isSelected = _cheDoXem == mode;
                      String textHienThi = mode;
                      if (!isEng) {
                        if (mode == 'Day') textHienThi = 'Ngày';
                        if (mode == 'Week') textHienThi = 'Tuần';
                        if (mode == 'Month') textHienThi = 'Tháng';
                      }

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _cheDoXem = mode),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF1E65FF) : Colors.transparent, borderRadius: BorderRadius.circular(25)),
                            child: Center(
                              child: Text(textHienThi, style: TextStyle(color: isSelected ? Colors.white : subTextColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.chevron_left, color: subTextColor), onPressed: () => _chuyenTrang(-1)),
                      Text(_layTieuDeDieuHuong(isEng), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      IconButton(icon: Icon(Icons.chevron_right, color: subTextColor), onPressed: () => _chuyenTrang(1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: _cheDoXem == 'Month' 
                    ? _buildMonthView(tatCaCongViec, myLocale, cardColor, textColor, subTextColor, isDark)
                    : _cheDoXem == 'Week'
                        ? _buildWeekView(tatCaCongViec, isEng, cardColor, textColor, subTextColor, isDark)
                        : _buildDayView(tatCaCongViec, isEng, cardColor, textColor, subTextColor, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManHinhNhapLieu())),
        backgroundColor: const Color(0xFF1E65FF),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  String _layTieuDeDieuHuong(bool isEng) {
    if (_cheDoXem == 'Month') {
      return DateFormat('MMMM yyyy', isEng ? 'en_US' : 'vi_VN').format(_focusedDay);
    } else if (_cheDoXem == 'Week') {
      int offset = _focusedDay.weekday == 7 ? 0 : _focusedDay.weekday;
      DateTime startOfWeek = _focusedDay.subtract(Duration(days: offset));
      DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      String startStr = DateFormat('MMM d').format(startOfWeek);
      String endStr = DateFormat('MMM d, yyyy').format(endOfWeek);
      return "$startStr - $endStr";
    } else {
      return DateFormat('EEEE, MMMM d', isEng ? 'en_US' : 'vi_VN').format(_focusedDay);
    }
  }

  Widget _buildMonthView(List<CongViec> tatCaCongViec, String myLocale, Color cardColor, Color textColor, Color subTextColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: TableCalendar(
        locale: myLocale, 
        firstDay: DateTime.utc(2000, 1, 1),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        headerVisible: false, 
        selectedDayPredicate: (day) => isSameDay(_focusedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = selectedDay;
            _cheDoXem = 'Day'; 
          });
        },
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
        daysOfWeekStyle: DaysOfWeekStyle(weekdayStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold), weekendStyle: TextStyle(color: Colors.redAccent.shade200, fontWeight: FontWeight.bold)),
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: textColor), 
          weekendTextStyle: TextStyle(color: Colors.redAccent.shade200),
          outsideTextStyle: TextStyle(color: subTextColor.withOpacity(0.3)), 
          todayDecoration: BoxDecoration(color: const Color(0xFF1E65FF).withOpacity(0.2), shape: BoxShape.circle),
          todayTextStyle: const TextStyle(color: Color(0xFF1E65FF), fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(color: Color(0xFF1E65FF), shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          markerDecoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        ),
        eventLoader: (day) => _layCongViecTheoNgay(tatCaCongViec, day),
      ),
    );
  }

  Widget _buildWeekView(List<CongViec> tatCaCongViec, bool isEng, Color cardColor, Color textColor, Color subTextColor, bool isDark) {
    int offset = _focusedDay.weekday == 7 ? 0 : _focusedDay.weekday;
    DateTime startOfWeek = _focusedDay.subtract(Duration(days: offset));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 7,
      itemBuilder: (context, index) {
        DateTime day = startOfWeek.add(Duration(days: index));
        int taskCount = _layCongViecTheoNgay(tatCaCongViec, day).length;
        bool isToday = isSameDay(day, DateTime.now());

        return GestureDetector(
          onTap: () => setState(() { _focusedDay = day; _cheDoXem = 'Day'; }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor, 
              borderRadius: BorderRadius.circular(16), 
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 2))],
              border: isToday ? Border.all(color: const Color(0xFF1E65FF).withOpacity(0.5), width: 1.5) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300)),
                  child: Center(child: Text("${day.day}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isToday ? const Color(0xFF1E65FF) : textColor))),
                ),
                const SizedBox(width: 16),
                Text(DateFormat('EEEE', isEng ? 'en_US' : 'vi_VN').format(day), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                const Spacer(),
                Text(isEng ? "$taskCount tasks" : "$taskCount việc", style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDayView(List<CongViec> tatCaCongViec, bool isEng, Color cardColor, Color textColor, Color subTextColor, QuanLyCongViecProvider provider) {
    List<CongViec> danhSachCuaNgay = _layCongViecTheoNgay(tatCaCongViec, _focusedDay);

    if (danhSachCuaNgay.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Center(
            child: Text(isEng ? "No tasks scheduled for this day" : "Không có công việc nào trong ngày này", style: TextStyle(color: subTextColor, fontSize: 15)),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: danhSachCuaNgay.length,
      itemBuilder: (context, index) {
        final cv = danhSachCuaNgay[index];
        return ItemCongViecWidget(
          congViec: cv,
          onDoiTrangThai: (val) { cv.trangThai = val == true ? 1 : 0; provider.capNhatCongViec(cv); },
          onChon: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv))),
        );
      },
    );
  }
}