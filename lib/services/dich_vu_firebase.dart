import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DichVuFirebase {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '630042812801-u1j11ee0anoh2hbfjmm2k5a5rak84ba2.apps.googleusercontent.com',
  );

  Future<User?> dangNhapEmailMatKhau(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception("Lỗi đăng nhập: ${e.toString()}");
    }
  }

  Future<User?> dangKyEmailMatKhau(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) {
      throw Exception("Lỗi đăng ký: ${e.toString()}");
    }
  }

  Future<User?> dangNhapGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; 

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

  Future<void> quenMatKhau(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception("Không thể gửi email: ${e.toString()}");
    }
  }

  Future<void> dangXuat() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> themCongViecCloud(Map<String, dynamic> data) async {
    if (currentUserId != null) {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .add(data);
    } else {
      throw Exception("Bạn chưa đăng nhập nên không thể lưu dữ liệu!");
    }
  }

  Stream<QuerySnapshot> layDanhSachCongViecCloud() {
    if (currentUserId != null) {
      return _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tasks')
          .orderBy('ngayTao', descending: true)
          .snapshots();
    } else {
      throw Exception("Vui lòng đăng nhập để xem công việc!");
    }
  }

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