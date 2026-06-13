import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Bir sohbet push'unun veri yükünden yola çıkarak mesajı "iletildi" yapar.
/// Hem ön plan hem arka plan işleyicisinden çağrılır; böylece "iletildi"
/// göstergesi, alıcı sohbeti açmadan da (mesaj cihaza ulaşır ulaşmaz) görünür.
Future<void> _markDeliveredFromData(Map<String, dynamic> data) async {
  if (data['type'] != 'chat') return;
  final chatId = data['chatId'] as String?;
  final messageId = data['messageId'] as String?;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (chatId == null || messageId == null || uid == null) return;
  try {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deliveredTo': FieldValue.arrayUnion([uid]),
    });
  } catch (e) {
    debugPrint('markDelivered (push) hata: $e');
  }
}

/// Arka planda/terminated durumda gelen FCM mesajları için en üst seviye
/// işleyici. `notification` payload'unu sistem tepsisi otomatik gösterir; biz
/// yalnızca mesajı "iletildi" olarak işaretliyoruz.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ayrı bir izolatta çalışır; Firebase'i burada bir kez başlatmamız gerekir.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await _markDeliveredFromData(message.data);
}

/// Push (uzaktan) bildirimleri yöneten servis: izin ister, FCM token'ını
/// kullanıcı dökümanına yazar ve uygulama ön plandayken gelen mesajları yerel
/// bildirim olarak gösterir.
///
/// Bildirimin kendisi sunucuda (Cloud Functions) üretilir: yeni sohbet mesajı
/// ve bölge fethi olduğunda ilgili kullanıcıların token'larına gönderilir.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final _local = FlutterLocalNotificationsPlugin();
  bool _inited = false;
  String? _uid;

  /// Yeni mesaj/fetih bildirimleri için Android kanalı (yüksek önem → açılır).
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'treadom_messages',
    'Mesajlar ve bildirimler',
    description: 'Yeni mesaj ve bölge fethi bildirimleri',
    importance: Importance.high,
  );

  /// İzin + yerel bildirim altyapısını ve ön plan dinleyicisini bir kez kurar.
  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    final androidImpl = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_channel);
    // Android 13+ çalışma zamanı bildirim izni.
    await androidImpl?.requestNotificationsPermission();

    await FirebaseMessaging.instance.requestPermission();
    // iOS'ta ön planda da sistem banner'ı gösterilsin.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Uygulama ön plandayken sistem 'notification' payload'unu göstermez;
    // kendimiz yerel bildirim olarak gösteriyoruz.
    FirebaseMessaging.onMessage.listen(_showForeground);
  }

  /// Oturum açan kullanıcıya bağlanır: izin/altyapıyı kurar ve token'ı yazar.
  /// Token yenilenince de günceller.
  Future<void> registerForUser(String uid) async {
    _uid = uid;
    try {
      await init();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(uid, token);
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        final u = _uid;
        if (u != null) _saveToken(u, t);
      });
    } catch (e) {
      debugPrint('PushService.registerForUser hata: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  void _showForeground(RemoteMessage message) {
    // Mesaj ön planda geldi → cihaza ulaştı, "iletildi" yap.
    _markDeliveredFromData(message.data);
    final n = message.notification;
    final title = n?.title ?? message.data['title'] as String?;
    final body = n?.body ?? message.data['body'] as String?;
    if (title == null && body == null) return;
    _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
