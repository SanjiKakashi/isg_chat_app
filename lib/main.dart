import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:isg_chat_app/core/theme/app_theme.dart';
import 'package:isg_chat_app/firebase_options.dart';
import 'package:isg_chat_app/presentation/bindings/app_binding.dart';
import 'package:isg_chat_app/routes/app_routes.dart';

/// App entry point.
///
/// Initialises Firebase before [runApp] (FR-006) and delegates all
/// routing to GetX named routes.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for a chat-focused experience.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const IsgChatApp());
}

/// Root widget.
///
/// Uses [GetMaterialApp] to enable GetX navigation and snackbar support.
/// The initial route is the Splash screen which decides where to go next.
class IsgChatApp extends StatelessWidget {
  const IsgChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ISG Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}
