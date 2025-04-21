import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:stackfood_multivendor_restaurant/features/home/widgets/trial_widget.dart';
import 'package:stackfood_multivendor_restaurant/features/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor_restaurant/common/controllers/theme_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/chat/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor_restaurant/features/profile/controllers/profile_controller.dart';
import 'package:stackfood_multivendor_restaurant/helper/date_converter_helper.dart';
import 'package:stackfood_multivendor_restaurant/helper/notification_helper.dart';
import 'package:stackfood_multivendor_restaurant/helper/route_helper.dart';
import 'package:stackfood_multivendor_restaurant/theme/dark_theme.dart';
import 'package:stackfood_multivendor_restaurant/theme/light_theme.dart';
import 'package:stackfood_multivendor_restaurant/util/app_constants.dart';
import 'package:stackfood_multivendor_restaurant/util/messages.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:url_strategy/url_strategy.dart';
import 'helper/get_di.dart' as di;
import 'package:stackfood_multivendor_restaurant/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor_restaurant/features/dashboard/screens/dashboard_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  if (!GetPlatform.isWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
  setPathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  Map<String, Map<String, String>> languages = await di.init();

  // Initialize local notifications plugin
  var androidInitialize =
      const AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOSInitialize = const DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  var initializationsSettings =
      InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  await flutterLocalNotificationsPlugin.initialize(initializationsSettings);

  // Create notification channels
  if (GetPlatform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'stackfood', // id
      'StackFood Notifications', // title
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Notifications',
      description: 'This channel is used for test notifications.',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
      await androidPlugin.createNotificationChannel(testChannel);
      await androidPlugin.requestNotificationsPermission();
    }
  }

  try {
    if (GetPlatform.isAndroid) {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyAeBvXjTdJGACPYEGfXBThsOiFOO-Dlj40',
            appId: '1:629553534814:android:5dfc7ed901be63eaa9a1cf',
            messagingSenderId: '629553534814',
            projectId: 'com.carrotfooddeliv.store',
          ),
        );
        debugPrint('Firebase initialized successfully with provided options');
      } else {
        debugPrint('Firebase was already initialized');
      }
    } else {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint(
            'Firebase initialized successfully for non-Android platform');
      } else {
        debugPrint('Firebase was already initialized');
      }
    }

    // Verify Firebase is working by getting the FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    debugPrint('=========Initial FCM Token: $token');

    // Make sure we are subscribed to the topic
    await FirebaseMessaging.instance.subscribeToTopic('restaurant_app');
    debugPrint('Subscribed to topic: restaurant_app');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Try alternative initialization method as fallback
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('Firebase initialized with fallback method');
      }
    } catch (fallbackError) {
      debugPrint(
          'Fallback Firebase initialization also failed: $fallbackError');
    }
  }

  // Show a test notification to verify system
  await _showTestNotification(flutterLocalNotificationsPlugin);

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      debugPrint('Initializing Firebase Messaging...');

      // Request notification permissions explicitly
      if (GetPlatform.isAndroid) {
        NotificationSettings settings =
            await FirebaseMessaging.instance.requestPermission(
          alert: true,
          announcement: true,
          badge: true,
          carPlay: false,
          criticalAlert: true,
          provisional: false,
          sound: true,
        );
        debugPrint(
            'Notification permission status: ${settings.authorizationStatus}');
      }

      // Enable foreground notifications for iOS
      if (GetPlatform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Set up token refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint('Token refreshed: $newToken');
        // Update token in backend if user is logged in
        if (Get.find<AuthController>().isLoggedIn()) {
          Get.find<AuthController>().updateToken();
        }
      });

      // Process message that caused app to open
      final RemoteMessage? remoteMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        debugPrint('Initial message data: ${remoteMessage.data}');
        body = NotificationHelper.convertNotification(remoteMessage.data);
        // Show a notification for the initial message for testing
        debugPrint('Showing notification for initial message');
        NotificationHelper.showNotification(
            remoteMessage, flutterLocalNotificationsPlugin);
      }

      // Set up foreground message handler - MOST IMPORTANT FOR IN-APP NOTIFICATIONS
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received with data: ${message.data}');
        debugPrint('Notification title: ${message.notification?.title}');
        debugPrint('Notification body: ${message.notification?.body}');

        // Show local notification
        NotificationHelper.showNotification(
            message, flutterLocalNotificationsPlugin);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

      // Set up message opened handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Message opened app with data: ${message.data}');
        try {
          NotificationBodyModel payload =
              NotificationHelper.convertNotification(message.data);
          if (payload.notificationType != null) {
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
              Get.to(() => const DashboardScreen(pageIndex: 3));
            } else if (payload.notificationType ==
                NotificationType.advertisement) {
              Get.toNamed(RouteHelper.getAdvertisementDetailsScreen(
                  advertisementId: payload.advertisementId,
                  fromNotification: true));
            } else if (payload.notificationType == NotificationType.campaign) {
              Get.toNamed(RouteHelper.getCampaignDetailsRoute(
                  id: payload.campaignId, fromNotification: true));
            } else {
              Get.toNamed(
                  RouteHelper.getNotificationRoute(fromNotification: true));
            }
          }
        } catch (e) {
          debugPrint('Error handling opened app notification: $e');
        }
      });

      // Initialize notification helper
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);

      // Clear all existing notifications in the tray
      await flutterLocalNotificationsPlugin.cancelAll();

      // Schedule a delayed token refresh
      Future.delayed(const Duration(seconds: 5), () async {
        final token = await FirebaseMessaging.instance.getToken();
        debugPrint('Delayed token check: $token');
      });
    }
  } catch (e) {
    debugPrint('Error in Firebase Messaging setup: $e');
  }

  runApp(MyApp(languages: languages, body: body));

  // Schedule a delayed test notification to ensure the system is properly initialized
  Future.delayed(const Duration(seconds: 5), () {
    debugPrint('Sending delayed test notification');
  });
}

// Function to show a test notification for debugging purposes
Future<void> _showTestNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
  try {
    if (GetPlatform.isAndroid) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'This channel is used for test notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Test notification',
      );

      const NotificationDetails details =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        99,
        'App Started',
        'Notification system is being tested',
        details,
      );
      debugPrint('Startup test notification sent');
    }
  } catch (e) {
    debugPrint('Error showing test notification: $e');
  }
}

// Function to directly show a notification
Future<void> _showDirectNotification(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
    String title,
    String body) async {
  try {
    if (GetPlatform.isAndroid) {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'This channel is used for test notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'Direct notification',
      );

      const NotificationDetails details =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        details,
      );
      debugPrint('Direct notification shown: $title - $body');
    }
  } catch (e) {
    debugPrint('Error showing direct notification: $e');
  }
}

class MyApp extends StatelessWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  const MyApp({super.key, required this.languages, required this.body});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    Get.find<ProfileController>().setTrialWidgetNotShow(false);

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetMaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: Get.key,
          theme: themeController.darkTheme ? dark : light,
          locale: localizeController.locale,
          translations: Messages(languages: languages),
          fallbackLocale: Locale(AppConstants.languages[0].languageCode!,
              AppConstants.languages[0].countryCode),
          initialRoute: RouteHelper.getSplashRoute(body),
          getPages: RouteHelper.routes,
          defaultTransition: Transition.topLevel,
          transitionDuration: const Duration(milliseconds: 500),
          builder: (BuildContext context, widget) {
            return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
                child: Material(
                  child: Stack(children: [
                    widget!,
                    GetBuilder<ProfileController>(builder: (profileController) {
                      bool canShow = profileController.profileModel != null &&
                          profileController.profileModel!.subscription !=
                              null &&
                          profileController
                                  .profileModel!.subscription!.isTrial ==
                              1 &&
                          profileController
                                  .profileModel!.subscription!.status ==
                              1 &&
                          DateConverter.differenceInDaysIgnoringTime(
                                  DateTime.parse(profileController
                                      .profileModel!.subscription!.expiryDate!),
                                  null) >=
                              0;

                      return canShow && !profileController.trialWidgetNotShow
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 90),
                                child: TrialWidget(
                                    subscription: profileController
                                        .profileModel!.subscription!),
                              ),
                            )
                          : const SizedBox();
                    }),
                  ]),
                ));
          },
        );
      });
    });
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
