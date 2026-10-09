import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../routes/app_routes.dart';
import 'api_service.dart';
import 'storage_service.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Must initialize Firebase before using any Firebase services in background
  await Firebase.initializeApp();
  
  if (message.notification != null) {
    // Show local notification for background messages
    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await localNotifications.initialize(
      settings: const InitializationSettings(android: initSettings),
    );
    
    await localNotifications.show(
      id: message.hashCode,
      title: message.notification!.title,
      body: message.notification!.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

class NotificationService extends GetxService {
  late final FirebaseMessaging _firebaseMessaging;
  bool _isFirebaseInitialized = false;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = Get.find<ApiService>();
  final StorageService _storageService = Get.find<StorageService>();

  Future<NotificationService> init(bool isFirebaseInitialized) async {
    _isFirebaseInitialized = isFirebaseInitialized || Firebase.apps.isNotEmpty;
    
    // Initialize local notifications
    try {
      await _initLocalNotifications();
    } catch (e) {
      print('Error initializing local notifications: $e');
    }

    if (!_isFirebaseInitialized && Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
        _isFirebaseInitialized = true;
      } catch (fe) {
        print('Firebase init attempt: $fe');
      }
    }

    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // 2. Register background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
        _showLocalNotification(message);
      });

      // 4. Handle when app is in background and user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });

      // 5. Handle when app is terminated and user taps notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationClick(initialMessage);
      }

      // 6. Request permission after UI is ready (2 second delay so user sees app first)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          await _requestPermission();
          // 7. Manage Token only after permission is granted
          _manageFCMToken();
        } catch (e) {
          print('Error requesting notification permission: $e');
        }
      });
    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
    }

    return this;
  }

  Future<void> _requestPermission() async {
    // Android 13+ (API 33+): use permission_handler for runtime notification permission
    if (Platform.isAndroid) {
      try {
        final status = await Permission.notification.status;
        print('Current notification permission status: $status');
        
        if (status.isDenied || status.isRestricted) {
          print('Requesting notification permission via permission_handler...');
          final result = await Permission.notification.request();
          print('Notification permission result: $result');
        } else if (status.isPermanentlyDenied) {
          print('Notification permission permanently denied. Opening app settings...');
          await openAppSettings();
        } else {
          print('Notification permission already granted: $status');
        }
      } catch (e) {
        print('Error requesting Android notification permission: $e');
      }
    }

    if (!_isFirebaseInitialized) {
      print('Firebase not initialized. Skipping Firebase Messaging permission request.');
      return;
    }

    try {
      // Firebase permission request (required for iOS, also needed for Android token)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      print('Firebase messaging permission: ${settings.authorizationStatus}');

      // iOS foreground notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      print('Error requesting Firebase messaging permission: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNotificationClickData(data);
          } catch (e) {
            print("Error parsing payload: $e");
          }
        }
      },
    );

    // Create Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    String title = message.notification?.title ?? message.data['title'] ?? 'New Notification 🚀';
    String body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? 'You have a new update.';

    try {
      print('Attempting to show local notification: title=$title, body=$body');
      await _localNotificationsPlugin.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          )
        ),
        payload: jsonEncode(message.data),
      );
      print('Local notification displayed successfully.');
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    _handleNotificationClickData(message.data);
  }

  void _handleNotificationClickData(Map<String, dynamic> data) {
    // Navigate to notifications screen
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> _manageFCMToken() async {
    if (!_isFirebaseInitialized) {
      print("Firebase not initialized, skipping token management.");
      return;
    }
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        _saveTokenToBackend(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToBackend(newToken);
      });
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      final vId = await _storageService.getVendorId();
      String platform = GetPlatform.isAndroid ? 'android' : 'ios';

      // 1. Sync token to Firestore document so Firebase Cloud Functions triggers push notifications
      if (vId != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(vId.toString()).set({
            'fcmTokens': {
              '${platform}Token': token,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            'vendor_id': vId.toString(),
            'role': 'vendor',
          }, SetOptions(merge: true));
          print("FCM Token synced to Firestore users/$vId successfully.");
        } catch (fe) {
          print("Firestore FCM token sync warning: $fe");
        }
      }

      // 2. Save token to HTTP API Backend
      // Note: ApiService interceptor auto-injects Authorization header from StorageService
      final uName = await _storageService.getUserName();

      final Map<String, dynamic> postData = {
        'fcm_token': token,
        'device_type': platform,
      };
      if (vId != null) postData['vendor_id'] = vId;
      if (uName != null) postData['username'] = uName;

      final response = await _apiService.dio.post(
        '/vendor/save-fcm-token',
        data: postData,
      );

      if (response.data['status'] == true) {
        print("FCM Token saved to Backend API successfully.");
      }
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  void refreshFCMToken() {
    if (_isFirebaseInitialized) {
      _manageFCMToken();
    }
  }

  /// Returns the current FCM token without saving it to backend.
  /// Used during login to include the token atomically in the login request.
  Future<String?> getFCMToken() async {
    if (!_isFirebaseInitialized) return null;
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('getFCMToken error: $e');
      return null;
    }
  }
}
