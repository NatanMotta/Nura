import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> init() async {
    // Richiesta permessi su iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Registra il token
      await _registerDeviceToken();

      // Gestione notifiche in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // Puoi usare un plugin come flutter_local_notifications per mostrare una UI
        // o aggiornare lo stato di Riverpod per accendere un "pallino rosso".
        print('Notifica ricevuta in Foreground: ${message.notification?.title}');
      });

      // Gestione click notifica da background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // Gestione refresh del token
      _fcm.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
    } catch (e) {
      print('Errore durante il fetch dell FCM token: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final platform = Platform.isIOS ? 'ios' : Platform.isAndroid ? 'android' : 'web';

    try {
      await _supabase.from('user_devices').upsert({
        'profile_id': user.id,
        'fcm_token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'profile_id, fcm_token');
      print('Dispositivo registrato con successo.');
    } catch (e) {
      print('Errore durante il salvataggio del token su Supabase: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    // Esempio: reindirizza l'utente a una schermata specifica 
    // basata su message.data['type']
    print('L utente ha cliccato sulla notifica: ${message.data}');
  }
}
