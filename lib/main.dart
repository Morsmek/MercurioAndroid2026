import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mercurio_messenger/firebase_options.dart';
import 'package:mercurio_messenger/utils/theme.dart';
import 'package:mercurio_messenger/screens/splash_screen.dart';
import 'package:mercurio_messenger/services/firebase_messaging_service.dart';

void main() async {
  // Set status bar style for dark theme
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase messaging service
  await FirebaseMessagingService().initialize();

  runApp(const MercurioApp());
}

class MercurioApp extends StatelessWidget {
  const MercurioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercurio Messenger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
