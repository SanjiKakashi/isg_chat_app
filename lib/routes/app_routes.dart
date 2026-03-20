import 'package:get/get.dart';
import 'package:isg_chat_app/presentation/bindings/auth_binding.dart';
import 'package:isg_chat_app/presentation/bindings/chat_binding.dart';
import 'package:isg_chat_app/presentation/pages/chat_page.dart';
import 'package:isg_chat_app/presentation/pages/login_page.dart';
import 'package:isg_chat_app/presentation/pages/splash_page.dart';

/// Named route constants for the entire app.
///
/// All navigation calls use these constants — no hard-coded strings anywhere.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String chat = '/chat';

  /// The list of [GetPage] entries consumed by [GetMaterialApp.getPages].
  static final List<GetPage<dynamic>> pages = [
    GetPage<void>(
      name: splash,
      page: SplashPage.new,
      binding: AuthBinding(),
    ),
    GetPage<void>(
      name: login,
      page: LoginPage.new,
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<void>(
      name: chat,
      page: ChatPage.new,
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}

