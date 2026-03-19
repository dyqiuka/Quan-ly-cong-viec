import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; 

import '../../models/cong_viec.dart';
import '../../providers/cai_dat_provider.dart';

class ItemCongViecWidget extends StatelessWidget {
  final CongViec congViec;
  final VoidCallback onChon;
  final Function(bool?) onDoiTrangThai;
  final int index; 

  const ItemCongViecWidget({
    super.key, 
    required this.congViec,
    required this.onChon,
    required this.onDoiTrangThai,
    this.index = 0, 
  });

  Color _layMauUuTien(String? mucDo) {
    if (mucDo == 'Cao' || mucDo == 'High') return Colors.red;
    if (mucDo == 'Trung Bình' || mucDo == 'Medium') return Colors.orange;
    if (mucDo == 'Thấp' || mucDo == 'Low') return Colors.green;
    return Colors.blue;
  }

  String _dichDanhMuc(String? cat, bool isEn) {
    if (cat == null) return isEn ? 'Work' : 'Công việc';
    if (!isEn) return cat;
    switch (cat) {
      case "Học tập": return "Study";
      case "Công việc": return "Work";
      case "Cá nhân": return "Personal";
      case "Sức khỏe": return "Health";
      case "Khác": return "Other";
      default: return cat;
    }
  }

  String _dichUuTien(String? pri, bool isEn) {
    if (pri == null) return '';
    if (!isEn) return pri;
    switch (pri) {
      case "Thấp": return "Low";
      case "Trung Bình": return "Medium";
      case "Cao": return "High";
      default: return pri;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<CaiDatProvider>().isEnglish;
    final isDark = context.watch<CaiDatProvider>().isDarkMode;

    bool daHoanThanh = congViec.trangThai == 1;
    Color mauUuTien = _layMauUuTien(congViec.mucDoUuTien);

    final cardColor = isDark 
        ? (daHoanThanh ? const Color(0xFF121212) : const Color(0xFF1E1E1E)) 
        : (daHoanThanh ? Colors.grey.shade100 : Colors.white);
        
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    Widget theCongViec = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: daHoanThanh ? 0 : (isDark ? 0 : 2), 
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: daHoanThanh ? borderColor : (isDark ? Colors.grey.shade800 : Colors.transparent)
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: daHoanThanh ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400) : mauUuTien,
              width: 6,
            ),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          
          leading: Transform.scale(
            scale: 1.1, 
            child: Checkbox(
              value: daHoanThanh,
              activeColor: Colors.green,
              checkColor: isDark ? Colors.black : Colors.white, 
              side: BorderSide(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, width: 2), 
              shape: const CircleBorder(),
              onChanged: onDoiTrangThai,
            ),
          ),
          
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10, 
                runSpacing: 6, 
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Hero(
                    tag: 'danh_muc_${congViec.maCongViec}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                        decoration: BoxDecoration(
                          color: daHoanThanh 
                              ? (isDark ? Colors.grey.shade900 : Colors.grey.shade200) 
                              : (isDark ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.blue.shade50),
                          borderRadius: BorderRadius.circular(6)
                        ),
                        child: Text(
                          _dichDanhMuc(congViec.danhMuc, isEn), 
                          style: TextStyle(
                            fontSize: 13, 
                            color: daHoanThanh ? (isDark ? Colors.grey.shade600 : Colors.grey) : (isDark ? Colors.blue.shade200 : Colors.blue.shade700),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  if (!daHoanThanh && congViec.mucDoUuTien != null)
                    Hero(
                      tag: 'uu_tien_${congViec.maCongViec}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            Icon(Icons.flag_rounded, size: 16, color: mauUuTien), 
                            const SizedBox(width: 4),
                            Text(
                              _dichUuTien(congViec.mucDoUuTien, isEn), 
                              style: TextStyle(fontSize: 13, color: mauUuTien, fontWeight: FontWeight.bold), 
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 10), 
              
              Hero(
                tag: 'tieu_de_${congViec.maCongViec}', 
                child: Material(
                  type: MaterialType.transparency,
                  child: Text(
                    congViec.tieuDe,
                    style: TextStyle(
                      fontSize: 19, 
                      fontWeight: FontWeight.bold,
                      decoration: daHoanThanh ? TextDecoration.lineThrough : null,
                      color: daHoanThanh ? (isDark ? Colors.grey.shade600 : Colors.grey) : textColor, 
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 12.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (congViec.thoiGianNhacNho != null && congViec.thoiGianNhacNho!.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.notifications_active_outlined, size: 18, color: daHoanThanh ? (isDark ? Colors.grey.shade700 : Colors.grey) : (isDark ? Colors.amber.shade400 : Colors.amber.shade700)), 
                      const SizedBox(width: 8),
                      Expanded(
                        child: Hero(
                          tag: 'nhac_nho_text_${congViec.maCongViec}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              congViec.thoiGianNhacNho!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: daHoanThanh ? (isDark ? Colors.grey.shade700 : Colors.grey) : (isDark ? Colors.amber.shade400 : Colors.amber.shade700), fontSize: 15), 
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), 
                ],
                Row(
                  children: [
                    Icon(Icons.timer_off_outlined, size: 18, color: daHoanThanh ? (isDark ? Colors.grey.shade700 : Colors.grey) : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey)), 
                    const SizedBox(width: 8),
                    Expanded(
                      child: Hero(
                        tag: 'thoi_han_text_${congViec.maCongViec}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Text(
                            congViec.ngayThucHien,
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(color: daHoanThanh ? (isDark ? Colors.grey.shade700 : Colors.grey) : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey), fontSize: 15), 
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          onTap: onChon,
        ),
      ),
    );

    return AnimationConfiguration.staggeredList(
      position: index, 
      duration: const Duration(milliseconds: 500), 
      child: SlideAnimation(
        verticalOffset: 100.0, 
        child: FadeInAnimation( 
          child: theCongViec,
        ),
      ),
    );
  }
}