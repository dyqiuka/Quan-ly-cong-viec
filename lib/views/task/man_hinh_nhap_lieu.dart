import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../models/cong_viec.dart';

class ManHinhNhapLieu extends StatefulWidget {
  final CongViec? congViec; // Truyền vào để sửa, null là thêm mới

  const ManHinhNhapLieu({Key? key, this.congViec}) : super(key: key);

  @override
  State<ManHinhNhapLieu> createState() => _ManHinhNhapLieuState();
}

class _ManHinhNhapLieuState extends State<ManHinhNhapLieu> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final TextEditingController _tieuDeController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();

  // Biến thời gian cho Hạn chót
  DateTime? _ngayChon;
  TimeOfDay? _gioChon;

  // 🔥 Biến thời gian cho Giờ nhắc nhở
  DateTime? _ngayNhacNho;
  TimeOfDay? _gioNhacNho;

  String _danhMucChon = 'Công việc';
  String _uuTienChon = 'Medium';

  final List<String> _danhMucList = ["Học tập", "Công việc", "Cá nhân", "Sức khỏe", "Khác"];
  final List<String> _uuTienList = ["Low", "Medium", "High"];

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu cũ vào Form nếu đang ở chế độ Sửa
    if (widget.congViec != null) {
      _tieuDeController.text = widget.congViec!.tieuDe;
      _moTaController.text = widget.congViec!.noiDung;
      
      // Load lại Danh mục và Ưu tiên (nếu model có hỗ trợ)
      // Giả sử model của bạn đã có 2 trường này:
      // _danhMucChon = widget.congViec!.danhMuc ?? 'Công việc';
      // _uuTienChon = widget.congViec!.mucDoUuTien ?? 'Medium';
      
      // Lưu ý: Phần bóc tách chuỗi ngày giờ để gán lại cho picker hơi phức tạp, 
      // nên tạm thời khi sửa việc, người dùng sẽ chọn lại ngày giờ mới nếu cần.
    }
  }

  // Hàm chọn Ngày (Dùng chung cho cả Hạn chót và Nhắc nhở)
  Future<void> _chonNgay(BuildContext context, bool laHanChot) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.blue.shade600)),
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

  // Hàm chọn Giờ (Dùng chung)
  Future<void> _chonGio(BuildContext context, bool laHanChot) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  // 🛠️ HÀM LƯU ĐÃ ĐƯỢC NÂNG CẤP ĐỂ XỬ LÝ 2 MỐC THỜI GIAN
  void _luuCongViec() {
    if (_formKey.currentState!.validate()) {
      
      // 1. Xử lý chuỗi Hạn chót (ngayThucHien)
      String chuoiHanChot = widget.congViec?.ngayThucHien ?? DateFormat('HH:mm - dd/MM/yyyy').format(DateTime.now());
      if (_ngayChon != null) {
        String gio = _gioChon != null ? '${_gioChon!.hour.toString().padLeft(2, '0')}:${_gioChon!.minute.toString().padLeft(2, '0')}' : '00:00';
        chuoiHanChot = "$gio - ${DateFormat('dd/MM/yyyy').format(_ngayChon!)}";
      }

      // 2. Xử lý chuỗi Giờ nhắc nhở (thoiGianNhacNho)
      String? chuoiNhacNho = widget.congViec?.thoiGianNhacNho;
      if (_ngayNhacNho != null) {
        String gioNhac = _gioNhacNho != null ? '${_gioNhacNho!.hour.toString().padLeft(2, '0')}:${_gioNhacNho!.minute.toString().padLeft(2, '0')}' : '00:00';
        chuoiNhacNho = "$gioNhac - ${DateFormat('dd/MM/yyyy').format(_ngayNhacNho!)}";
      }

      // 3. Tạo Object duy nhất mang theo TẤT CẢ dữ liệu
      final cvLuu = CongViec(
        maCongViec: widget.congViec?.maCongViec, // Nếu là thêm mới thì cái này sẽ là null
        tieuDe: _tieuDeController.text.trim(),
        noiDung: _moTaController.text.trim(),
        ngayThucHien: chuoiHanChot, 
        thoiGianNhacNho: chuoiNhacNho, 
        trangThai: widget.congViec?.trangThai ?? 0,
        danhMuc: _danhMucChon,
        mucDoUuTien: _uuTienChon,
      );

      final provider = Provider.of<QuanLyCongViecProvider>(context, listen: false);
      
      // 4. Phân nhánh logic RÕ RÀNG
      if (widget.congViec == null) {
        // Chế độ: THÊM MỚI
        provider.themMoiCongViec(cvLuu); 
      } else {
        // Chế độ: SỬA
        provider.capNhatCongViec(cvLuu);
      }
      
      // 5. Đóng màn hình
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.congViec == null ? "Tạo công việc mới" : "Sửa công việc",
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // ── Tiêu đề ──
            _buildLabel("Tiêu đề công việc", isRequired: true),
            TextFormField(
              controller: _tieuDeController,
              decoration: _inputDecoration("Cần làm việc gì?"),
              validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
            ),
            const SizedBox(height: 24),

            // ── Mô tả ──
            _buildLabel("Mô tả"),
            TextFormField(
              controller: _moTaController,
              maxLines: 4,
              decoration: _inputDecoration("Thêm mô tả chi tiết..."),
            ),
            const SizedBox(height: 24),

            // ── Khối 1: Hạn chót (Deadline) ──
            _buildLabel("Thời gian bắt đầu"),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _chonNgay(context, false), // Dùng biến phụ (_ngayNhacNho) làm ngày bắt đầu
                    child: _buildTimePickerBox(
                      _ngayNhacNho == null ? "Ngày bắt đầu" : DateFormat('dd/MM/yyyy').format(_ngayNhacNho!),
                      Icons.play_circle_outline,
                      _ngayNhacNho != null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _chonGio(context, false), // Dùng biến phụ (_gioNhacNho) làm giờ bắt đầu
                    child: _buildTimePickerBox(
                      _gioNhacNho == null ? "Giờ bắt đầu" : _gioNhacNho!.format(context),
                      Icons.access_time,
                      _gioNhacNho != null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Khối 2: Giờ hoàn thành (Bắt buộc) ──
            _buildLabel("Thời gian hoàn thành", isRequired: true),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _chonNgay(context, true), // Dùng biến chính (_ngayChon) làm ngày hoàn thành
                    child: _buildTimePickerBox(
                      _ngayChon == null ? "Ngày xong" : DateFormat('dd/MM/yyyy').format(_ngayChon!),
                      Icons.check_circle_outline,
                      _ngayChon != null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _chonGio(context, true), // Dùng biến chính (_gioChon) làm giờ hoàn thành
                    child: _buildTimePickerBox(
                      _gioChon == null ? "Giờ xong" : _gioChon!.format(context),
                      Icons.timer_off_outlined,
                      _gioChon != null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Danh mục ──
            Row(
              children: [
                Icon(Icons.sell_outlined, size: 18, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                _buildLabel("Danh mục"),
              ],
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _danhMucList.map((cat) {
                bool isSelected = _danhMucChon == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _danhMucChon = cat),
                  selectedColor: Colors.blue.shade600,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Mức độ ưu tiên ──
            _buildLabel("Mức độ ưu tiên"),
            Row(
              children: _uuTienList.map((pri) {
                bool isSelected = _uuTienChon == pri;
                Color actColor = pri == 'High' ? Colors.red : pri == 'Medium' ? const Color.fromARGB(255, 219, 132, 1) : Colors.green;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _uuTienChon = pri),
                    child: Container(
                      margin: EdgeInsets.only(right: pri != 'High' ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? actColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? actColor : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                      ),
                      child: Text(
                        pri,
                        style: TextStyle(color: isSelected ? actColor : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
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
      
      // ── Nút Lưu ──
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
              child: const Text("Lưu công việc", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
    );
  }

  // Khối Widget con giúp rút gọn code
  Widget _buildTimePickerBox(String text, IconData icon, bool hasData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: hasData ? Colors.blue.shade300 : Colors.grey.shade200)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(text, style: TextStyle(color: hasData ? Colors.black87 : Colors.grey.shade400, fontSize: 14)),
          Icon(icon, size: 18, color: hasData ? Colors.blue.shade600 : Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          text: text, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
          children: [if (isRequired) const TextSpan(text: " *", style: TextStyle(color: Colors.red))],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true, fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5)),
    );
  }
}