import 'package:flutter/material.dart';
import 'package:focus_badminton/provider/cart_provider.dart';
import 'package:focus_badminton/provider/notification_provider.dart';
import 'main_screen.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import './screens/splash_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        // home: MainScreen(),
        home: SplashScreen(),
      ),
    );
  }
}
