import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform; 
import 'dart:async';
import 'package:flutter/foundation.dart'; // 🔥 IMPORT THƯ VIỆN ĐỂ NHẬN DIỆN WEB

class DichVuThongBao {
  static final DichVuThongBao _instance = DichVuThongBao._internal();
  factory DichVuThongBao() => _instance;
  DichVuThongBao._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static final StreamController<String?> streamNhanPayload = StreamController<String?>.broadcast();

  static String? veChoXuLy;

  Future<void> khoiTao() async {
    // 🔥 CHỐN CRASH TRÊN WEB: Nếu chạy trên trình duyệt thì bỏ qua toàn bộ hàm này
    if (kIsWeb) {
      debugPrint("Đang chạy trên Web -> Bỏ qua khởi tạo Local Notifications.");
      return; 
    }

    tz.initializeTimeZones(); 
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    final NotificationAppLaunchDetails? notificationAppLaunchDetails = 
        await _notificationsPlugin.getNotificationAppLaunchDetails();
        
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      veChoXuLy = notificationAppLaunchDetails?.notificationResponse?.payload;
    }

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          streamNhanPayload.add(response.payload); 
        }
      },
    );

    // 🔥 Sửa lỗi gọi Platform trên Web (Dù đã chặn ở trên, nhưng viết thế này sẽ an toàn tuyệt đối)
    if (!kIsWeb && Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> hienThongBaoNgay({required String title, required String body}) async {
    if (kIsWeb) return; // 🔥 Không chạy trên Web

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kenh_test_nhanh', 
      'Thông báo kiểm tra',
      channelDescription: 'Kênh dùng để kiểm tra loa và quyền thông báo',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true, 
      playSound: true,       
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    
    await _notificationsPlugin.show(
      id: 8888, 
      title: title, 
      body: body, 
      notificationDetails: platformDetails
    );
  }
  
  Future<void> henGioThongBao({required int id, required String title, required String body, required DateTime thoiGian, String? payload}) async {
    if (kIsWeb) return; // 🔥 Không chạy trên Web

    if (thoiGian.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id: id, 
      title: title, 
      body: body,
      scheduledDate: tz.TZDateTime.from(thoiGian, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'kenh_nhac_nho_cv', 
          'Nhắc nhở công việc', 
          channelDescription: 'Kênh báo chuông khi công việc đến hạn',
          importance: Importance.max, 
          priority: Priority.high, 
          icon: '@mipmap/ic_launcher',
          enableVibration: true, 
          playSound: true,       
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, 
      payload: payload,
    );
  }

  Future<void> huyThongBao(int id) async {
    if (kIsWeb) return; // 🔥 Không chạy trên Web
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> huyTatCaThongBao() async {
    if (kIsWeb) return; // 🔥 Không chạy trên Web
    await _notificationsPlugin.cancelAll();
  }
}