import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

import '../../services/dich_vu_firebase.dart';
import '../auth/man_hinh_dang_nhap.dart';
import '../../providers/cai_dat_provider.dart';

class ManHinhHoSo extends StatefulWidget {
  const ManHinhHoSo({super.key}); 

  @override
  State<ManHinhHoSo> createState() => _ManHinhHoSoState();
}

class _ManHinhHoSoState extends State<ManHinhHoSo> {
  User? _user;
  final DichVuFirebase _dichVuFirebase = DichVuFirebase();

  String _ngaySinh = "Chưa cập nhật";
  String _gioiTinh = "Chưa cập nhật";

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _taiThongTinTuFirestore(); 
  }

  String _hienThiGioiTinh(String gt, bool isEn) {
    if (gt == "Chưa cập nhật") return isEn ? "Not updated" : "Chưa cập nhật";
    if (!isEn) return gt;
    if (gt == 'Nam') return 'Male';
    if (gt == 'Nữ') return 'Female';
    if (gt == 'Khác') return 'Other';
    return gt;
  }

  Future<void> _taiThongTinTuFirestore() async {
    if (_user == null) return;
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _ngaySinh = doc.get('ngaySinh') ?? "Chưa cập nhật";
          _gioiTinh = doc.get('gioiTinh') ?? "Chưa cập nhật";
        });
      }
    } catch (e) {
      debugPrint("Chưa có dữ liệu Firestore: $e");
    }
  }

  Future<void> _capNhatFirestore(String truong, String giaTri) async {
    if (_user == null) return;
    final isEn = context.read<CaiDatProvider>().isEnglish;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        truong: giaTri
      }, SetOptions(merge: true)); 
      _taiThongTinTuFirestore(); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Error saving data: $e" : "Lỗi lưu dữ liệu: $e")));
    }
  }

  void _doiTenNguoiDung() {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    TextEditingController tenController = TextEditingController(text: _user?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEn ? "Change Display Name" : "Đổi tên hiển thị", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tenController,
          decoration: InputDecoration(hintText: isEn ? "Enter new name" : "Nhập tên mới", border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEn ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (tenController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _user?.updateDisplayName(tenController.text.trim());
                await _user?.reload();
                setState(() => _user = FirebaseAuth.instance.currentUser);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Name updated!" : "Đã cập nhật tên!")));
              }
            },
            child: Text(isEn ? "Save" : "Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> _chonNgaySinh() async {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: isEn ? "SELECT DATE OF BIRTH" : "CHỌN NGÀY SINH",
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      await _capNhatFirestore('ngaySinh', formattedDate);
    }
  }

  void _chonGioiTinh() {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEn ? "Select Gender" : "Chọn giới tính", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(isEn ? "Male" : "Nam"), leading: const Icon(Icons.male, color: Colors.blue), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Nam'); }),
            ListTile(title: Text(isEn ? "Female" : "Nữ"), leading: const Icon(Icons.female, color: Colors.pink), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Nữ'); }),
            ListTile(title: Text(isEn ? "Other" : "Khác"), leading: const Icon(Icons.transgender, color: Colors.purple), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Khác'); }),
          ],
        ),
      ),
    );
  }

  void _doiAnhDaiDien() {
    final isEn = context.read<CaiDatProvider>().isEnglish;
    TextEditingController linkAnhController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEn ? "Update Avatar" : "Cập nhật ảnh đại diện", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: linkAnhController,
          decoration: InputDecoration(hintText: isEn ? "Paste image URL here" : "Dán link ảnh (URL) vào đây", border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(isEn ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (linkAnhController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _user?.updatePhotoURL(linkAnhController.text.trim());
                await _user?.reload();
                setState(() => _user = FirebaseAuth.instance.currentUser);
              }
            },
            child: Text(isEn ? "Update" : "Cập nhật"),
          ),
        ],
      ),
    );
  }

  void _doiMatKhau() async {
    if (_user == null || _user?.email == null) return;
    final isEn = context.read<CaiDatProvider>().isEnglish;

    if (_user?.providerData[0].providerId == 'google.com') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEn 
            ? "Google accounts do not need a password change here." 
            : "Tài khoản Google không cần đổi mật khẩu tại đây."))
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEn ? "Change Password" : "Đổi mật khẩu", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          isEn 
              ? "We will send a password reset link to:\n\n${_user!.email}\n\nDo you want to continue?"
              : "Chúng tôi sẽ gửi link tạo mật khẩu mới đến email:\n\n${_user!.email}\n\nBạn có muốn tiếp tục không?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text(isEn ? "Cancel" : "Hủy", style: const TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(dialogContext); 
              try {
                await _dichVuFirebase.quenMatKhau(_user!.email!);
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade700,
                    duration: const Duration(seconds: 5),
                    content: Text(
                      isEn 
                          ? "✔ Link sent! Please check your Email to change password and login again."
                          : "✔ Đã gửi link! Vui lòng check Email để đổi mật khẩu rồi đăng nhập lại.",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                );

                await _dichVuFirebase.dangXuat();
                if (!mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
                  (route) => false, 
                );

              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(isEn 
                        ? "Error: Cannot send email right now. Please try again later!" 
                        : "Lỗi: Không thể gửi email lúc này. Vui lòng thử lại sau!")
                  )
                );
              }
            },
            child: Text(isEn ? "Send Email" : "Gửi Email", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF0F4FF);
    final cardColor = isDark ? Colors.grey[850]! : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Text(
          isEn ? "Profile" : "Hồ sơ cá nhân", 
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: isDark ? Colors.blue.shade900 : Colors.blue.shade100,
                    backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                    child: _user?.photoURL == null ? Icon(Icons.person, size: 55, color: isDark ? Colors.white70 : Colors.blue) : null,
                  ),
                  GestureDetector(
                    onTap: _doiAnhDaiDien,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: bgColor, width: 3)),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: Text(isEn ? "Full Name" : "Họ và tên", style: TextStyle(fontSize: 12, color: subtitleColor)),
                    subtitle: Text(
                      _user?.displayName ?? (isEn ? "No name" : "Chưa có tên"), 
                      style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)
                    ),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _doiTenNguoiDung,
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.redAccent),
                    title: Text("Gmail", style: TextStyle(fontSize: 12, color: subtitleColor)),
                    subtitle: Text(
                      _user?.email ?? (isEn ? "No email" : "Chưa có email"), 
                      style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)
                    ),
                    trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey), 
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  ListTile(
                    leading: const Icon(Icons.cake, color: Colors.orange),
                    title: Text(isEn ? "Date of Birth" : "Ngày sinh", style: TextStyle(fontSize: 12, color: subtitleColor)),
                    subtitle: Text(
                      _ngaySinh == "Chưa cập nhật" ? (isEn ? "Not updated" : "Chưa cập nhật") : _ngaySinh, 
                      style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)
                    ),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _chonNgaySinh,
                  ),
                  Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[200]),

                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.green),
                    title: Text(isEn ? "Gender" : "Giới tính", style: TextStyle(fontSize: 12, color: subtitleColor)),
                    subtitle: Text(
                      _hienThiGioiTinh(_gioiTinh, isEn), 
                      style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)
                    ),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _chonGioiTinh,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle), 
                  child: const Icon(Icons.key, color: Colors.orange)
                ),
                title: Text(isEn ? "Change Password" : "Đổi mật khẩu", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: _doiMatKhau,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _dichVuFirebase.dangXuat();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const ManHinhDangNhap()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, size: 24),
                label: Text(isEn ? "Log Out" : "Đăng xuất", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.red.withValues(alpha: 0.2) : Colors.red.shade50,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16), 
                    side: BorderSide(color: isDark ? Colors.red.shade900 : Colors.red.shade200)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}