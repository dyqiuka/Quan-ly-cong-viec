import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/quan_ly_cong_viec_provider.dart';
import '../../services/dich_vu_firebase.dart';
import '../../services/ho_tro_sqlite.dart';
import '../auth/man_hinh_dang_nhap.dart';
import '../../providers/cai_dat_provider.dart';

class ManHinhSettings extends StatefulWidget {
  const ManHinhSettings({Key? key}) : super(key: key);

  @override
  State<ManHinhSettings> createState() => _ManHinhSettingsState();
}

class _ManHinhSettingsState extends State<ManHinhSettings> {
  bool _isNotifEnabled = true;
  bool _isReminderEnabled = true;
  bool _isLoadingDelete = false; // Trạng thái quay vòng vòng khi đang xóa data

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

  // ── HÀM 2: XÓA TOÀN BỘ DỮ LIỆU & TÀI KHOẢN (DANGER ZONE) ──
  void _xoaToanBoDuLieu(bool isEng, BuildContext context) {
    TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc phải bấm nút, không cho bấm ra ngoài
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Text(isEng ? "Delete Account" : "Xóa tài khoản", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEng 
                    ? "This action is irreversible. All your tasks will be permanently deleted from the cloud. Please enter your password to confirm."
                    : "Hành động này không thể hoàn tác. Toàn bộ dữ liệu của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống. Vui lòng nhập mật khẩu để xác nhận.",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEng ? "Password" : "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(isEng ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
            StatefulBuilder(
              builder: (context, setStateDialog) {
                return ElevatedButton(
                  onPressed: _isLoadingDelete ? null : () async {
                    String pass = passwordController.text.trim();
                    if (pass.isEmpty) {
                      _hienThongBao(isEng ? "Please enter your password!" : "Vui lòng nhập mật khẩu!");
                      return;
                    }

                    setStateDialog(() => _isLoadingDelete = true);

                    try {
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        // 1. Xác thực lại mật khẩu
                        AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: pass);
                        await user.reauthenticateWithCredential(credential);

                        // 2. Mật khẩu ĐÚNG -> Tiến hành xóa dữ liệu trên Firebase
                        var taskDocs = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('tasks').get();
                        for (var doc in taskDocs.docs) {
                          await doc.reference.delete();
                        }

                        // 3. Xóa dữ liệu trên SQLite (Máy hiện tại)
                        await HoTroSQLite().xoaTatCa();

                        // 4. Xóa luôn tài khoản Firebase Auth
                        await user.delete();

                        if (mounted) {
                          Navigator.pop(context); // Đóng hộp thoại
                          _hienThongBao(isEng ? "Account deleted successfully." : "Đã xóa tài khoản và dữ liệu.");
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManHinhDangNhap()));
                        }
                      }
                    } catch (e) {
                      setStateDialog(() => _isLoadingDelete = false);
                      _hienThongBao(isEng ? "Incorrect password. Please try again." : "Mật khẩu không đúng. Vui lòng thử lại.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoadingDelete 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(isEng ? "Delete Forever" : "Xóa vĩnh viễn", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      SnackBar(content: Text(thongBao), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? "chua_dang_nhap@email.com";
    final userName = userEmail.split('@').first;

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
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30, backgroundColor: Colors.white24,
                                backgroundImage: NetworkImage("https://ui-avatars.com/api/?name=$userName&background=random"),
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
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Positioned(
                      top: 190, left: 20, right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 5))]),
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

                      // --- THÔNG BÁO ---
                      _buildSectionTitle(isEng ? "NOTIFICATIONS" : "THÔNG BÁO"),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          _buildSwitchTile(
                            icon: Icons.notifications_active, iconColor: Colors.blue, bgColor: Colors.blue.shade50,
                            title: isEng ? "Notifications" : "Thông báo ứng dụng", subtitle: isEng ? "Enabled for all tasks" : "Bật cho tất cả công việc", textColor: textColor,
                            value: _isNotifEnabled, onChanged: (val) => setState(() => _isNotifEnabled = val),
                          ),
                          Divider(height: 1, indent: 60, color: Colors.grey.withOpacity(0.1)),
                          _buildSwitchTile(
                            icon: Icons.alarm, iconColor: Colors.purple, bgColor: Colors.purple.shade50,
                            title: isEng ? "Daily Reminder" : "Nhắc nhở hàng ngày", subtitle: isEng ? "Every day at 09:00" : "Mỗi ngày vào lúc 09:00 sáng", textColor: textColor,
                            value: _isReminderEnabled, onChanged: (val) => setState(() => _isReminderEnabled = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- DANGER ZONE (KHU VỰC NGUY HIỂM) ---
                      _buildSectionTitle(isEng ? "DANGER ZONE" : "KHU VỰC NGUY HIỂM", isDanger: true),
                      _buildSettingsCard(
                        cardColor: cardColor,
                        children: [
                          _buildActionTile(
                            icon: Icons.delete_forever, iconColor: Colors.red, bgColor: Colors.red.shade50,
                            title: isEng ? "Delete All Data & Account" : "Xóa toàn bộ Dữ liệu", 
                            subtitle: isEng ? "Permanently delete your account" : "Xóa vĩnh viễn tài khoản và công việc", 
                            textColor: Colors.red,
                            onTap: () => _xoaToanBoDuLieu(isEng, context), // 🔥 GỌI HÀM XÓA DỮ LIỆU
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