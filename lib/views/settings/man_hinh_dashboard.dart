import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/cai_dat_provider.dart';
import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../models/cong_viec.dart';

import '../home/item_cong_viec_widget.dart';
import '../task/man_hinh_chi_tiet.dart';

DateTime? phanTichNgay(String input) {
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

class ManHinhDashboard extends StatefulWidget {
  const ManHinhDashboard({Key? key}) : super(key: key);

  @override
  State<ManHinhDashboard> createState() => _ManHinhDashboardState();
}

class _ManHinhDashboardState extends State<ManHinhDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _tuKhoaTimKiem = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _moDanhSach(BuildContext context, String tieuDe, String loaiBoLoc) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ManHinhDanhSachChiTiet(tieuDe: tieuDe, loaiBoLoc: loaiBoLoc)));
  }

  @override
  Widget build(BuildContext context) {
    final caiDat = Provider.of<CaiDatProvider>(context);
    final isEng = caiDat.isEnglish;
    final isDark = caiDat.isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(isEng ? "Dashboard" : "Bảng thống kê", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: Consumer<QuanLyCongViecProvider>(
        builder: (context, provider, child) {
          final tasks = provider.danhSachCongViec;

          if (_tuKhoaTimKiem.isNotEmpty) {
            final keyword = _tuKhoaTimKiem.toLowerCase();
            List<CongViec> searchResults = tasks.where((t) {
              return t.tieuDe.toLowerCase().contains(keyword) || t.noiDung.toLowerCase().contains(keyword);
            }).toList();

            return Column(
              children: [
                _buildSearchBar(isEng, cardColor, textColor),
                Expanded(
                  child: searchResults.isEmpty
                      ? Center(child: Text(isEng ? "No tasks found" : "Không tìm thấy công việc", style: const TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: searchResults.length,
                          itemBuilder: (context, index) {
                            final cv = searchResults[index];
                            return ItemCongViecWidget(
                              congViec: cv,
                              onDoiTrangThai: (val) { cv.trangThai = val == true ? 1 : 0; provider.capNhatCongViec(cv); },
                              onChon: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv))),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          int tong = tasks.length;
          int hoanThanh = tasks.where((t) => t.trangThai == 1).length;
          int dangLam = tasks.where((t) => t.trangThai == 0).length;
          int tyLeHoanThanh = tong > 0 ? ((hoanThanh / tong) * 100).round() : 0;

          int viecHomNayChuaXong = 0;
          int viecHomNayHoanThanh = 0;
          int viecBoQua = 0; 
          
          final now = DateTime.now();
          final todayDate = DateTime(now.year, now.month, now.day); 
          
          for (var t in tasks) {
            DateTime? taskDate = phanTichNgay(t.ngayThucHien.toString());
            if (taskDate != null) {
              DateTime nDate = DateTime(taskDate.year, taskDate.month, taskDate.day);
              if (t.trangThai == 0) { 
                if (nDate.isBefore(todayDate)) viecBoQua++; 
                else if (nDate.isAtSameMomentAs(todayDate)) viecHomNayChuaXong++; 
              } else if (t.trangThai == 1) { 
                if (nDate.isAtSameMomentAs(todayDate)) viecHomNayHoanThanh++; 
              }
            }
          }

          // 🔥 MỚI: Danh sách các danh mục mặc định
          final List<String> defaultCats = ["Học tập", "Công việc", "Cá nhân", "Sức khỏe"];

          // 🔥 MỚI: Gom tất cả các danh mục tự gõ tay vào mục "Khác"
          Map<String, int> thongKeDanhMuc = {
            "Học tập": tasks.where((t) => t.danhMuc == "Học tập").length,
            "Công việc": tasks.where((t) => t.danhMuc == "Công việc").length,
            "Cá nhân": tasks.where((t) => t.danhMuc == "Cá nhân").length,
            "Sức khỏe": tasks.where((t) => t.danhMuc == "Sức khỏe").length,
            "Khác": tasks.where((t) => !defaultCats.contains(t.danhMuc)).length,
          };

          String statusTitle;
          String statusSub;
          Color statusColor;
          IconData statusIcon;

          if (tong == 0) {
            statusTitle = isEng ? "Ready to start?" : "Sẵn sàng làm việc?";
            statusSub = isEng ? "Tap + to add your first task." : "Nhấn + để tạo việc đầu tiên.";
            statusColor = Colors.blue;
            statusIcon = Icons.rocket_launch_rounded;
          } else if (viecBoQua > 0 && hoanThanh < dangLam) {
            statusTitle = isEng ? "Needs Attention" : "Cần bứt tốc hơn";
            statusSub = isEng ? "You have $viecBoQua missed tasks." : "Đang có $viecBoQua việc bị bỏ qua.";
            statusColor = Colors.redAccent;
            statusIcon = Icons.warning_amber_rounded;
          } else if (tyLeHoanThanh >= 80) {
            statusTitle = isEng ? "Outstanding!" : "Hiệu suất tuyệt vời!";
            statusSub = isEng ? "You've completed $tyLeHoanThanh% of tasks." : "Đã hoàn thành $tyLeHoanThanh% công việc.";
            statusColor = Colors.green;
            statusIcon = Icons.emoji_events_rounded;
          } else {
            statusTitle = isEng ? "On Track" : "Đang tiến triển tốt";
            statusSub = isEng ? "Keep up the momentum." : "Tiếp tục duy trì nhịp độ nhé.";
            statusColor = Colors.orange;
            statusIcon = Icons.trending_up_rounded;
          }

          return Column(
            children: [
              _buildSearchBar(isEng, cardColor, textColor),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), shape: BoxShape.circle),
                              child: Icon(statusIcon, color: statusColor, size: 36),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(statusTitle, style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(statusSub, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(isEng ? "Today's Snapshot" : "Thống kê hôm nay", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildSmallStatCard(title: isEng ? "Missed" : "Đã bỏ qua", value: "$viecBoQua", icon: Icons.schedule_outlined, color: Colors.redAccent, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "Missed" : "Quá hạn", 'missed')),
                            const SizedBox(width: 16),
                            _buildSmallStatCard(title: isEng ? "Pending" : "Cần làm\nHôm nay", value: "$viecHomNayChuaXong", icon: Icons.today, color: Colors.orange, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "Today" : "Hôm nay", 'today_pending')),
                            const SizedBox(width: 16),
                            _buildSmallStatCard(title: isEng ? "Done" : "Đã xong\nHôm nay", value: "$viecHomNayHoanThanh", icon: Icons.task_alt, color: Colors.green, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "Done Today" : "Hoàn thành", 'today_done')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(isEng ? "Overall Stats" : "Tổng quan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(title: isEng ? "Total" : "Tổng việc", value: "$tong", icon: Icons.assignment_outlined, color: Colors.blue, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "All" : "Tất cả", 'all'))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(title: isEng ? "Completed" : "Đã xong", value: "$hoanThanh", icon: Icons.check_circle_outline, color: Colors.green, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "Completed" : "Đã xong", 'completed'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatCard(title: isEng ? "Pending" : "Đang làm", value: "$dangLam", icon: Icons.pending_actions, color: Colors.orange, cardColor: cardColor, textColor: textColor, onTap: () => _moDanhSach(context, isEng ? "Pending" : "Đang làm", 'pending'))),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard(title: isEng ? "Categories" : "Danh mục", value: "5", icon: Icons.category_outlined, color: Colors.purple, cardColor: cardColor, textColor: textColor, onTap: null)), 
                        ],
                      ),
                      const SizedBox(height: 36),

                      Text(isEng ? "Tasks by Category" : "Phân bổ theo danh mục", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          children: [
                            _buildCategoryBar("Học tập", isEng ? "Study" : "Học tập", thongKeDanhMuc["Học tập"]!, tong, Colors.purple, textColor, onTap: () => _moDanhSach(context, isEng ? "Study" : "Học tập", 'cat_Học tập')),
                            _buildCategoryBar("Công việc", isEng ? "Work" : "Công việc", thongKeDanhMuc["Công việc"]!, tong, Colors.teal, textColor, onTap: () => _moDanhSach(context, isEng ? "Work" : "Công việc", 'cat_Công việc')),
                            _buildCategoryBar("Cá nhân", isEng ? "Personal" : "Cá nhân", thongKeDanhMuc["Cá nhân"]!, tong, Colors.pink, textColor, onTap: () => _moDanhSach(context, isEng ? "Personal" : "Cá nhân", 'cat_Cá nhân')),
                            _buildCategoryBar("Sức khỏe", isEng ? "Health" : "Sức khỏe", thongKeDanhMuc["Sức khỏe"]!, tong, Colors.redAccent, textColor, onTap: () => _moDanhSach(context, isEng ? "Health" : "Sức khỏe", 'cat_Sức khỏe')),
                            _buildCategoryBar("Khác", isEng ? "Other" : "Khác", thongKeDanhMuc["Khác"]!, tong, Colors.blueGrey, textColor, isLast: true, onTap: () => _moDanhSach(context, isEng ? "Other" : "Khác", 'cat_Khác')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isEng, Color cardColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _tuKhoaTimKiem = value),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: isEng ? "Search in all tasks..." : "Tìm nhanh công việc...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _tuKhoaTimKiem.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _tuKhoaTimKiem = '');
                  },
                )
              : null,
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color, required Color cardColor, required Color textColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 16),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard({required String title, required String value, required IconData icon, required Color color, required Color cardColor, required Color textColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 130, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String catKey, String label, int count, int total, Color color, Color textColor, {bool isLast = false, VoidCallback? onTap}) {
    if (total == 0) return const SizedBox(); 
    double ratio = count / total;
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 20), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 15)),
                  ],
                ),
                Row(
                  children: [
                    Text("$count  (${ (ratio * 100).toStringAsFixed(1) }%)", style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4), const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ratio, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 8)),
          ],
        ),
      ),
    );
  }
}

class ManHinhDanhSachChiTiet extends StatefulWidget {
  final String tieuDe;
  final String loaiBoLoc;

  const ManHinhDanhSachChiTiet({Key? key, required this.tieuDe, required this.loaiBoLoc}) : super(key: key);

  @override
  State<ManHinhDanhSachChiTiet> createState() => _ManHinhDanhSachChiTietState();
}

class _ManHinhDanhSachChiTietState extends State<ManHinhDanhSachChiTiet> {
  final TextEditingController _searchController = TextEditingController();
  String _tuKhoaTimKiem = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caiDat = Provider.of<CaiDatProvider>(context);
    final isEng = caiDat.isEnglish;
    final isDark = caiDat.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(widget.tieuDe, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _tuKhoaTimKiem = value),
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: isEng ? "Filter this list..." : "Lọc trong danh sách này...",
                prefixIcon: const Icon(Icons.filter_list, color: Colors.grey),
                suffixIcon: _tuKhoaTimKiem.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Colors.grey, size: 20), onPressed: () { _searchController.clear(); setState(() => _tuKhoaTimKiem = ''); }) : null,
                filled: true, fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: Consumer<QuanLyCongViecProvider>(
              builder: (context, provider, child) {
                List<CongViec> filteredList = [];
                final now = DateTime.now();
                final todayDate = DateTime(now.year, now.month, now.day);
                
                // 🔥 MỚI: Danh sách các danh mục mặc định để dùng cho phần filter
                final List<String> defaultCats = ["Học tập", "Công việc", "Cá nhân", "Sức khỏe"];

                for (var t in provider.danhSachCongViec) {
                  DateTime? taskDate = phanTichNgay(t.ngayThucHien.toString());
                  DateTime? nDate;
                  if (taskDate != null) nDate = DateTime(taskDate.year, taskDate.month, taskDate.day);

                  bool passLoc = false;
                  if (widget.loaiBoLoc == 'all') passLoc = true;
                  else if (widget.loaiBoLoc == 'completed') passLoc = t.trangThai == 1;
                  else if (widget.loaiBoLoc == 'pending') passLoc = t.trangThai == 0;
                  else if (widget.loaiBoLoc == 'missed') passLoc = t.trangThai == 0 && nDate != null && nDate.isBefore(todayDate);
                  else if (widget.loaiBoLoc == 'today_pending') passLoc = t.trangThai == 0 && nDate != null && nDate.isAtSameMomentAs(todayDate);
                  else if (widget.loaiBoLoc == 'today_done') passLoc = t.trangThai == 1 && nDate != null && nDate.isAtSameMomentAs(todayDate);
                  else if (widget.loaiBoLoc.startsWith('cat_')) {
                    // 🔥 MỚI: Xử lý lọc danh sách khi bấm vào thanh danh mục
                    String catType = widget.loaiBoLoc.substring(4);
                    if (catType == 'Khác') {
                      // Nếu chọn xem "Khác" -> Lọc tất cả những việc không thuộc 4 nhóm cơ bản
                      passLoc = !defaultCats.contains(t.danhMuc);
                    } else {
                      passLoc = t.danhMuc == catType;
                    }
                  }

                  if (passLoc && _tuKhoaTimKiem.isNotEmpty) {
                    final keyword = _tuKhoaTimKiem.toLowerCase();
                    if (!t.tieuDe.toLowerCase().contains(keyword) && !t.noiDung.toLowerCase().contains(keyword)) passLoc = false;
                  }

                  if (passLoc) filteredList.add(t);
                }

                filteredList.sort((a, b) {
                  int getPrio(String? m) { if (m == 'High') return 3; if (m == 'Medium') return 2; if (m == 'Low') return 1; return 0; }
                  return getPrio(b.mucDoUuTien).compareTo(getPrio(a.mucDoUuTien));
                });

                if (filteredList.isEmpty) return Center(child: Text(isEng ? "No tasks found" : "Không tìm thấy công việc nào", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)));

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 40), physics: const BouncingScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final cv = filteredList[index];
                    return ItemCongViecWidget(
                      congViec: cv,
                      onDoiTrangThai: (val) { cv.trangThai = val == true ? 1 : 0; provider.capNhatCongViec(cv); },
                      onChon: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManHinhChiTiet(congViec: cv))),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}