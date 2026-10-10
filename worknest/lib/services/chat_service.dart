import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  final String role; // "user" or "assistant"
  final String text;
  ChatMessage({required this.role, required this.text});
}

/// Sends chat messages to the `chat` Supabase Edge Function
/// (supabase/functions/chat), which retrieves the relevant company policy
/// excerpts and calls the AI model.
///
/// The AI API key is a Supabase secret that only the Edge Function can read —
/// the app authenticates with the signed-in user's session instead, so no AI
/// key is shipped inside the APK.
class ChatService {
  Future<String> send(String message, List<ChatMessage> history) async {
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'chat',
        body: {
          'message': message,
          'history':
              history.map((m) => {'role': m.role, 'text': m.text}).toList(),
        },
      );

      final data = res.data;
      if (data is! Map || data['ok'] != true) {
        throw Exception(
            (data is Map ? data['reply'] : null) ?? 'AI assistant error.');
      }
      return data['reply'] as String;
    } on FunctionException catch (e) {
      final details = e.details;
      throw Exception(details is Map && details['reply'] != null
          ? details['reply']
          : 'AI assistant error (${e.status}).');
    }
  }
}
