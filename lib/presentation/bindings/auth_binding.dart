import 'package:get/get.dart';

/// Route-level binding for Splash + Login screens.
///
/// All auth dependencies are registered permanently by [AppBinding] at
/// startup, so this binding is intentionally empty. It exists only to satisfy
/// the [GetPage.binding] contract and to serve as the extension point for any
/// future route-scoped work.
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // All auth deps (FirestoreService, repositories, use-cases, AuthController)
    // are permanent singletons registered once in AppBinding (main.dart).
    // Nothing to do here.
  }
}
