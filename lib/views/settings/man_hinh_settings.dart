import 'package:btl/views/home/man_hinh_chinh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../services/dich_vu_firebase.dart';
import '../../services/ho_tro_sqlite.dart';
import '../auth/man_hinh_dang_nhap.dart';
import '../../providers/cai_dat_provider.dart';

import 'man_hinh_ho_so.dart'; 
import 'man_hinh_dashboard.dart'; 

class ManHinhSettings extends StatefulWidget {
  const ManHinhSettings({Key? key}) : super(key: key);

  @override
  State<ManHinhSettings> createState() => _ManHinhSettingsState();
}

class _ManHinhSettingsState extends State<ManHinhSettings> {
  // Đã xóa bỏ dòng bool _isNotifEnabled = true; gây lỗi load lại tự bật
  bool _isLoadingDelete = false; 

  // ── HÀM 1: ĐĂNG XUẤT ──
  void _xuLyDangXuat(bool isEng) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEng ? "Log Out" : "Đăng xuất", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(isEng ? "Are you sure you want to log out?" : "Bạn có chắc chắn muốn đăng xuất?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isEng ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(isEng ? "Log Out" : "Đăng xuất", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await DichVuFirebase().dangXuat();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManHinhDangNhap()));
      }
    }
  }

  // ── HÀM 2: HIỂN THỊ MENU TÙY CHỌN XÓA ──
  void _hienThiMenuXoaDuLieu(bool isEng, BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 10),
                Text(isEng ? "Select Deletion Option" : "Chọn kiểu xóa dữ liệu", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.calendar_month, color: Colors.blue)),
                  title: Text(isEng ? "Delete tasks by specific date" : "Xóa công việc theo ngày đã chọn", style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _chonNgayDeXoa(isEng, context);
                  },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.delete_sweep, color: Colors.red)),
                  title: Text(isEng ? "Delete ALL tasks" : "Xóa TOÀN BỘ công việc", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _xacNhanXoaDuLieu(isEng, context, null); 
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  // ── HÀM 3: CHỌN NGÀY VÀ CHO XEM TRƯỚC DANH SÁCH VIỆC SẼ XÓA (ĐÃ SỬA LỖI MÙ TỊT) ──
  Future<void> _chonNgayDeXoa(bool isEng, BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Colors.red.shade600)),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      String strNgay = DateFormat('dd/MM/yyyy').format(picked);

      // Lấy danh sách công việc hiện có từ Provider để lọc
      final provider = Provider.of<QuanLyCongViecProvider>(context, listen: false);
      final viecTrongNgay = provider.danhSachCongViec.where((cv) {
        return (cv.ngayThucHien ?? '').contains(strNgay);
      }).toList();

      // Nếu ngày đó trống trơn
      if (viecTrongNgay.isEmpty) {
        _hienThongBao(isEng ? "No tasks found on $strNgay." : "Tuyệt vời! Ngày $strNgay không có việc nào để xóa cả.");
        return;
      }

      // Hiện hộp thoại danh sách các việc sẽ bị xóa
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEng ? "Tasks on $strNgay" : "Công việc ngày $strNgay", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: viecTrongNgay.length,
              itemBuilder: (c, i) => ListTile(
                leading: const Icon(Icons.circle, size: 10, color: Colors.redAccent),
                title: Text(viecTrongNgay[i].tieuDe, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isEng ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx); // Đóng preview
                _xacNhanXoaDuLieu(isEng, context, picked); // Tiếp tục gọi lệnh xóa
              },
              child: Text(isEng ? "Delete (${viecTrongNgay.length})" : "Xóa toàn bộ (${viecTrongNgay.length})", style: const TextStyle(color: Colors.white)),
            )
          ]
        )
      );
    }
  }

  // ── HÀM 4: XÓA VÀ TỰ ĐỘNG LOAD LẠI TRANG (ĐÃ SỬA LỖI PHẢI THOÁT APP) ──
  void _xacNhanXoaDuLieu(bool isEng, BuildContext context, DateTime? ngayXoa) {
    String strNgay = ngayXoa != null ? DateFormat('dd/MM/yyyy').format(ngayXoa) : "";
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (contextDialog) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(isEng ? "Confirm Deletion" : "Xác nhận xóa", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            ],
          ),
          content: Text(
            ngayXoa == null 
              ? (isEng ? "Are you sure you want to permanently delete ALL tasks?" : "Bạn có chắc chắn muốn xóa vĩnh viễn TOÀN BỘ công việc không?")
              : (isEng ? "Delete all tasks scheduled on $strNgay?" : "Bạn muốn xóa toàn bộ công việc trong ngày $strNgay?"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contextDialog), child: Text(isEng ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
            StatefulBuilder(
              builder: (context, setStateBtn) {
                return ElevatedButton(
                  onPressed: _isLoadingDelete ? null : () async {
                    setStateBtn(() => _isLoadingDelete = true);

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        var taskCollection = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('tasks');
                        var taskDocs = await taskCollection.get();

                        int count = 0;
                        if (ngayXoa == null) {
                          // 1. XÓA TẤT CẢ
                          for (var doc in taskDocs.docs) { await doc.reference.delete(); }
                          try { await HoTroSQLite().xoaTatCa(); } catch(e){} 
                          count = taskDocs.docs.length;
                        } else {
                          // 2. XÓA THEO NGÀY
                          for (var doc in taskDocs.docs) {
                            String ngayThucHien = doc.data()['ngayThucHien'] ?? '';
                            if (ngayThucHien.contains(strNgay)) {
                              await doc.reference.delete();
                              count++;
                            }
                          }
                        }

                        if (mounted) {
                          Navigator.pop(contextDialog); // Đóng popup
                          _hienThongBao(isEng ? "Deleted $count tasks successfully." : "Đã xóa thành công $count công việc.");
                          
                          // 🔥 ĐÂY LÀ ĐOẠN F5 LẠI APP MÀ KHÔNG CẦN THOÁT RA VÀO LẠI 🔥
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const ManHinhChinh()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      }
                    } catch (e) {
                      _hienThongBao(isEng ? "Error deleting tasks." : "Có lỗi xảy ra khi xóa dữ liệu.");
                    } finally {
                      setStateBtn(() => _isLoadingDelete = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: _isLoadingDelete 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEng ? "Delete" : "Xóa", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }
            ),
          ],
        );
      },
    );
  }

  void _hienThongBao(String thongBao) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(thongBao), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 4)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "chua_dang_nhap@email.com";
    final userName = user?.displayName ?? userEmail.split('@').first; 

    final caiDat = Provider.of<CaiDatProvider>(context);
    final isEng = caiDat.isEnglish;
    final isDark = caiDat.isDarkMode;

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF4F7FC);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<QuanLyCongViecProvider>(
        builder: (context, provider, child) {
          final tasks = provider.danhSachCongViec;
          final total = tasks.length;
          final active = tasks.where((t) => t.trangThai == 0).length;
          final done = tasks.where((t) => t.trangThai == 1).length;
          final percent = total == 0 ? 0 : ((done / total) * 100).round();

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── 1. HEADER & THẺ THỐNG KÊ ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity, height: 240,
                      padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isEng ? "Settings" : "Cài đặt", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 20),
                          
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManHinhHoSo())),
                            child: Container(
                              color: Colors.transparent, 
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30, backgroundColor: Colors.white24,
                                    backgroundImage: user?.photoURL != null 
                                        ? NetworkImage(user!.photoURL!)
                                        : NetworkImage("https://ui-avatars.com/api/?name=$userName&background=random") as ImageProvider,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                        const SizedBox(height: 4),
                                        Text(userEmail, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                        const SizedBox(height: 4),
                                        Text(isEng ? "$total tasks • $percent% done" : "$total công việc • hoàn thành $percent%", style: const TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white70) 
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    
                    Positioned(
                      top: 190, left: 20, right: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManHinhDashboard())),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: cardColor, 
                            borderRadius: BorderRadius.circular(16), 
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(total.toString(), isEng ? "Total" : "Tổng", isDark ? Colors.blue.shade300 : Colors.blue.shade700, textColor),
                              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                              _buildStatItem(active.toString(), isEng ? "Active" : "Đang làm", isDark ? Colors.orange.shade300 : Colors.orange.shade700, textColor),
                              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                              _buildStatItem(done.toString(), isEng ? "Done" : "Đã xong", isDark ? Colors.green.shade300 : Colors.green.shade700, textColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),

                // ── 2. CÁC MỤC CÀI ĐẶT ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- NGÔN NGỮ ---
                      _buildSectionTitle(isEng ? "LANGUAGE" : "NGÔN NGỮ"),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                              _buildSwitchTile(
                                icon: Icons.language, iconColor: Colors.teal, bgColor: Colors.teal.shade50,
                                title: isEng ? "English" : "Tiếng Anh", subtitle: isEng ? "App language is set to English" : "Đang sử dụng Tiếng Việt", textColor: textColor,
                                value: isEng, onChanged: (val) => caiDat.doiNgonNgu(val),
                              ),
                          ],
                      ),
                      const SizedBox(height: 24),

                      // --- GIAO DIỆN ---
                      _buildSectionTitle(isEng ? "APPEARANCE" : "GIAO DIỆN"),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          _buildSwitchTile(
                            icon: Icons.light_mode, iconColor: Colors.orange, bgColor: Colors.orange.shade50,
                            title: isEng ? "Dark Mode" : "Chế độ tối", subtitle: isDark ? (isEng ? "Dark theme active" : "Đang bật nền tối") : (isEng ? "Light theme active" : "Đang dùng nền sáng"), textColor: textColor,
                            value: isDark, onChanged: (val) => caiDat.doiGiaoDien(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- THÔNG BÁO (ĐÃ KẾT NỐI VỚI PROVIDER) ---
                      _buildSectionTitle(isEng ? "NOTIFICATIONS" : "THÔNG BÁO"),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_active, iconColor: Colors.blue, bgColor: Colors.blue.shade50,
                            title: isEng ? "App Notifications" : "Thông báo ứng dụng", subtitle: isEng ? "Allow task reminders" : "Cho phép app réo chuông báo đến hạn", textColor: textColor,
                            value: caiDat.isNotifEnabled, // Đã lấy đúng trạng thái
                            onChanged: (val) => caiDat.doiThongBao(val), // Đã lưu đúng trạng thái
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- QUẢN LÝ DỮ LIỆU ---
                      _buildSectionTitle(isEng ? "DATA MANAGEMENT" : "QUẢN LÝ DỮ LIỆU", isDanger: true),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          _buildActionTile(
                            icon: Icons.delete_outline, iconColor: Colors.red, bgColor: Colors.red.shade50,
                            title: isEng ? "Delete Tasks" : "Xóa dữ liệu công việc", 
                            subtitle: isEng ? "Delete all tasks or by specific date" : "Xóa toàn bộ hoặc xóa theo ngày bạn chọn", 
                            textColor: Colors.red,
                            onTap: () => _hienThiMenuXoaDuLieu(isEng, context), 
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- NÚT ĐĂNG XUẤT ---
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          ListTile(
                            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.logout, color: Colors.grey)),
                            title: Text(isEng ? "Log Out" : "Đăng xuất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () => _xuLyDangXuat(isEng),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String number, String label, Color numberColor, Color textColor) {
    return Column(
      children: [
        Text(number, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: numberColor)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDanger ? Colors.redAccent : Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children, required Color cardColor}) {
    return Container(
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required bool value, required Function(bool) onChanged, required Color textColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5))),
      trailing: Switch(value: value, activeColor: Colors.blue.shade600, onChanged: onChanged),
    );
  }

  Widget _buildActionTile({required IconData icon, required Color iconColor, required Color bgColor, required String title, required String subtitle, required VoidCallback onTap, required Color textColor}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}