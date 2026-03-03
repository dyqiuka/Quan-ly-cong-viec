import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/cai_dat_provider.dart';
import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../models/cong_viec.dart';
import '../task/man_hinh_nhap_lieu.dart';
import '../task/man_hinh_chi_tiet.dart';
import 'item_cong_viec_widget.dart';
import '../settings/man_hinh_ho_so.dart';
import 'thanh_tien_do_lua_widget.dart'; // Widget chứa hiệu ứng lửa đã được tách riêng

class TrangChuView extends StatefulWidget {
  const TrangChuView({Key? key}) : super(key: key);

  @override
  State<TrangChuView> createState() => _TrangChuViewState();
}

class _TrangChuViewState extends State<TrangChuView> {
  // Controller cho thanh tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  String _loaiBoLoc = 'all'; 
  String _danhMucDuocChon = 'All';
  String _tuKhoaTimKiem = '';
  bool _hienThanhTimKiem = false;
  final List<String> _danhSachDanhMuc = ["All", "Học tập", "Công việc", "Cá nhân", "Sức khỏe", "Khác"];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Dịch danh mục
  String _dichDanhMuc(String cat, bool isEng) {
    if (!isEng) return cat;
    switch(cat) {
      case "Học tập": return "Study";
      case "Công việc": return "Work";
      case "Cá nhân": return "Personal";
      case "Sức khỏe": return "Health";
      case "Khác": return "Other";
      default: return cat;
    }
  }

  // Lời chào theo thời gian
  String _layLoiChao(bool isEng) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isEng ? "Good morning" : "Chào buổi sáng";
    if (hour < 17) return isEng ? "Good afternoon" : "Chào buổi chiều";
    return isEng ? "Good evening" : "Chào buổi tối";
  }

  // Mở Màn hình Hồ sơ người dùng
  void _moHoSoNguoiDung() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManHinhHoSo()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caiDat = Provider.of<CaiDatProvider>(context);
    final isEng = caiDat.isEnglish;
    final isDark = caiDat.isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF0F4FF);
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;

    String locale = isEng ? 'en_US' : 'vi_VN';
    String ngayHienTai = DateFormat('EEEE, d MMMM', locale).format(DateTime.now());

    // Lấy tên người dùng từ Firebase
    final user = FirebaseAuth.instance.currentUser;
    String tenNguoiDung = user?.displayName ?? (isEng ? "User" : "Bạn");

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<QuanLyCongViecProvider>(
        builder: (context, provider, child) {
          final tasks = provider.danhSachCongViec;
          final activeTasks = tasks.where((t) => t.trangThai == 0).toList();
          final completedTasks = tasks.where((t) => t.trangThai == 1).toList();

          // 🔥 BỘ TÍNH TOÁN NGÀY THÁNG (Giữ nguyên chuỗi dữ liệu để mốt dùng cho Dashboard)
          int viecHomNayChuaXong = 0;
          int viecHomNayHoanThanh = 0;
          int viecBoQua = 0; 
          int tongCon = activeTasks.length; // Tổng tất cả việc chưa làm (mọi thời điểm)
          
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day); 
          
          for (var t in tasks) {
            DateTime? taskDate;
            String input = t.ngayThucHien.toString().trim();

            if (input.isNotEmpty) {
              try {
                final parts = input.split(RegExp(r'[\s\/\-\.]'));
                List<int> nums = parts.where((p) => RegExp(r'^\d+$').hasMatch(p)).map((e) => int.parse(e)).toList();
                
                if (nums.length >= 3) {
                  int n1 = nums[0], n2 = nums[1], n3 = nums[2];
                  if (n1 > 1000) taskDate = DateTime(n1, n2, n3);
                  else if (n3 > 1000) taskDate = DateTime(n3, n2, n1);
                }
                taskDate ??= DateTime.tryParse(input);
              } catch (e) {}
            }

            if (taskDate != null) {
              DateTime nDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
              if (t.trangThai == 0) { 
                if (nDate.isBefore(todayDate)) {
                  viecBoQua++; 
                } else if (nDate.isAtSameMomentAs(todayDate)) {
                  viecHomNayChuaXong++; 
                }
              } else if (t.trangThai == 1) { 
                if (nDate.isAtSameMomentAs(todayDate)) {
                  viecHomNayHoanThanh++; 
                }
              }
            }
          }

          // 🔥 TÍNH TOÁN TỔNG TIẾN ĐỘ TOÀN BỘ CÔNG VIỆC
          int tongTatCaViec = tasks.length;
          int tongViecDaXong = completedTasks.length;
          int tongPhanTram = tongTatCaViec > 0 ? ((tongViecDaXong / tongTatCaViec) * 100).round() : 0;
          double progressValue = tongTatCaViec > 0 ? (tongViecDaXong / tongTatCaViec) : 0.0;
          
          // Cờ hiệu báo đạt 100% để hiển thị màu chữ Cam
          bool isFireActive = (tongTatCaViec > 0 && tongViecDaXong == tongTatCaViec);

          // LOGIC CHUẨN: BỘ LỌC 3 LỚP
          List<CongViec> filteredTasks = tasks.where((task) {
            if (_danhMucDuocChon != 'All' && task.danhMuc != _danhMucDuocChon) return false;
            if (_loaiBoLoc == 'active' && task.trangThai == 1) return false;
            if (_loaiBoLoc == 'completed' && task.trangThai == 0) return false;
            if (_tuKhoaTimKiem.isNotEmpty) {
              final keyword = _tuKhoaTimKiem.toLowerCase();
              return task.tieuDe.toLowerCase().contains(keyword) || 
                     task.noiDung.toLowerCase().contains(keyword);
            }
            return true;
          }).toList();

          return SafeArea(
            // TOÀN BỘ MÀN HÌNH KÉO ĐƯỢC
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(), 
              child: Column(
                children: [
                  // ── PHẦN HEADER ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ngayHienTai, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text("${_layLoiChao(isEng)}, $tenNguoiDung 👋", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
                                  const SizedBox(height: 12),
                                  
                                  // TÁCH 3 ĐẦU DÒNG CHUẨN
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEng ? "• Missed tasks: $viecBoQua" : "• Bạn đã bỏ qua: $viecBoQua việc", 
                                        style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.w600)
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isEng ? "• Today's tasks: $viecHomNayChuaXong" : "• Hôm nay cần làm: $viecHomNayChuaXong việc", 
                                        style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w600)
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isEng ? "• Total pending: $tongCon" : "• Tổng còn: $tongCon việc", 
                                        style: const TextStyle(color: Colors.white, fontSize: 13)
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(_hienThanhTimKiem ? Icons.close : Icons.search, color: Colors.white), 
                                  onPressed: () {
                                    setState(() {
                                      _hienThanhTimKiem = !_hienThanhTimKiem;
                                      if (!_hienThanhTimKiem) {
                                        _searchController.clear();
                                        _tuKhoaTimKiem = '';
                                      }
                                    });
                                  }
                                ),
                                GestureDetector(
                                  onTap: _moHoSoNguoiDung,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2), 
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      backgroundImage: user?.photoURL != null 
                                          ? NetworkImage(user!.photoURL!) 
                                          : null,
                                      child: user?.photoURL == null 
                                          ? const Icon(Icons.person, color: Colors.white, size: 20) 
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // 🔥 TỔNG TIẾN ĐỘ + GỌI WIDGET LỬA
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(isEng ? "Overall Progress" : "Tổng tiến độ", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  Text("$tongPhanTram%", style: TextStyle(color: isFireActive ? Colors.orangeAccent : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // 🔥 GỌI WIDGET THANH TIẾN ĐỘ LỬA TỪ FILE ĐÃ TÁCH
                              ThanhTienDoLuaWidget(progressValue: progressValue),
                              
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildTrangThaiCham(Colors.amberAccent, isEng ? "${activeTasks.length} Pending" : "${activeTasks.length} đang chờ"),
                                  const SizedBox(width: 16),
                                  _buildTrangThaiCham(Colors.greenAccent, isEng ? "${completedTasks.length} Done" : "${completedTasks.length} hoàn thành"),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // ── THANH TÌM KIẾM ──
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity, height: 0),
                    secondChild: Container(
                      padding: const EdgeInsets.all(16), 
                      color: cardColor,
                      child: TextField(
                        controller: _searchController, 
                        autofocus: true, 
                        onChanged: (value) => setState(() => _tuKhoaTimKiem = value),
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: isEng ? "Search..." : "Tìm kiếm...", 
                          hintStyle: TextStyle(color: subTextColor),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey), 
                          filled: true, 
                          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50, 
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                        ),
                      ),
                    ),
                    crossFadeState: _hienThanhTimKiem ? CrossFadeState.showSecond : CrossFadeState.showFirst, 
                    duration: const Duration(milliseconds: 300),
                  ),

                  // ── DANH SÁCH BÊN DƯỚI ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(isEng ? "Categories" : "Danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            TextButton.icon(
                              onPressed: () => setState(() => _loaiBoLoc = _loaiBoLoc == 'all' ? 'active' : _loaiBoLoc == 'active' ? 'completed' : 'all'),
                              icon: const Icon(Icons.tune, size: 16, color: Colors.blue),
                              label: Text(
                                _loaiBoLoc == 'all' ? (isEng ? "All" : "Tất cả") : _loaiBoLoc == 'active' ? (isEng ? "Active" : "Đang làm") : (isEng ? "Done" : "Đã xong"), 
                                style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)
                              ),
                            )
                          ],
                        ),
                        // Thanh ngang Categories
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, 
                            itemCount: _danhSachDanhMuc.length,
                            physics: const BouncingScrollPhysics(), 
                            itemBuilder: (context, index) {
                              String cat = _danhSachDanhMuc[index];
                              bool isSelected = _danhMucDuocChon == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false, 
                                  label: Text(_dichDanhMuc(cat, isEng)), 
                                  selected: isSelected, 
                                  onSelected: (_) => setState(() => _danhMucDuocChon = cat),
                                  selectedColor: Colors.blue.shade600, 
                                  backgroundColor: cardColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade600), 
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 13
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _loaiBoLoc == 'all' 
                              ? (isEng ? "All tasks (${filteredTasks.length})" : "Tất cả công việc (${filteredTasks.length})") 
                              : _loaiBoLoc == 'active' 
                                  ? (isEng ? "Active (${filteredTasks.length})" : "Đang làm (${filteredTasks.length})") 
                                  : (isEng ? "Completed (${filteredTasks.length})" : "Đã hoàn thành (${filteredTasks.length})"),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 10),
                        
                        // Danh sách công việc
                        filteredTasks.isEmpty 
                          ? _buildEmptyState(isEng, cardColor, textColor, subTextColor) 
                          : ListView.builder(
                              shrinkWrap: true, 
                              physics: const NeverScrollableScrollPhysics(), 
                              padding: const EdgeInsets.only(bottom: 80, top: 8), 
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final cv = filteredTasks[index];
                                return ItemCongViecWidget(
                                  congViec: cv,
                                  onDoiTrangThai: (val) { cv.trangThai = val == true ? 1 : 0; provider.capNhatCongViec(cv); },
                                  onChon: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv))),
                                );
                              },
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManHinhNhapLieu())),
        backgroundColor: Colors.blue.shade600, 
        elevation: 6, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildTrangThaiCham(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), 
        const SizedBox(width: 6), 
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))
      ]
    );
  }

  Widget _buildEmptyState(bool isEng, Color cardColor, Color textColor, Color subTextColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32), 
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, size: 32, color: Colors.blue.shade400)),
            const SizedBox(height: 16),
            Text(
              _tuKhoaTimKiem.isNotEmpty 
                  ? (isEng ? "No tasks found" : "Không tìm thấy công việc nào") 
                  : (isEng ? "No tasks yet" : "Chưa có công việc nào"), 
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              _tuKhoaTimKiem.isEmpty 
                  ? (isEng ? "Tap + to create a new task" : "Hãy bấm dấu + để tạo mới") 
                  : (isEng ? "Try a different keyword" : "Thử tìm kiếm với từ khóa khác"), 
              style: TextStyle(color: subTextColor, fontSize: 12)
            ),
          ],
        ),
      ),
    );
  }
}