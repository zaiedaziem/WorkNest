import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role; // "user" or "assistant"
  final String text;
  ChatMessage({required this.role, required this.text});
}

class ChatService {
  static String get _groqKey     => dotenv.env['GROQ_API_KEY']     ?? '';
  static String get _supabaseUrl => dotenv.env['SUPABASE_URL']     ?? '';
  static String get _supabaseKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static const _baseSystemPrompt =
      'You are an HR assistant for WorkNest, a Malaysian HR system. '
      'Be concise and helpful. Reply in English only. '
      'EPF=11%, SOCSO=0.5%, EIS=0.2%. OT: weekday 1.5x, rest day 2x, public holiday 3x. '
      'Annual leave: <2yrs=8d, 2-5yrs=12d, >5yrs=16d. Sick: <2yrs=14d, 2-5yrs=18d, >5yrs=22d. '
      'If unsure, advise checking with HR directly.';

  Future<String> send(String message, List<ChatMessage> history) async {
    // 1. Load relevant policy chunks from Supabase (best-effort)
    String policyContext = '';
    try {
      policyContext = await _loadAllChunks(message, topK: 1);
    } catch (_) {
      // Non-fatal — proceed without policy context
    }

    // 2. Build system prompt
    final systemPrompt = policyContext.isEmpty
        ? _baseSystemPrompt
        : '$_baseSystemPrompt\n'
          '=== COMPANY POLICY DOCUMENT ===\n'
          'The following is the full content of the company\'s official HR policy document.\n'
          'Use it to answer policy-related questions accurately:\n\n'
          '$policyContext\n'
          '=== END OF POLICY DOCUMENT ===\n';

    // 3. Build messages
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.text}),
      {'role': 'user', 'content': message},
    ];

    final body = jsonEncode({
      'model': 'llama-3.1-8b-instant',
      'messages': messages,
      'max_tokens': 768,
    });

    // 4. Call Groq
    final res = await http.post(
      Uri.parse(_groqUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_groqKey',
      },
      body: body,
    );

    final data = jsonDecode(res.body);

    if (data['error'] != null) {
      throw Exception(data['error']['message'] ?? 'Groq API error');
    }

    return data['choices'][0]['message']['content'] as String;
  }

  // Load relevant chunks — keyword-scored, top 3 only
  Future<String> _loadAllChunks(String query, {int topK = 2}) async {
    if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) return '';

    final res = await http.get(
      Uri.parse(
          '$_supabaseUrl/rest/v1/policy_chunks?select=content&order=chunk_index.asc'),
      headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      },
    );

    final List data = jsonDecode(res.body);
    if (data.isEmpty) return '';

    final chunks = data
        .map((d) {
          final c = (d['content'] as String? ?? '').trim();
          return c.length > 600 ? '${c.substring(0, 600)}…' : c;
        })
        .where((c) => c.isNotEmpty)
        .toList();

    final selected = _selectRelevantChunks(chunks, query, topK: topK);

    final buffer = StringBuffer();
    for (int i = 0; i < selected.length; i++) {
      buffer.writeln('[Section ${i + 1}]');
      buffer.writeln(selected[i]);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  List<String> _selectRelevantChunks(List<String> chunks, String query,
      {int topK = 3}) {
    if (query.isEmpty) return chunks.take(topK).toList();

    final stopWords = {
      'what','is','the','how','many','can','i','a','an','for','of','in',
      'to','and','or','do','does','are','was','will','my','me','we','our',
      'about','this','that','it','with','be','have','has','ada','yang','dan',
      'di','ke','dari','untuk','pada','ini','itu','tidak','boleh','dengan'
    };

    final queryWords = query
        .toLowerCase()
        .split(RegExp(r'[ ?,\.!]+'))
        .where((w) => w.length > 2 && !stopWords.contains(w))
        .toList();

    if (queryWords.isEmpty) return chunks.take(topK).toList();

    // Score and sort
    final scored = List.generate(chunks.length, (idx) {
      final lower = chunks[idx].toLowerCase();
      final score = queryWords.where((w) => lower.contains(w)).length;
      return {'idx': idx, 'score': score, 'chunk': chunks[idx]};
    });

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final top = scored.take(topK).toList();
    top.sort((a, b) => (a['idx'] as int).compareTo(b['idx'] as int));
    return top.map((e) => e['chunk'] as String).toList();
  }
}
