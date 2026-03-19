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
    String path = join(await getDatabasesPath(), 'quan_ly_cong_viec.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _taoBang,
      onUpgrade: _nangCapBang,
    );
  }

  Future<void> _taoBang(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cong_viec(
        maCongViec TEXT PRIMARY KEY,
        tieuDe TEXT,
        noiDung TEXT,
        ngayThucHien TEXT,
        thoiGianNhacNho TEXT,
        trangThai INTEGER,
        userId TEXT,
        danhMuc TEXT,
        mucDoUuTien TEXT
      )
    ''');
  }

  Future<void> _nangCapBang(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS cong_viec');
    await _taoBang(db, newVersion);
  }

  Future<int> themMoi(CongViec congViec) async {
    final db = await database;
    return await db.insert(
      'cong_viec', 
      congViec.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CongViec>> layDanhSach(String userId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'cong_viec',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return List.generate(maps.length, (i) {
      return CongViec.fromMap(maps[i]['maCongViec'].toString(), maps[i]);
    });
  }

  Future<int> capNhat(CongViec congViec) async {
    final db = await database;
    return await db.update(
      'cong_viec',
      congViec.toMap(),
      where: 'maCongViec = ?',
      whereArgs: [congViec.maCongViec],
    );
  }

  Future<int> xoaBo(String id) async {
    final db = await database;
    return await db.delete(
      'cong_viec',
      where: 'maCongViec = ?',
      whereArgs: [id],
    );
  }
  
  Future<void> xoaTatCa() async {
    final db = await database;
    await db.delete('cong_viec');
  }
}