import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cong_viec.dart';
import '../services/ho_tro_sqlite.dart';

class QuanLyCongViecProvider with ChangeNotifier {
  final HoTroSQLite _dbHelper = HoTroSQLite();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ==========================================
  // KHAI BÁO BIẾN TRẠNG THÁI
  // ==========================================
  List<CongViec> _danhSachCongViec = [];
  bool _dangTaiDuLieu = false;
  
  String _danhMucDangLoc = 'All'; 

  // ==========================================
  // GETTERS (LẤY DỮ LIỆU RA GIAO DIỆN)
  // ==========================================
  List<CongViec> get danhSachCongViec => _danhSachCongViec;
  bool get dangTaiDuLieu => _dangTaiDuLieu;
  String get danhMucDangLoc => _danhMucDangLoc;
  String? get userId => _auth.currentUser?.uid;

  // 🔥 LỌC VÀ SẮP XẾP DANH SÁCH THEO ĐỘ QUAN TRỌNG
  List<CongViec> get danhSachHienThi {
    List<CongViec> ketQuaLoc;

    // 1. Lọc theo danh mục trước
    if (_danhMucDangLoc == 'All') {
      ketQuaLoc = List.from(_danhSachCongViec); 
    } else {
      ketQuaLoc = _danhSachCongViec.where((cv) => cv.danhMuc == _danhMucDangLoc).toList();
    }

    // 2. Sắp xếp danh sách đã lọc
    ketQuaLoc.sort((a, b) {
      // Ưu tiên 1: Đẩy việc đã hoàn thành (trạng thái = 1) xuống cuối cùng
      if (a.trangThai != b.trangThai) {
        return a.trangThai.compareTo(b.trangThai); 
      }

      // Ưu tiên 2: Tính điểm mức độ quan trọng
      int diemQuanTrong(String? mucDo) {
        if (mucDo == 'High') return 3;
        if (mucDo == 'Medium') return 2;
        if (mucDo == 'Low') return 1;
        return 0; // Mặc định
      }

      // So sánh điểm: Điểm cao (High) sẽ xếp lên trên
      return diemQuanTrong(b.mucDoUuTien).compareTo(diemQuanTrong(a.mucDoUuTien));
    });

    return ketQuaLoc;
  }

  // ==========================================
  // CÁC HÀM XỬ LÝ LOGIC
  // ==========================================
  
  void thayDoiBoLoc(String danhMucMoi) {
    if (_danhMucDangLoc != danhMucMoi) {
      _danhMucDangLoc = danhMucMoi;
      notifyListeners(); 
    }
  }

  // 1. TẢI DỮ LIỆU TỪ MÁY (OFFLINE - Khởi tạo)
  Future<void> taiDuLieuTuSQLite() async {
    if (userId == null) return;
    
    _danhSachCongViec = await _dbHelper.layDanhSach(userId!);
    notifyListeners();
  }

  // 2. ĐỒNG BỘ TỪ MÂY VỀ MÁY (ONLINE - Chạy ngầm)
  Future<void> dongBoTuFirebaseVeMay() async {
    if (userId == null) return;
    
    _dangTaiDuLieu = true;
    notifyListeners();

    try {
      var snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get();
      
      await _dbHelper.xoaTatCa(); 

      List<CongViec> danhSachMoi = [];

      for (var doc in snapshot.docs) {
        CongViec cv = CongViec.fromMap(doc.id, doc.data());
        cv.userId = userId; 
        await _dbHelper.themMoi(cv); 
        danhSachMoi.add(cv);
      }

      _danhSachCongViec = danhSachMoi;
    } catch (e) {
      debugPrint("Lỗi đồng bộ: $e");
    } finally {
      _dangTaiDuLieu = false;
      notifyListeners();
    }
  }

  // 3. THÊM MỚI (Cập nhật UI ngay lập tức)
  Future<void> themMoiCongViec(CongViec congViec) async {
    if (userId == null) return;

    congViec.userId = userId;
    var docRef = _firestore.collection('users').doc(userId).collection('tasks').doc();
    congViec.maCongViec = docRef.id; 

    _danhSachCongViec.insert(0, congViec); 
    notifyListeners();

    _dbHelper.themMoi(congViec); 
    try {
      await docRef.set(congViec.toMap()); 
    } catch(e) {
      debugPrint("Lỗi đẩy Firebase: $e");
    }
  }

  // 4. CẬP NHẬT CÔNG VIỆC
  Future<void> capNhatCongViec(CongViec congViec) async {
    if (userId == null || congViec.maCongViec == null) return;

    int index = _danhSachCongViec.indexWhere((item) => item.maCongViec == congViec.maCongViec);
    if (index != -1) {
      _danhSachCongViec[index] = congViec;
      notifyListeners(); 
    }

    _dbHelper.capNhat(congViec);
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(congViec.maCongViec)
          .update(congViec.toMap());
    } catch(e) {
      debugPrint("Lỗi cập nhật Firebase: $e");
    }
  }

  // 5. XÓA CÔNG VIỆC
  Future<void> xoaCongViec(String id) async {
    if (userId == null) return;

    _danhSachCongViec.removeWhere((item) => item.maCongViec == id);
    notifyListeners();

    _dbHelper.xoaBo(id);
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(id)
          .delete();
    } catch(e) {
      debugPrint("Lỗi xóa Firebase: $e");
    }
  }
}