import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Thư viện database
import 'package:intl/intl.dart'; // Để định dạng ngày tháng

import '../../services/dich_vu_firebase.dart';
import '../auth/man_hinh_dang_nhap.dart';

class ManHinhHoSo extends StatefulWidget {
  const ManHinhHoSo({Key? key}) : super(key: key);

  @override
  State<ManHinhHoSo> createState() => _ManHinhHoSoState();
}

class _ManHinhHoSoState extends State<ManHinhHoSo> {
  User? _user;
  final DichVuFirebase _dichVuFirebase = DichVuFirebase();

  // Các biến để lưu thông tin mở rộng từ Database
  String _ngaySinh = "Chưa cập nhật";
  String _gioiTinh = "Chưa cập nhật";

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _taiThongTinTuFirestore(); // Tải ngày sinh và giới tính khi mở trang
  }

  // 1. HÀM TẢI THÔNG TIN TỪ FIRESTORE
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

  // 2. HÀM CẬP NHẬT LÊN FIRESTORE
  Future<void> _capNhatFirestore(String truong, String giaTri) async {
    if (_user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        truong: giaTri
      }, SetOptions(merge: true)); // merge: true để không làm mất dữ liệu cũ
      _taiThongTinTuFirestore(); // Tải lại để UI hiển thị ngay
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi lưu dữ liệu: $e")));
    }
  }

  // 3. ĐỔI TÊN
  void _doiTenNguoiDung() {
    TextEditingController tenController = TextEditingController(text: _user?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đổi tên hiển thị", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: tenController,
          decoration: const InputDecoration(hintText: "Nhập tên mới", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (tenController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _user?.updateDisplayName(tenController.text.trim());
                await _user?.reload();
                setState(() => _user = FirebaseAuth.instance.currentUser);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật tên!")));
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // 4. CHỌN NGÀY SINH (Dùng bộ lịch của Flutter)
  Future<void> _chonNgaySinh() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000), 
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: "CHỌN NGÀY SINH",
    );
    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      await _capNhatFirestore('ngaySinh', formattedDate);
    }
  }

  // 5. CHỌN GIỚI TÍNH
  void _chonGioiTinh() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn giới tính", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text("Nam"), leading: const Icon(Icons.male, color: Colors.blue), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Nam'); }),
            ListTile(title: const Text("Nữ"), leading: const Icon(Icons.female, color: Colors.pink), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Nữ'); }),
            ListTile(title: const Text("Khác"), leading: const Icon(Icons.transgender, color: Colors.purple), onTap: () { Navigator.pop(context); _capNhatFirestore('gioiTinh', 'Khác'); }),
          ],
        ),
      ),
    );
  }

  // 6. ĐỔI ẢNH ĐẠI DIỆN BẰNG LINK
  void _doiAnhDaiDien() {
    TextEditingController linkAnhController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cập nhật ảnh đại diện", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: linkAnhController,
          decoration: const InputDecoration(hintText: "Dán link ảnh (URL) vào đây", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (linkAnhController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await _user?.updatePhotoURL(linkAnhController.text.trim());
                await _user?.reload();
                setState(() => _user = FirebaseAuth.instance.currentUser);
              }
            },
            child: const Text("Cập nhật"),
          ),
        ],
      ),
    );
  }

  // 7. ĐỔI MẬT KHẨU
  void _doiMatKhau() {
    if (_user?.providerData[0].providerId == 'google.com') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tài khoản Google không thể đổi mật khẩu tại đây.")));
      return;
    }
    TextEditingController matKhauController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: matKhauController,
          obscureText: true, 
          decoration: const InputDecoration(hintText: "Nhập mật khẩu mới (min 6 ký tự)", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              if (matKhauController.text.length >= 6) {
                Navigator.pop(context);
                try {
                  await _user?.updatePassword(matKhauController.text);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đổi mật khẩu thành công!")));
                } catch (e) {
                  if (e.toString().contains('requires-recent-login')) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng đăng xuất và đăng nhập lại để thực hiện.")));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                }
              }
            },
            child: const Text("Lưu", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF0F4FF);
    const cardColor = Colors.white;
    const textColor = Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: textColor), onPressed: () => Navigator.pop(context)),
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── AVATAR TRÊN CÙNG ──
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
                    child: _user?.photoURL == null ? const Icon(Icons.person, size: 55, color: Colors.blue) : null,
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

            // ── THÔNG TIN CHI TIẾT ──
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: Column(
                children: [
                  // Tên
                  ListTile(
                    leading: const Icon(Icons.badge, color: Colors.blue),
                    title: const Text("Họ và tên", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_user?.displayName ?? "Duy", style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _doiTenNguoiDung,
                  ),
                  const Divider(height: 1),

                  // Gmail
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.redAccent),
                    title: const Text("Gmail", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_user?.email ?? "Chưa có email", style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey), // Có ổ khóa ý chỉ không sửa được
                  ),
                  const Divider(height: 1),

                  // Ngày sinh
                  ListTile(
                    leading: const Icon(Icons.cake, color: Colors.orange),
                    title: const Text("Ngày sinh", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_ngaySinh, style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _chonNgaySinh,
                  ),
                  const Divider(height: 1),

                  // Giới tính
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.green),
                    title: const Text("Giới tính", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    subtitle: Text(_gioiTinh, style: const TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onTap: _chonGioiTinh,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── BẢO MẬT & TÀI KHOẢN ──
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
              ),
              child: ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.key, color: Colors.orange)),
                title: const Text("Đổi mật khẩu", style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: _doiMatKhau,
              ),
            ),

            const SizedBox(height: 30),

            // ── NÚT ĐĂNG XUẤT ──
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
                label: const Text("Đăng xuất", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.red.shade200)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}