import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cong_viec.dart';

class HoTroSQLite {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _khoiTaoDB();
    return _database!;
  }

  Future<Database> _khoiTaoDB() async {
    // Tìm đường dẫn lưu file database trên điện thoại
    String path = join(await getDatabasesPath(), 'quan_ly_cong_viec.db');
    return await openDatabase(
      path,
      version: 2, // 🔥 Nâng cấp version lên 2 vì chúng ta đổi cấu trúc bảng
      onCreate: _taoBang,
      onUpgrade: _nangCapBang,
    );
  }

  Future<void> _taoBang(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cong_viec(
        maCongViec TEXT PRIMARY KEY, -- Đổi thành TEXT để chứa ID Firebase
        tieuDe TEXT,
        noiDung TEXT,
        ngayThucHien TEXT,
        thoiGianNhacNho TEXT,
        trangThai INTEGER,
        userId TEXT,
        danhMuc TEXT,
        mucDoUuTien TEXT                  -- 🔥 THÊM CỘT NÀY: Phân biệt tài khoản
      )
    ''');
  }

  // Tự động dọn dẹp bảng cũ bị lỗi khi cập nhật code
  Future<void> _nangCapBang(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS cong_viec');
    await _taoBang(db, newVersion);
  }

  // 1. THÊM CÔNG VIỆC
  Future<int> themMoi(CongViec congViec) async {
    final db = await database;
    return await db.insert(
      'cong_viec', 
      congViec.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Ghi đè nếu bị trùng ID
    );
  }

  // 2. LẤY DANH SÁCH (CHỈ CỦA RIÊNG USER ĐÓ)
  Future<List<CongViec>> layDanhSach(String userId) async {
    final db = await database;
    
    // 🔥 Lệnh SQL: Quét bảng, lấy đúng những dòng có userId khớp với người đang đăng nhập
    final List<Map<String, dynamic>> maps = await db.query(
      'cong_viec',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      // Ép kiểu ID sang chuỗi để Model không bị lỗi
      return CongViec.fromMap(maps[i]['maCongViec'].toString(), maps[i]);
    });
  }

  // 3. SỬA CÔNG VIỆC
  Future<int> capNhat(CongViec congViec) async {
    final db = await database;
    return await db.update(
      'cong_viec',
      congViec.toMap(),
      where: 'maCongViec = ?', // Tìm đúng ID công việc dạng chữ để sửa
      whereArgs: [congViec.maCongViec],
    );
  }

  // 4. XÓA CÔNG VIỆC
  Future<int> xoaBo(String id) async { // Đổi tham số thành String
    final db = await database;
    return await db.delete(
      'cong_viec',
      where: 'maCongViec = ?',
      whereArgs: [id],
    );
  }
  
  // 5. LÀM SẠCH KHI ĐĂNG XUẤT (Tùy chọn thêm cho an toàn)
  Future<void> xoaTatCa() async {
    final db = await database;
    await db.delete('cong_viec');
  }
}