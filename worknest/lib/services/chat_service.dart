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
      'Base every factual answer strictly on the COMPANY POLICY DOCUMENT EXCERPTS '
      'provided below, when present — they are this company\'s actual policy and '
      'always take priority over any general assumption you might otherwise make '
      'about typical Malaysian HR rules (leave entitlements, EPF/SOCSO/EIS rates, '
      'claim amounts, etc. vary by company). '
      'If the excerpts do not contain the answer, say so explicitly and advise the '
      'employee to check with HR directly — do not guess or invent a number or '
      'policy detail.';

  Future<String> send(String message, List<ChatMessage> history) async {
    // 1. Load relevant policy chunks from Supabase (best-effort)
    String policyContext = '';
    try {
      policyContext = await _loadAllChunks(message, topK: 4);
    } catch (_) {
      // Non-fatal — proceed without policy context
    }

    // 2. Build system prompt
    final systemPrompt = policyContext.isEmpty
        ? _baseSystemPrompt
        : '$_baseSystemPrompt\n'
          '=== COMPANY POLICY DOCUMENT EXCERPTS ===\n'
          'Each excerpt below is labeled with its source page number. When your '
          'answer relies on one of these excerpts, mention the page it came from '
          '(e.g. "see page 5 of the policy document"). Only cite a page when the '
          'excerpt actually informed your answer — do not invent page numbers.\n\n'
          '$policyContext\n'
          '=== END OF POLICY DOCUMENT EXCERPTS ===\n';

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
      'temperature': 0.2,
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

  // Load relevant chunks — keyword-scored, top N (default 2)
  Future<String> _loadAllChunks(String query, {int topK = 2}) async {
    if (_supabaseUrl.isEmpty || _supabaseKey.isEmpty) return '';

    final res = await http.get(
      Uri.parse(
          '$_supabaseUrl/rest/v1/policy_chunks?select=content,page_number&order=chunk_index.asc'),
      headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      },
    );

    final List data = jsonDecode(res.body);
    if (data.isEmpty) return '';

    // NOTE: chunks are kept at FULL length here — do not truncate before the
    // full-document-vs-fallback decision below, or full-document mode ends up
    // silently sending clipped policy text to the model on every message.
    // Truncation only happens inside _selectRelevantChunks, for the chunks
    // that actually get selected in fallback mode.
    final chunks = data
        .map((d) {
          final c = (d['content'] as String? ?? '').trim();
          return (content: c, page: d['page_number'] as int?);
        })
        .where((c) => c.content.isNotEmpty)
        .toList();

    // For "what's new" / "summarize" type questions, keyword-matching a
    // handful of chunks isn't enough — the model needs to see the whole
    // document. If everything fits comfortably in context, send it all
    // (in page order) instead of narrowing to a keyword-scored subset. The
    // keyword scorer below only matches literal substrings, so it's
    // effectively blind whenever the policy document and the question are in
    // different languages (e.g. an English question against a Bahasa Melayu
    // policy document) — keeping this threshold generous avoids relying on
    // that fallback until it's actually necessary for a large document.
    const maxTotalChars = 60000; // ≈ 15k tokens, comfortably inside Llama 3.1's context window
    final totalChars = chunks.fold<int>(0, (sum, c) => sum + c.content.length);

    final selected = totalChars <= maxTotalChars
        ? chunks
        : _selectRelevantChunks(chunks, query, topK: 6);

    final buffer = StringBuffer();
    for (final chunk in selected) {
      buffer.writeln(
          '[${chunk.page != null ? 'Page ${chunk.page}' : 'Page unknown'}]');
      buffer.writeln(chunk.content);
      buffer.writeln();
    }
    return buffer.toString().trim();
  }

  List<({String content, int? page})> _selectRelevantChunks(
      List<({String content, int? page})> chunks, String query,
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
      final lower = chunks[idx].content.toLowerCase();
      final score = queryWords.where((w) => lower.contains(w)).length;
      return (idx: idx, score: score, chunk: chunks[idx]);
    });

    scored.sort((a, b) => b.score.compareTo(a.score));

    final top = scored.take(topK).toList();
    top.sort((a, b) => a.idx.compareTo(b.idx));
    // Truncate only here, for the handful of chunks actually selected in
    // fallback mode — keeps token usage bounded without clipping content
    // that full-document mode would otherwise send whole.
    return top.map((e) {
      final c = e.chunk.content;
      final truncated = c.length > 600 ? '${c.substring(0, 600)}…' : c;
      return (content: truncated, page: e.chunk.page);
    }).toList();
  }
}
