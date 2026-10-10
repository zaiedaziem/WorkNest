import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

const noInternetMessage =
    'No internet connection. Please check your connection and try again.';

/// True when [error] was caused by the device being offline or the server
/// being unreachable (rather than by the request itself being rejected).
bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;
  final text = error.toString();
  return text.contains('SocketException') ||
      text.contains('Failed host lookup') ||
      text.contains('ClientException') ||
      text.contains('Failed to fetch') ||
      text.contains('XMLHttpRequest') ||
      text.contains('Network is unreachable') ||
      text.contains('Connection refused') ||
      text.contains('Connection reset') ||
      text.contains('Connection closed');
}

/// Turns any error into a short message that is safe to show to the user.
///
/// Database rules (e.g. "You are 350m away from the office") arrive as
/// [PostgrestException]s; showing just their message keeps the server's
/// wording without the technical wrapper.
String friendlyError(Object error) {
  if (isNetworkError(error)) return noInternetMessage;
  if (error is PostgrestException) return error.message;
  if (error is AuthException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}
