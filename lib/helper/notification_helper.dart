import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart' as fgt;
import 'package:stackfood_multivendor_restaurant/features/advertisement/controllers/advertisement_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/chat/controllers/chat_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/dashboard/screens/dashboard_screen.dart';
import 'package:stackfood_multivendor_restaurant/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/chat/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor_restaurant/features/dashboard/widgets/new_request_dialog_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/custom_print_helper.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/helper/user_type.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:stackfood_multivendor_restaurant/main.dart';
import 'package:stackfood_multivendor_restaurant/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NotificationHelper {
  static Future<void> initialize(
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) async {
    debugPrint('Initializing NotificationHelper...');

    if (GetPlatform.isAndroid) {
      // Create main notification channel
      const fln.AndroidNotificationChannel channel =
          fln.AndroidNotificationChannel(
        'stackfood', // id
        'StackFood Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: fln.Importance.high,
        enableVibration: true,
        playSound: true,
      );

      // Create OTP notification channel
      const fln.AndroidNotificationChannel otpChannel =
          fln.AndroidNotificationChannel(
        'otp_channel',
        'OTP Notifications',
        description: 'This channel is used for OTP verification codes.',
        importance: fln.Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Create test notification channel
      const fln.AndroidNotificationChannel testChannel =
          fln.AndroidNotificationChannel(
        'test_only_channel',
        'Test Notifications',
        description: 'This channel is only for test notifications',
        importance: fln.Importance.max,
        enableVibration: true,
        enableLights: true,
        playSound: true,
      );

      // Get the Android plugin implementation
      final fln.AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        debugPrint('Creating notification channels');
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.createNotificationChannel(otpChannel);
        await androidPlugin.createNotificationChannel(testChannel);
        await androidPlugin.requestNotificationsPermission();
        debugPrint('Notification channels created');
      }
    }

    // Use the launcher icon instead of custom notification icon for better visibility
    debugPrint('Setting up notification initialization settings');
    var androidInitialize =
        const fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    var initializationsSettings = fln.InitializationSettings(
        android: androidInitialize, iOS: iOSInitialize);

    // Initialize the plugin with click handling
    await notificationsPlugin.initialize(
      initializationsSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
        try {
          debugPrint(
              'Notification clicked with response: ${response.toString()}');
          if (response.payload != null && response.payload!.isNotEmpty) {
            debugPrint('Notification payload: ${response.payload}');
            NotificationBodyModel payload =
                NotificationBodyModel.fromJson(jsonDecode(response.payload!));
            _handleNotificationNavigation(payload);
          } else {
            debugPrint('Empty payload, navigating to notification screen');
            Get.toNamed(
                RouteHelper.getNotificationRoute(fromNotification: true));
          }
        } catch (e) {
          debugPrint('Error handling notification click: $e');
          // Default navigation on error
          Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
        }
      },
    );
    debugPrint('Notification plugin initialized');

    // Request notification permissions for iOS
    if (GetPlatform.isIOS) {
      debugPrint('Setting iOS foreground notification options');
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Request notification permissions for Android (as a backup)
    if (GetPlatform.isAndroid) {
      try {
        debugPrint('Requesting Android notification permissions');
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
          criticalAlert: false,
          announcement: false,
        );
        debugPrint(
            'Android notification permission status: ${settings.authorizationStatus}');
      } catch (e) {
        debugPrint('Error requesting Android permission: $e');
      }
    }

    // Set up message handlers
    debugPrint('Setting up Firebase message listeners');

    // Handle messages that arrive when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("onMessage received: ${message.data}");
      _processNotification(message, notificationsPlugin);
    });

    // Handle when a notification is clicked and the app was in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("onMessageOpenedApp: ${message.data}");
      try {
        if (message.data.isNotEmpty) {
          NotificationBodyModel payload = convertNotification(message.data);
          _handleNotificationNavigation(payload);
        }
      } catch (e) {
        debugPrint('Error handling opened app notification: $e');
        // Default fallback
        Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
      }
    });

    debugPrint('NotificationHelper initialization complete');
  }

  static void _processNotification(RemoteMessage message,
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) {
    String? title = message.notification?.title ?? message.data['title'];
    String? body = message.notification?.body ?? message.data['body'];
    NotificationBodyModel notificationBody = convertNotification(message.data);

    if (message.data.containsKey('order_id') &&
        (message.data['type'] == 'order_otp' ||
            message.data.containsKey('otp'))) {
      _showNotification(
          title ?? 'Verification Code',
          body ?? 'Your verification code has arrived',
          'otp_channel',
          notificationBody,
          notificationsPlugin);
    } else if (message.data.containsKey('order_id') ||
        message.data['type'] == 'order_status') {
      _showNotification(
          title ?? 'Order Update',
          body ?? 'Your order status has been updated',
          'stackfood',
          notificationBody,
          notificationsPlugin);

      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<OrderController>().getPaginatedOrders(1, true);
        Get.find<OrderController>().getCurrentOrders();
      }
    } else {
      _showNotification(
          title ?? 'New Notification',
          body ?? 'You have a new notification',
          'stackfood',
          notificationBody,
          notificationsPlugin);
    }

    _processSpecialNotifications(message);
  }

  static Future<void> _showNotification(
      String title,
      String body,
      String channelId,
      NotificationBodyModel notificationBody,
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) async {
    debugPrint('_showNotification called with:');
    debugPrint('Title: $title');
    debugPrint('Body: $body');
    debugPrint('Channel ID: $channelId');
    debugPrint('NotificationBody: ${jsonEncode(notificationBody.toJson())}');

    if (GetPlatform.isAndroid) {
      fln.AndroidNotificationDetails androidDetails;

      // Configure notification details based on channel
      if (channelId == 'otp_channel') {
        androidDetails = const fln.AndroidNotificationDetails(
          'otp_channel',
          'OTP Notifications',
          channelDescription: 'This channel is used for OTP notifications',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: fln.NotificationVisibility.public,
          fullScreenIntent: true,
          ticker: 'New OTP notification',
        );
      } else if (channelId == 'test_only_channel') {
        androidDetails = const fln.AndroidNotificationDetails(
          'test_only_channel',
          'Test Notifications',
          channelDescription: 'This channel is used for test notifications',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: fln.NotificationVisibility.public,
          ticker: 'Test notification',
        );
      } else {
        // Default channel - stackfood
        androidDetails = const fln.AndroidNotificationDetails(
          'stackfood',
          'StackFood Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: fln.Importance.high,
          priority: fln.Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: fln.NotificationVisibility.public,
          ticker: 'New notification',
        );
      }

      // Create notification details with Android configuration
      final fln.NotificationDetails details =
          fln.NotificationDetails(android: androidDetails);

      try {
        // Use a unique ID for each notification
        final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
        debugPrint('Showing Android notification with ID: $id');

        // Display the notification
        await notificationsPlugin.show(
          id,
          title,
          body,
          details,
          payload: jsonEncode(notificationBody.toJson()),
        );
        debugPrint('Notification displayed successfully on Android');
      } catch (e) {
        debugPrint('Error displaying Android notification: $e');
      }
    } else if (GetPlatform.isIOS) {
      // Configure iOS notification
      const fln.DarwinNotificationDetails iOSDetails =
          fln.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      const fln.NotificationDetails details =
          fln.NotificationDetails(iOS: iOSDetails);

      try {
        // Display the notification on iOS
        final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
        debugPrint('Showing iOS notification with ID: $id');

        await notificationsPlugin.show(
          id,
          title,
          body,
          details,
          payload: jsonEncode(notificationBody.toJson()),
        );
        debugPrint('Notification displayed successfully on iOS');
      } catch (e) {
        debugPrint('Error displaying iOS notification: $e');
      }
    }
  }

  static void _processSpecialNotifications(RemoteMessage message) {
    if (message.data['type'] == 'maintenance') {
      Get.find<SplashController>().getConfigData();
    } else if (message.data['type'] == 'message') {
      _handleChatNotification(message);
    } else if (message.data['type'] == 'advertisement') {
      Get.find<AdvertisementController>().getAdvertisementList('1', 'all');
    }
  }

  static void _handleChatNotification(RemoteMessage message) {
    if (!Get.find<AuthController>().isLoggedIn()) return;

    if (Get.currentRoute.startsWith(RouteHelper.chatScreen)) {
      Get.find<ChatController>().getConversationList(1);
      if (Get.find<ChatController>()
              .messageModel!
              .conversation!
              .id
              .toString() ==
          message.data['conversation_id'].toString()) {
        Get.find<ChatController>().getMessages(
          1,
          NotificationBodyModel(
            notificationType: NotificationType.message,
            adminId:
                message.data['sender_type'] == UserType.admin.name ? 0 : null,
            customerId:
                message.data['sender_type'] == UserType.user.name ? 0 : null,
            deliveryManId:
                message.data['sender_type'] == UserType.delivery_man.name
                    ? 0
                    : null,
          ),
          null,
          int.parse(message.data['conversation_id'].toString()),
        );
      }
    } else if (Get.currentRoute
        .startsWith(RouteHelper.conversationListScreen)) {
      Get.find<ChatController>().getConversationList(1);
    }
  }

  static void _handleNotificationNavigation(NotificationBodyModel payload) {
    if (payload.notificationType == NotificationType.order) {
      Get.toNamed(RouteHelper.getOrderDetailsRoute(payload.orderId,
          fromNotification: true));
    } else if (payload.notificationType == NotificationType.message) {
      Get.toNamed(RouteHelper.getChatRoute(
        notificationBody: payload,
        conversationId: payload.conversationId,
        fromNotification: true,
      ));
    } else if (payload.notificationType == NotificationType.block ||
        payload.notificationType == NotificationType.unblock) {
      Get.toNamed(RouteHelper.getSignInRoute());
    } else if (payload.notificationType == NotificationType.withdraw) {
      Get.to(const DashboardScreen(pageIndex: 3));
    } else if (payload.notificationType == NotificationType.advertisement) {
      Get.toNamed(RouteHelper.getAdvertisementDetailsScreen(
          advertisementId: payload.advertisementId, fromNotification: true));
    } else if (payload.notificationType == NotificationType.campaign) {
      Get.toNamed(RouteHelper.getCampaignDetailsRoute(
          id: payload.campaignId, fromNotification: true));
    } else {
      Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
    }
  }

  static Future<String?> getFCMToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  static NotificationBodyModel convertNotification(Map<String, dynamic> data) {
    if (data['type'] == 'advertisement') {
      return NotificationBodyModel(
          notificationType: NotificationType.advertisement,
          advertisementId: int.parse(data['advertisement_id']));
    } else if (data['type'] == 'new_order' ||
        data['type'] == 'New order placed' ||
        data['type'] == 'order_status') {
      return NotificationBodyModel(
          orderId: int.parse(data['order_id']),
          notificationType: NotificationType.order);
    } else if (data['type'] == 'message') {
      return NotificationBodyModel(
        orderId: (data['order_id'] != null && data['order_id'].isNotEmpty)
            ? int.parse(data['order_id'])
            : null,
        conversationId: (data['conversation_id'] != null &&
                data['conversation_id'].isNotEmpty)
            ? int.parse(data['conversation_id'])
            : null,
        notificationType: NotificationType.message,
        type: data['sender_type'] == UserType.delivery_man.name
            ? UserType.delivery_man.name
            : UserType.customer.name,
      );
    } else if (data['type'] == 'block') {
      return NotificationBodyModel(notificationType: NotificationType.block);
    } else if (data['type'] == 'unblock') {
      return NotificationBodyModel(notificationType: NotificationType.unblock);
    } else if (data['type'] == 'withdraw') {
      return NotificationBodyModel(notificationType: NotificationType.withdraw);
    } else if (data['type'] == 'campaign') {
      return NotificationBodyModel(
          notificationType: NotificationType.campaign,
          campaignId: int.parse(data['data_id']));
    } else {
      return NotificationBodyModel(notificationType: NotificationType.general);
    }
  }

  // This method is called from main.dart
  static void showNotification(RemoteMessage message,
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) {
    debugPrint(
        'Showing notification: ${message.notification?.title ?? "No title"}');
    debugPrint('Notification data: ${message.data}');

    try {
      // First, determine the title and body from various sources
      String title = message.notification?.title ??
          message.data['title'] ??
          'New Notification';

      String body = message.notification?.body ??
          message.data['body'] ??
          'You have a new notification';

      debugPrint('Using title: $title, body: $body');

      // Convert notification data to our model
      NotificationBodyModel notificationBody =
          convertNotification(message.data);

      // Determine the appropriate channel
      String channelId = 'stackfood';
      if (message.data.containsKey('order_id') &&
          (message.data['type'] == 'order_otp' ||
              message.data.containsKey('otp'))) {
        channelId = 'otp_channel';
      }

      // Show the notification
      _showNotification(
          title, body, channelId, notificationBody, notificationsPlugin);
    } catch (e) {
      debugPrint('Error showing notification: $e');

      // Fallback to a simple notification as a last resort
      _showSimpleNotification('New Notification', 'You have a new notification',
          notificationsPlugin);
    }
  }

  // Simplified notification display for fallback scenarios
  static Future<void> _showSimpleNotification(String title, String body,
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) async {
    try {
      if (GetPlatform.isAndroid) {
        const fln.AndroidNotificationDetails androidDetails =
            fln.AndroidNotificationDetails(
          'stackfood',
          'StackFood Notifications',
          channelDescription:
              'This channel is used for important notifications',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          ticker: 'New notification',
        );

        const fln.NotificationDetails details =
            fln.NotificationDetails(android: androidDetails);

        await notificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          title,
          body,
          details,
        );
        debugPrint('Simple notification displayed');
      }
    } catch (e) {
      debugPrint('Error showing simple notification: $e');
    }
  }

  // Add a test notification function to verify notification system
  static Future<void> _displayTestNotification(
      fln.FlutterLocalNotificationsPlugin notificationsPlugin) async {
    try {
      if (GetPlatform.isAndroid) {
        const fln.AndroidNotificationDetails androidDetails =
            fln.AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'This channel is used for test notifications',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          enableLights: true,
          enableVibration: true,
          playSound: true,
          visibility: fln.NotificationVisibility.public,
          ticker: 'Test notification',
        );

        const fln.NotificationDetails details =
            fln.NotificationDetails(android: androidDetails);

        await notificationsPlugin.show(
          100,
          'Test Notification',
          'This is a test notification to verify the system is working',
          details,
        );
        debugPrint('Test notification displayed');
      }
    } catch (e) {
      debugPrint('Error displaying test notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<dynamic> myBackgroundMessageHandler(RemoteMessage message) async {
  debugPrint("onBackground: Message received in background handler");
  debugPrint("Message data: ${message.data}");
  debugPrint(
      "Message notification: ${message.notification?.title} - ${message.notification?.body}");

  try {
    // Initialize Firebase first
    await Firebase.initializeApp();
    debugPrint("Firebase initialized in background handler");

    // Initialize the notification plugin
    fln.FlutterLocalNotificationsPlugin notificationsPlugin =
        fln.FlutterLocalNotificationsPlugin();

    // Initialize with the launcher icon for better visibility
    var androidInitialize =
        const fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOSInitialize = const fln.DarwinInitializationSettings();
    var initializationsSettings = fln.InitializationSettings(
        android: androidInitialize, iOS: iOSInitialize);

    await notificationsPlugin.initialize(initializationsSettings);
    debugPrint("Notification plugin initialized in background handler");

    // Create notification channel for Android
    if (GetPlatform.isAndroid) {
      const fln.AndroidNotificationChannel channel =
          fln.AndroidNotificationChannel(
        'stackfood',
        'StackFood Notifications',
        description: 'This channel is used for important notifications.',
        importance: fln.Importance.high,
        enableVibration: true,
        playSound: true,
      );

      final fln.AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          notificationsPlugin.resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        debugPrint("Notification channel created in background handler");
      }
    }

    // Extract notification title and body with non-nullable defaults
    String title = message.notification?.title ??
        message.data['title'] ??
        'New Notification';

    String body = message.notification?.body ??
        message.data['body'] ??
        'You have a new notification';

    debugPrint(
        "Showing background notification with: Title: $title, Body: $body");

    // Determine appropriate channel
    String channelId = 'stackfood';
    fln.Importance importance = fln.Importance.high;

    if (message.data.containsKey('order_id') &&
        (message.data['type'] == 'order_otp' ||
            message.data.containsKey('otp'))) {
      channelId = 'otp_channel';
      importance = fln.Importance.max;
    }

    // Show notification on Android
    if (GetPlatform.isAndroid) {
      fln.AndroidNotificationDetails androidDetails =
          fln.AndroidNotificationDetails(
        channelId,
        channelId == 'otp_channel'
            ? 'OTP Notifications'
            : 'StackFood Notifications',
        importance: importance,
        priority: fln.Priority.high,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        ticker: 'New notification',
        visibility: fln.NotificationVisibility.public,
        fullScreenIntent: channelId == 'otp_channel',
      );

      fln.NotificationDetails platformDetails =
          fln.NotificationDetails(android: androidDetails);

      // Use a unique ID for each notification based on current time
      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
      );
      debugPrint("Background notification displayed on Android with ID: $id");
    }
    // Show notification on iOS
    else if (GetPlatform.isIOS) {
      const fln.DarwinNotificationDetails iOSDetails =
          fln.DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'notification.wav',
      );
      const fln.NotificationDetails platformDetails =
          fln.NotificationDetails(iOS: iOSDetails);

      final int id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await notificationsPlugin.show(
        id,
        title,
        body,
        platformDetails,
      );
      debugPrint("Background notification displayed on iOS with ID: $id");
    }

    return Future<void>.value();
  } catch (e) {
    debugPrint("Error handling background notification: $e");
    // Always return a completed future
    return Future<void>.value();
  }
}
