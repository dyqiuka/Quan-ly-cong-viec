import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // THÊM IMPORT NÀY

class DichVuFirebase {
  // ── KHỞI TẠO CÁC DỊCH VỤ FIREBASE ──
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Khởi tạo Database
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '630042812801-u1j11ee0anoh2hbfjmm2k5a5rak84ba2.apps.googleusercontent.com',
  );


  // ==========================================================
  // PHẦN 1: XÁC THỰC TÀI KHOẢN (AUTHENTICATION)
  // ==========================================================

  // 1. Đăng nhập bằng Email & Mật khẩu
  Future<User?> dangNhapEmailMatKhau(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception("Lỗi đăng nhập: ${e.toString()}");
    }
  }

  // 2. Đăng ký tài khoản mới
  Future<User?> dangKyEmailMatKhau(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception("Lỗi đăng ký: ${e.toString()}");
    }
  }

  // 3. Đăng nhập bằng Google
  Future<User?> dangNhapGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Người dùng hủy đăng nhập

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      throw Exception("Lỗi đăng nhập Google: ${e.toString()}");
    }
  }

  // 4. Quên mật khẩu (Gửi email khôi phục)
  Future<void> quenMatKhau(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Không thể gửi email: ${e.toString()}");
    }
  }

  // 5. Đăng xuất
  Future<void> dangXuat() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }


  // ==========================================================
  // PHẦN 2: QUẢN LÝ DỮ LIỆU CÔNG VIỆC (CLOUD FIRESTORE)
  // ==========================================================

  // Hàm tiện ích: Lấy ID của người dùng đang đăng nhập
  String? get currentUserId => _auth.currentUser?.uid;

  // 6. THÊM công việc mới lên Firebase
  Future<void> themCongViecCloud(Map<String, dynamic> data) async {
    if (currentUserId != null) {
      // Lưu theo cấu trúc: users -> [ID Người dùng] -> tasks -> [Tự sinh ID công việc]
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .add(data);
    } else {
      throw Exception("Bạn chưa đăng nhập nên không thể lưu dữ liệu!");
    }
  }

  // 7. LẤY danh sách công việc (Dạng Stream để tự động cập nhật UI)
  Stream<QuerySnapshot> layDanhSachCongViecCloud() {
    if (currentUserId != null) {
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .orderBy('ngayTao', descending: true) // Ưu tiên việc mới tạo lên đầu
          .snapshots();
    } else {
      throw Exception("Vui lòng đăng nhập để xem công việc!");
    }
  }

  // 8. SỬA công việc (Cập nhật tiêu đề, nội dung, đổi trạng thái done...)
  Future<void> capNhatCongViecCloud(String taskId, Map<String, dynamic> data) async {
    if (currentUserId != null) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(taskId)
          .update(data);
    }
  }

  // 9. XÓA công việc
  Future<void> xoaCongViecCloud(String taskId) async {
    if (currentUserId != null) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    }
  }
  
}