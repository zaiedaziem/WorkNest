import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worknest/services/error_message.dart';

void main() {
  group('friendlyError', () {
    test('network failures become a clear "no internet" message', () {
      expect(friendlyError(TimeoutException('slow')), noInternetMessage);
      expect(friendlyError(Exception('SocketException: Failed host lookup: x.supabase.co')),
          noInternetMessage);
      expect(friendlyError(Exception('ClientException: Failed to fetch')), noInternetMessage);
    });

    test('database rule errors show only their message', () {
      const e = PostgrestException(
        message: 'You are 350m away from the office. Must be within 100m.',
        code: 'P0001',
      );

      expect(friendlyError(e), 'You are 350m away from the office. Must be within 100m.');
    });

    test('auth errors show only their message', () {
      expect(friendlyError(const AuthException('Invalid login credentials')),
          'Invalid login credentials');
    });

    test('app exceptions drop the "Exception: " prefix', () {
      expect(friendlyError(Exception('Only pending requests can be cancelled.')),
          'Only pending requests can be cancelled.');
    });
  });

  group('isNetworkError', () {
    test('is false for errors that are not about connectivity', () {
      expect(isNetworkError(Exception('Insufficient balance.')), isFalse);
      expect(isNetworkError(const PostgrestException(message: 'denied')), isFalse);
    });
  });
}
