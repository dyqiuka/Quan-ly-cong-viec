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
import 'thanh_tien_do_lua_widget.dart';

class TrangChuView extends StatefulWidget {
  const TrangChuView({Key? key}) : super(key: key);

  @override
  State<TrangChuView> createState() => _TrangChuViewState();
}

class _TrangChuViewState extends State<TrangChuView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  String _danhMucDuocChon = 'All';
  String _tuKhoaTimKiem = '';
  bool _hienThanhTimKiem = false;
  final List<String> _danhSachDanhMuc = ["All", "Học tập", "Công việc", "Cá nhân", "Sức khỏe", "Khác"];

  late AnimationController _pulseController;

  final GlobalKey _keyQuaHan = GlobalKey();
  final GlobalKey _keyHomNay = GlobalKey();
  String _mucDangHighlight = 'All'; 

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cuonDenMuc(GlobalKey key, String muc) {
    setState(() {
      _mucDangHighlight = _mucDangHighlight == muc ? 'All' : muc;
    });

    if (_mucDangHighlight != 'All' && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.1, 
      );
    }
  }

  String _dichDanhMuc(String cat, bool isEng) {
    if (!isEng) return cat;
    switch (cat) {
      case "Học tập": return "Study";
      case "Công việc": return "Work";
      case "Cá nhân": return "Personal";
      case "Sức khỏe": return "Health";
      case "Khác": return "Other";
      default: return cat;
    }
  }

  String _layLoiChao(bool isEng) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isEng ? "Good morning" : "Chào buổi sáng";
    if (hour < 17) return isEng ? "Good afternoon" : "Chào buổi chiều";
    return isEng ? "Good evening" : "Chào buổi tối";
  }

  DateTime? _phanTichNgay(String input) {
    if (input.trim().isEmpty) return null;
    try {
      final parts = input.trim().split(RegExp(r'[\s\/\-\.]'));
      List<int> nums = parts.where((p) => RegExp(r'^\d+$').hasMatch(p)).map((e) => int.parse(e)).toList();
      if (nums.length >= 3) {
        int n1 = nums[0], n2 = nums[1], n3 = nums[2];
        if (n1 > 1000) return DateTime(n1, n2, n3);
        if (n3 > 1000) return DateTime(n3, n2, n1);
      }
      return DateTime.tryParse(input.trim());
    } catch (e) {
      return null;
    }
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
    final user = FirebaseAuth.instance.currentUser;
    String tenNguoiDung = user?.displayName ?? (isEng ? "User" : "Bạn");

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<QuanLyCongViecProvider>(
        builder: (context, provider, child) {
          
          // Lấy danh sách gốc từ Provider
          final rawTasks = provider.danhSachCongViec;

          // 🔥 BƯỚC QUAN TRỌNG: SẮP XẾP THEO ĐỘ ƯU TIÊN (High -> Medium -> Low)
          List<CongViec> tasks = List.from(rawTasks);
          tasks.sort((a, b) {
            int getPriorityScore(String? mucDo) {
              if (mucDo == 'High') return 3;
              if (mucDo == 'Medium') return 2;
              if (mucDo == 'Low') return 1;
              return 0; // Không có mức độ
            }
            // Xếp giảm dần (Điểm cao nằm trên)
            return getPriorityScore(b.mucDoUuTien).compareTo(getPriorityScore(a.mucDoUuTien));
          });

          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day);
          final tomorrowDate = todayDate.add(const Duration(days: 1));

          // 1. DỮ LIỆU THỐNG KÊ (Cho khối Tiến độ ở trên)
          int viecHomNayTong = 0;
          int viecHomNayDaXong = 0;
          int viecBoQua = 0;
          int tongCon = tasks.where((t) => t.trangThai == 0).length;

          // 2. DỮ LIỆU NHÓM (Chỉ chứa việc CHƯA LÀM)
          List<CongViec> groupQuaHan = [];
          List<CongViec> groupHomNay = [];
          List<CongViec> groupNgayMai = [];
          List<CongViec> groupSapToi = [];
          List<CongViec> groupKhongNgay = [];
      
          // LỌC VÀ CHIA NHÓM
          for (var t in tasks) {
            DateTime? taskDate = _phanTichNgay(t.ngayThucHien.toString());

            // --- BƯỚC 1: TÍNH THỐNG KÊ TRÊN HEADER (Đếm cả việc đã xong) ---
            if (taskDate != null) {
              DateTime nDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
              if (t.trangThai == 0 && nDate.isBefore(todayDate)) viecBoQua++;
              if (nDate.isAtSameMomentAs(todayDate)) {
                viecHomNayTong++;
                if (t.trangThai == 1) viecHomNayDaXong++;
              }
            }

            // --- BƯỚC 2: ẨN VIỆC ĐÃ XONG KHỎI TRANG CHỦ ---
            if (t.trangThai == 1) continue;

            // --- BƯỚC 3: KIỂM TRA BỘ LỌC TÌM KIẾM ---
            bool passFilter = true;
            if (_danhMucDuocChon != 'All' && t.danhMuc != _danhMucDuocChon) passFilter = false;
            if (_tuKhoaTimKiem.isNotEmpty) {
              final keyword = _tuKhoaTimKiem.toLowerCase();
              if (!t.tieuDe.toLowerCase().contains(keyword) && !t.noiDung.toLowerCase().contains(keyword)) passFilter = false;
            }

            // --- BƯỚC 4: ĐƯA VIỆC VÀO TỪNG NHÓM ---
            if (passFilter) {
              if (taskDate == null) {
                groupKhongNgay.add(t);
              } else {
                DateTime nDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
                if (nDate.isBefore(todayDate)) {
                  groupQuaHan.add(t);
                } else if (nDate.isAtSameMomentAs(todayDate)) {
                  groupHomNay.add(t);
                } else if (nDate.isAtSameMomentAs(tomorrowDate)) {
                  groupNgayMai.add(t);
                } else if (nDate.isAfter(tomorrowDate)) {
                  groupSapToi.add(t);
                }
              }
            }
          }

          int percentHomNay = viecHomNayTong > 0 ? ((viecHomNayDaXong / viecHomNayTong) * 100).round() : 0;
          double progressHomNay = viecHomNayTong > 0 ? (viecHomNayDaXong / viecHomNayTong) : 0.0;
          bool isFireActive = (viecHomNayTong > 0 && viecHomNayDaXong == viecHomNayTong);

          return SafeArea(
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
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
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
                                  Text(ngayHienTai, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text("${_layLoiChao(isEng)}, $tenNguoiDung 👋", style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 12),
                                  
                                  // 🔥 3 DÒNG THỐNG KÊ (BIẾN THÀNH NÚT BẤM CÓ TƯƠNG TÁC)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildClickableBullet(
                                        text: isEng ? "• Missed tasks: $viecBoQua" : "• Đã bỏ qua: $viecBoQua việc",
                                        color: Colors.orangeAccent,
                                        isActive: _mucDangHighlight == 'QuaHan',
                                        onTap: () => _cuonDenMuc(_keyQuaHan, 'QuaHan'),
                                      ),
                                      _buildClickableBullet(
                                        text: isEng ? "• Today's tasks: $viecHomNayTong" : "• Hôm nay cần làm: $viecHomNayTong việc",
                                        color: Colors.greenAccent,
                                        isActive: _mucDangHighlight == 'HomNay',
                                        onTap: () => _cuonDenMuc(_keyHomNay, 'HomNay'),
                                      ),
                                      _buildClickableBullet(
                                        text: isEng ? "• Total pending: $tongCon" : "• Tổng còn: $tongCon việc",
                                        color: Colors.white,
                                        isActive: _mucDangHighlight == 'All', 
                                        onTap: () {
                                          setState(() => _mucDangHighlight = 'All');
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
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
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManHinhHoSo())),
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                    child: CircleAvatar(
                                      radius: 16, backgroundColor: Colors.white.withOpacity(0.3),
                                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                                      child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 🔥 KHỐI TIẾN ĐỘ HÔM NAY
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isFireActive ? [BoxShadow(color: Colors.orangeAccent.withOpacity(0.3), blurRadius: 10)] : [],
                            border: isFireActive ? Border.all(color: Colors.orangeAccent.withOpacity(0.8), width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(isEng ? "Today's Mission" : "Nhiệm vụ hôm nay", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  
                                  Row(
                                    children: [
                                      Text("$percentHomNay%", style: TextStyle(color: isFireActive ? Colors.orangeAccent : Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: isFireActive ? 1.0 + (_pulseController.value * 0.2) : 1.0,
                                            child: Icon(
                                              Icons.local_fire_department_rounded,
                                              size: 24,
                                              color: isFireActive ? Colors.orangeAccent : Colors.white30,
                                              shadows: isFireActive ? [Shadow(color: Colors.redAccent, blurRadius: 10 * _pulseController.value)] : [],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ThanhTienDoLuaWidget(progressValue: progressHomNay),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _buildTrangThaiCham(Colors.amberAccent, isEng ? "${viecHomNayTong - viecHomNayDaXong} Pending" : "${viecHomNayTong - viecHomNayDaXong} đang chờ"),
                                  const SizedBox(width: 16),
                                  _buildTrangThaiCham(Colors.greenAccent, isEng ? "$viecHomNayDaXong Done" : "$viecHomNayDaXong hoàn thành"),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // ── THANH TÌM KIẾM ──
                  if (_hienThanhTimKiem) Container(
                    padding: const EdgeInsets.all(16), color: cardColor,
                    child: TextField(
                      controller: _searchController, autofocus: true,
                      onChanged: (value) => setState(() => _tuKhoaTimKiem = value),
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: isEng ? "Search..." : "Tìm kiếm...",
                        prefixIcon: const Icon(Icons.search, color: Colors.grey), filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)
                      ),
                    ),
                  ),

                  // ── DANH SÁCH CHIA NHÓM (GROUP BY DATE) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // --- CATEGORIES HORIZONTAL BAR ---
                        Row(
                          children: [
                            Text(isEng ? "Categories" : "Danh mục", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 36,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, itemCount: _danhSachDanhMuc.length,
                            itemBuilder: (context, index) {
                              String cat = _danhSachDanhMuc[index];
                              bool isSelected = _danhMucDuocChon == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  showCheckmark: false, label: Text(_dichDanhMuc(cat, isEng)),
                                  selected: isSelected, onSelected: (_) => setState(() => _danhMucDuocChon = cat),
                                  selectedColor: Colors.blue.shade600, backgroundColor: cardColor,
                                  labelStyle: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey.shade600), fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade300))),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        // --- HIỂN THỊ DANH SÁCH THEO TỪNG NHÓM ---
                        if (groupQuaHan.isEmpty && groupHomNay.isEmpty && groupNgayMai.isEmpty && groupSapToi.isEmpty && groupKhongNgay.isEmpty)
                          _buildEmptyState(isEng, cardColor, textColor, subTextColor)
                        else ...[
                          _buildTaskGroup(groupQuaHan, isEng ? "Overdue / Missed" : "Đã bỏ qua / Quá hạn", Colors.redAccent, _keyQuaHan, 'QuaHan', provider),
                          _buildTaskGroup(groupHomNay, isEng ? "Today" : "Hôm nay", Colors.green, _keyHomNay, 'HomNay', provider),
                          _buildTaskGroup(groupNgayMai, isEng ? "Tomorrow" : "Ngày mai", Colors.blue, null, 'NgayMai', provider),
                          _buildTaskGroup(groupSapToi, isEng ? "Upcoming" : "Sắp tới", Colors.purple, null, 'SapToi', provider),
                          _buildTaskGroup(groupKhongNgay, isEng ? "No Date" : "Chưa lên lịch", Colors.grey, null, 'KhongNgay', provider),
                          const SizedBox(height: 80),
                        ]
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
        backgroundColor: Colors.blue.shade600, elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  // --- WIDGET DÒNG GẠCH ĐẦU DÒNG CÓ THỂ BẤM ĐƯỢC ---
  Widget _buildClickableBullet({required String text, required Color color, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          padding: EdgeInsets.only(right: 8, left: isActive ? 6 : 0), 
          child: Text(text, style: TextStyle(color: color, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.w600)),
        ),
      ),
    );
  }

  // --- WIDGET RENDER NHÓM CÔNG VIỆC CÓ LÀM MỜ ---
  Widget _buildTaskGroup(List<CongViec> tasks, String title, Color titleColor, GlobalKey? key, String groupID, QuanLyCongViecProvider provider) {
    if (tasks.isEmpty) return const SizedBox(); 

    // 🔥 Logic Hiệu ứng ánh sáng: Nếu đang highlight 1 mục mà mục này không khớp -> Làm mờ (0.3). Ngược lại sáng (1.0)
    double opacity = (_mucDangHighlight == 'All' || _mucDangHighlight == groupID) ? 1.0 : 0.3;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: Column(
        key: key, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: titleColor),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: titleColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text("${tasks.length}", style: TextStyle(color: titleColor, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final cv = tasks[index];
              return ItemCongViecWidget(
                congViec: cv,
                onDoiTrangThai: (val) { 
                  cv.trangThai = val == true ? 1 : 0; 
                  provider.capNhatCongViec(cv); 
                },
                onChon: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv))),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrangThaiCham(Color color, String text) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), 
      const SizedBox(width: 6), Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12))
    ]);
  }

  Widget _buildEmptyState(bool isEng, Color cardColor, Color textColor, Color subTextColor) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        padding: const EdgeInsets.all(32), 
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.check_circle_outline, size: 32, color: Colors.blue.shade400)),
            const SizedBox(height: 16),
            Text(isEng ? "All caught up!" : "Hoàn thành xuất sắc!", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(isEng ? "Tap + to create a new task" : "Bấm dấu + để thêm việc mới nhé", style: TextStyle(color: subTextColor, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}