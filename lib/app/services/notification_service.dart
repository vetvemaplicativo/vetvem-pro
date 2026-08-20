import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../modules/home/home_controller.dart';

class NotificationService {
  static final _fln = FlutterLocalNotificationsPlugin();
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static StreamSubscription? _sub;

  // Deep-link: id do agendamento a abrir assim que o HomeController existir
  // (cobre o caso do push chegar com o app ainda fechado/inicializando).
  static String? pendingAppointmentId;

  static const _channel = AndroidNotificationChannel(
    'vetvem_pro_channel_v2',
    'VetVem Pro',
    description: 'Notificações do VetVem Pro',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> init() async {
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      ),
      // Toque na notificação local (app em foreground)
      onDidReceiveNotificationResponse: (resp) {
        final id = resp.payload;
        if (id != null && id.isNotEmpty) openAppointment(id);
      },
    );

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveToken();
    FirebaseMessaging.instance.onTokenRefresh.listen(_updateToken);
    // Em foreground quem exibe é o listener do Firestore (abaixo);
    // o push FCM (function sendPush) cobre background/app fechado.
    _listenFirestoreNotifications();

    // Deep-link: toque no push com o app em background ou fechado.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
  }

  static void _handleMessage(RemoteMessage message) {
    final id = message.data['appointmentId'];
    if (id is String && id.isNotEmpty) openAppointment(id);
  }

  // Abre direto a tela do agendamento. Se o HomeController ainda não
  // existir (app recém-aberto pelo push), guarda o id pra consumir depois.
  static void openAppointment(String id) {
    if (!Get.isRegistered<HomeController>()) {
      pendingAppointmentId = id;
      return;
    }
    Get.find<HomeController>().openAppointmentDetail(id);
  }

  static Future<void> _saveToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  static Future<void> _updateToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({'fcmToken': token});
  }

  static void _listenFirestoreNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _sub?.cancel();
    _sub = _firestore
        .collection('notifications')
        .doc(uid)
        .collection('pending')
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final d = change.doc.data() ?? {};
          // pushed=true: o push FCM já exibiu esta notificação (app fechado).
          // Freshness: fallback para docs antigos sem push (ex.: sem token).
          final ts = d['createdAt'];
          final created = ts is Timestamp ? ts.toDate() : null;
          final fresh = created == null ||
              DateTime.now().difference(created).inMinutes < 3;
          // Só exibe com o app em primeiro plano — em background/fechado o
          // push FCM já aparece na bandeja (evita duplicata na bandeja).
          final foreground = WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed;
          if (foreground && d['pushed'] != true && fresh) {
            _show(
              title: d['title'] as String? ?? 'VetVem Pro',
              body: d['body'] as String? ?? '',
              payload: d['appointmentId'] as String?,
            );
          }
          change.doc.reference.update({'read': true});
        }
      }
    });
  }

  static Future<void> _show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          color: const Color(0xFF1A73E8),
          icon: '@mipmap/launcher_icon',
          playSound: true,
          enableVibration: true,
          ticker: title,
          visibility: NotificationVisibility.public,
        ),
      ),
      payload: payload,
    );
  }

  static Future<void> sendTo({
    required String toUid,
    required String title,
    required String body,
    String? tipo,
    String? appointmentId,
  }) async {
    await _firestore
        .collection('notifications')
        .doc(toUid)
        .collection('pending')
        .add({
      'title': title,
      'body': body,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (tipo != null) 'tipo': tipo,
      if (appointmentId != null) 'appointmentId': appointmentId,
    });
  }

  static void dispose() {
    _sub?.cancel();
  }
}
