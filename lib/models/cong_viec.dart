class CongViec {
  String? maCongViec;   // ID dạng chuỗi (String) của Firebase
  String tieuDe;
  String noiDung;
  String ngayThucHien;
  String? thoiGianNhacNho;
  int trangThai;
  String? userId;       // "Thẻ chủ quyền" phân biệt người dùng
  
  // 🔥 THÊM 2 TRƯỜNG MỚI NÀY
  String? danhMuc;
  String? mucDoUuTien;

  CongViec({
    this.maCongViec,
    required this.tieuDe,
    required this.noiDung,
    required this.ngayThucHien,
    this.thoiGianNhacNho,
    this.trangThai = 0,
    this.userId,
    this.danhMuc,       // 🔥 THÊM VÀO ĐÂY
    this.mucDoUuTien,   // 🔥 THÊM VÀO ĐÂY
  });

  // Chuyển từ Map (của Firebase hoặc SQLite) sang Object
  factory CongViec.fromMap(String id, Map<String, dynamic> map) {
    return CongViec(
      maCongViec: id, 
      tieuDe: map['tieuDe'] ?? '',
      noiDung: map['noiDung'] ?? '',
      ngayThucHien: map['ngayThucHien'] ?? '',
      thoiGianNhacNho: map['thoiGianNhacNho'],
      trangThai: map['trangThai'] ?? 0,
      userId: map['userId'],
      danhMuc: map['danhMuc'],           // 🔥 ĐỌC TỪ MAP
      mucDoUuTien: map['mucDoUuTien'],   // 🔥 ĐỌC TỪ MAP
    );
  }

  // Chuyển từ Object sang Map để lưu vào máy (SQLite) và mây (Firebase)
  Map<String, dynamic> toMap() {
    return {
      'maCongViec': maCongViec, 
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'ngayThucHien': ngayThucHien,
      'thoiGianNhacNho': thoiGianNhacNho,
      'trangThai': trangThai,
      'userId': userId,
      'danhMuc': danhMuc,           // 🔥 GHI VÀO MAP
      'mucDoUuTien': mucDoUuTien,   // 🔥 GHI VÀO MAP
    };
  }
}