import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/income_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/reports_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'providers/profile_provider.dart'; // ✅ Import ProfileProvider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initializeNotifications(); // Initialize Notifications

  runApp(MyApp());
}

// 🔔 Initialize Notifications
Future<void> _initializeNotifications() async {
  await AwesomeNotifications().initialize(
    'resource://drawable/ic_stat_notification',
    [
      NotificationChannel(
        channelKey: 'reminder_channel',
        channelName: 'Reminders',
        channelDescription: 'Daily reminders to add expenses',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
      )
    ],
  );

  // Request Permission (Android 13+)
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }
}

// 📢 Show Notification on App Launch
Future<void> _showReminderNotification() async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 1,
      channelKey: 'reminder_channel',
      title: 'Reminder!',
      body: 'Don’t forget to add your income or expenses today.',
      notificationLayout: NotificationLayout.Default,
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _showReminderNotification(); // 🔔 Show notification on launch

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()), // ✅ Register ProfileProvider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/signup': (context) => SignUpScreen(),
          '/home': (context) => HomeScreen(),
          '/income': (context) => IncomePage(),
          '/expense': (context) => ExpensePage(),
          '/reports': (context) => ReportsScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          print("User is logged in: ${snapshot.data?.email}");
          return HomeScreen();
        }
        print("No user found, redirecting to login screen.");
        return LoginScreen();
      },
    );
  }
}
