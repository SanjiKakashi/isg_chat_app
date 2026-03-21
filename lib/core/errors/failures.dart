/// Typed failure hierarchy returned instead of throwing raw exceptions.
abstract class Failure {
  const Failure(this.message);
  final String message;
}

/// Firebase Auth failure.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Firestore operation failure.
class FirestoreFailure extends Failure {
  const FirestoreFailure(super.message);
}

/// User cancelled the sign-in flow.
class CancelledFailure extends Failure {
  const CancelledFailure() : super('');
}

/// No internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure() : super('No internet connection. Please try again.');
}

/// Failure — carries the HTTP [statusCode] for precise handling.
class AiFailure extends Failure {
  const AiFailure(super.message, {required this.statusCode});

  /// The raw HTTP status code returned by the API.
  final int statusCode;

  bool get isRateLimit => statusCode == 429;
  bool get isUnauthorised => statusCode == 401;
  bool get isServerError => statusCode >= 500;
}

