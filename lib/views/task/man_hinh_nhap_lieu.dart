import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../models/cong_viec.dart';
import '../../services/dich_vu_thong_bao.dart';
import '../../providers/cai_dat_provider.dart';

class ManHinhNhapLieu extends StatefulWidget {
  final CongViec? congViec; 

  const ManHinhNhapLieu({super.key, this.congViec}); 

  @override
  State<ManHinhNhapLieu> createState() => _ManHinhNhapLieuState();
}

class _ManHinhNhapLieuState extends State<ManHinhNhapLieu> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _tieuDeController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();

  DateTime? _ngayChon;
  TimeOfDay? _gioChon;

  DateTime? _ngayNhacNho;
  TimeOfDay? _gioNhacNho;

  String _danhMucChon = 'Công việc';
  String _uuTienChon = 'Trung Bình'; 

  final List<String> _danhMucList = ["Học tập", "Công việc", "Cá nhân", "Sức khỏe", "Khác"];
  final List<String> _uuTienList = ["Thấp", "Trung Bình", "Cao"];

  @override
  void initState() {
    super.initState();
    if (widget.congViec != null) {
      _tieuDeController.text = widget.congViec!.tieuDe;
      _moTaController.text = widget.congViec!.noiDung;
      
      if (_danhMucList.contains(widget.congViec!.danhMuc)) {
        _danhMucChon = widget.congViec!.danhMuc!;
      }
      if (_uuTienList.contains(widget.congViec!.mucDoUuTien)) {
        _uuTienChon = widget.congViec!.mucDoUuTien!;
      }

      try {
        if (widget.congViec!.ngayThucHien.contains(' - ')) {
          List<String> parts = widget.congViec!.ngayThucHien.split(' - ');
          List<String> timeParts = parts[0].split(':');
          _gioChon = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
          List<String> dateParts = parts[1].split('/');
          _ngayChon = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
        }
      } catch (e) {
        debugPrint("Lỗi đọc ngày hoàn thành: $e");
      }

      try {
        if (widget.congViec!.thoiGianNhacNho != null && widget.congViec!.thoiGianNhacNho!.contains(' - ')) {
          List<String> parts = widget.congViec!.thoiGianNhacNho!.split(' - ');
          List<String> timeParts = parts[0].split(':');
          _gioNhacNho = TimeOfDay(hour: int.parse(timeParts[0]), minute: int.parse(timeParts[1]));
          List<String> dateParts = parts[1].split('/');
          _ngayNhacNho = DateTime(int.parse(dateParts[2]), int.parse(dateParts[1]), int.parse(dateParts[0]));
        }
      } catch (e) {
        debugPrint("Lỗi đọc ngày nhắc nhở: $e");
      }
    }
  }

  String _dichDanhMuc(String cat, bool isEn) {
    if (!isEn) return cat;
    switch (cat) {
      case "Học tập": return "Study";
      case "Công việc": return "Work";
      case "Cá nhân": return "Personal";
      case "Sức khỏe": return "Health";
      case "Khác": return "Other";
      default: return cat;
    }
  }

  String _dichUuTien(String pri, bool isEn) {
    if (!isEn) return pri;
    switch (pri) {
      case "Thấp": return "Low";
      case "Trung Bình": return "Medium";
      case "Cao": return "High";
      default: return pri;
    }
  }

  Future<void> _chonNgay(BuildContext context, bool laHanChot, bool isDark) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark 
              ? const ColorScheme.dark(primary: Colors.blue) 
              : ColorScheme.light(primary: Colors.blue.shade600),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (laHanChot) {
          _ngayChon = picked;
        } else {
          _ngayNhacNho = picked;
        }
      });
    }
  }

  Future<void> _chonGio(BuildContext context, bool laHanChot, bool isDark) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: isDark 
              ? const ColorScheme.dark(primary: Colors.blue) 
              : ColorScheme.light(primary: Colors.blue.shade600),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (laHanChot) {
          _gioChon = picked;
        } else {
          _gioNhacNho = picked;
        }
      });
    }
  }

  void _luuCongViec() async {
    final isEn = Provider.of<CaiDatProvider>(context, listen: false).isEnglish;

    if (_formKey.currentState!.validate()) {
      
      if (_ngayNhacNho != null && _ngayChon != null) {
        int gioBatDau = _gioNhacNho?.hour ?? 0;
        int phutBatDau = _gioNhacNho?.minute ?? 0;
        DateTime thoiGianBatDau = DateTime(
          _ngayNhacNho!.year, _ngayNhacNho!.month, _ngayNhacNho!.day, gioBatDau, phutBatDau
        );

        int gioKetThuc = _gioChon?.hour ?? 23; 
        int phutKetThuc = _gioChon?.minute ?? 59;
        DateTime thoiGianKetThuc = DateTime(
          _ngayChon!.year, _ngayChon!.month, _ngayChon!.day, gioKetThuc, phutKetThuc
        );

        if (thoiGianBatDau.isAfter(thoiGianKetThuc)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(isEn 
                        ? "Error: Start time cannot be after Completion time!" 
                        : "Lỗi: Thời gian bắt đầu không thể diễn ra sau Thời gian hoàn thành!")
                  ),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return; 
        }
      }

      String chuoiHanChot = widget.congViec?.ngayThucHien ?? DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now());
      if (_ngayChon != null) {
        String gio = _gioChon != null ? '${_gioChon!.hour.toString().padLeft(2, '0')}:${_gioChon!.minute.toString().padLeft(2, '0')}' : '00:00';
        chuoiHanChot = "$gio - ${DateFormat('dd/MM/yyyy').format(_ngayChon!)}";
      }

      String? chuoiNhacNho = widget.congViec?.thoiGianNhacNho;
      if (_ngayNhacNho != null) {
        String gioNhac = _gioNhacNho != null ? '${_gioNhacNho!.hour.toString().padLeft(2, '0')}:${_gioNhacNho!.minute.toString().padLeft(2, '0')}' : '00:00';
        chuoiNhacNho = "$gioNhac - ${DateFormat('dd/MM/yyyy').format(_ngayNhacNho!)}";
      }

      final cvLuu = CongViec(
        maCongViec: widget.congViec?.maCongViec,
        tieuDe: _tieuDeController.text.trim(),
        noiDung: _moTaController.text.trim(),
        ngayThucHien: chuoiHanChot, 
        thoiGianNhacNho: chuoiNhacNho, 
        trangThai: widget.congViec?.trangThai ?? 0,
        danhMuc: _danhMucChon,
        mucDoUuTien: _uuTienChon,
      );

      final provider = Provider.of<QuanLyCongViecProvider>(context, listen: false);
      
      if (widget.congViec == null) {
        provider.themMoiCongViec(cvLuu); 
      } else {
        provider.capNhatCongViec(cvLuu);
        if (widget.congViec!.maCongViec != null) {
          int idCu = widget.congViec!.maCongViec.hashCode; 
          await DichVuThongBao().huyThongBao(idCu);
        }
      }

      final caiDat = Provider.of<CaiDatProvider>(context, listen: false);

      if (_ngayNhacNho != null && _gioNhacNho != null && caiDat.isNotifEnabled) {
        DateTime thoiGianHen = DateTime(
          _ngayNhacNho!.year, _ngayNhacNho!.month, _ngayNhacNho!.day, 
          _gioNhacNho!.hour, _gioNhacNho!.minute
        );
        
        // 🔥 ĐÃ SỬA LỖI Ở ĐÂY: Tạo ID độc nhất không bao giờ trùng lặp
        int notifId = cvLuu.maCongViec != null 
            ? cvLuu.maCongViec.hashCode 
            : DateTime.now().millisecondsSinceEpoch.remainder(100000);

        String tieuDeThongBao = "";
        if (cvLuu.mucDoUuTien == 'Cao') {
          tieuDeThongBao = isEn ? "🔴 [URGENT] Start working now!" : "🔴 [QUAN TRỌNG] Bắt tay vào làm ngay!";
        } else if (cvLuu.mucDoUuTien == 'Trung Bình') {
          tieuDeThongBao = isEn ? "🟡 [Notice] It's time to work!" : "🟡 [Lưu ý] Đến giờ làm việc rồi!";
        } else {
          tieuDeThongBao = isEn ? "🟢 [Relax] Don't forget this task!" : "🟢 [Thong thả] Đừng quên nhiệm vụ này nhé!";
        }

        try {
          await DichVuThongBao().henGioThongBao(
            id: notifId,
            title: tieuDeThongBao, 
            body: "👉 ${cvLuu.tieuDe}", 
            thoiGian: thoiGianHen,
            payload: cvLuu.tieuDe,
          );
        } catch (e) {
          debugPrint("Lỗi báo thức: $e");
        }
      }

      if (mounted) Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.congViec == null 
              ? (isEn ? "Create new task" : "Tạo công việc mới") 
              : (isEn ? "Edit task" : "Sửa công việc"),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildLabel(isEn ? "Task title" : "Tiêu đề công việc", isDark, isRequired: true),
            TextFormField(
              controller: _tieuDeController,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(isEn ? "What needs to be done?" : "Cần làm việc gì?", isDark),
              validator: (value) => value == null || value.isEmpty 
                  ? (isEn ? 'Please enter a title' : 'Vui lòng nhập tiêu đề') 
                  : null,
            ),
            const SizedBox(height: 24),

            _buildLabel(isEn ? "Description" : "Mô tả", isDark),
            TextFormField(
              controller: _moTaController,
              maxLines: 4,
              style: TextStyle(color: textColor),
              decoration: _inputDecoration(isEn ? "Add detailed description..." : "Thêm mô tả chi tiết...", isDark),
            ),
            const SizedBox(height: 24),

            _buildLabel(isEn ? "Start time" : "Thời gian bắt đầu", isDark),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _chonNgay(context, false, isDark), 
                    child: _buildTimePickerBox(
                      _ngayNhacNho == null 
                          ? (isEn ? "Start date" : "Ngày bắt đầu") 
                          : DateFormat('dd/MM/yyyy').format(_ngayNhacNho!),
                      Icons.play_circle_outline,
                      _ngayNhacNho != null,
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _chonGio(context, false, isDark),
                    child: _buildTimePickerBox(
                      _gioNhacNho == null 
                          ? (isEn ? "Start time" : "Giờ bắt đầu") 
                          : _gioNhacNho!.format(context),
                      Icons.access_time,
                      _gioNhacNho != null,
                      isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildLabel(isEn ? "Completion time" : "Thời gian hoàn thành", isDark, isRequired: true),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _chonNgay(context, true, isDark), 
                    child: _buildTimePickerBox(
                      _ngayChon == null 
                          ? (isEn ? "End date" : "Ngày xong") 
                          : DateFormat('dd/MM/yyyy').format(_ngayChon!),
                      Icons.check_circle_outline,
                      _ngayChon != null,
                      isDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _chonGio(context, true, isDark), 
                    child: _buildTimePickerBox(
                      _gioChon == null 
                          ? (isEn ? "End time" : "Giờ xong") 
                          : _gioChon!.format(context),
                      Icons.timer_off_outlined,
                      _gioChon != null,
                      isDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Icon(Icons.sell_outlined, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                _buildLabel(isEn ? "Category" : "Danh mục", isDark),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _danhMucList.map((cat) {
                bool isSelected = _danhMucChon == cat;
                return ChoiceChip(
                  label: Text(_dichDanhMuc(cat, isEn)),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _danhMucChon = cat),
                  selectedColor: Colors.blue.shade600,
                  backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected 
                        ? Colors.white 
                        : (isDark ? Colors.grey[400] : Colors.grey.shade600),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), 
                    side: BorderSide(
                      color: isSelected 
                          ? Colors.transparent 
                          : (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                    )
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            _buildLabel(isEn ? "Priority" : "Mức độ ưu tiên", isDark),
            Row(
              children: _uuTienList.map((pri) {
                bool isSelected = _uuTienChon == pri;
                Color actColor = pri == 'Cao' 
                    ? Colors.red 
                    : pri == 'Trung Bình' 
                        ? const Color.fromARGB(255, 219, 132, 1) 
                        : Colors.green;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _uuTienChon = pri),
                    child: Container(
                      margin: EdgeInsets.only(right: pri != 'Cao' ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? actColor.withValues(alpha: 0.1) : (isDark ? Colors.grey[850] : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? actColor : (isDark ? Colors.grey.shade800 : Colors.grey.shade300), 
                          width: isSelected ? 1.5 : 1
                        ),
                      ),
                      child: Text(
                        _dichUuTien(pri, isEn),
                        style: TextStyle(
                          color: isSelected ? actColor : (isDark ? Colors.grey[400] : Colors.grey.shade600), 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _luuCongViec,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isEn ? "Save task" : "Lưu công việc", 
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerBox(String text, IconData icon, bool hasData, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(
          color: hasData 
              ? Colors.blue.shade300 
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
        )
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text, 
            style: TextStyle(
              color: hasData 
                  ? (isDark ? Colors.white : Colors.black87) 
                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade400), 
              fontSize: 14
            )
          ),
          Icon(
            icon, 
            size: 18, 
            color: hasData ? Colors.blue.shade600 : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text, 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontSize: 14, 
            fontWeight: FontWeight.w600
          ),
          children: [
            if (isRequired) const TextSpan(text: " *", style: TextStyle(color: Colors.red))
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) { 
    final fillColor = isDark ? Colors.grey[900] : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontSize: 14),
      filled: true, 
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5)),
    );
  }
}