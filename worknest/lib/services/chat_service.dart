import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role; // "user" or "assistant"
  final String text;
  ChatMessage({required this.role, required this.text});
}

class ChatService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt = '''
You are an HR assistant for WorkNest, an HR management system used by Malaysian companies.

WORKNEST SYSTEM:
- Employees use the mobile app to clock in/out (GPS for office, WFH mode for remote)
- Leave, claims, and OT requests are submitted in the app and approved by HR
- Payslips are available in the app after HR finalizes monthly payroll

PAYROLL & DEDUCTIONS:
- EPF: 11% of basic salary | SOCSO: 0.5% of gross | EIS: 0.2% of gross
- OT: Weekday 1.5x, Rest day 2.0x, Public holiday 3.0x hourly rate
- Absent days without approved leave are deducted from salary

LEAVE POLICY (Employment Act 1955):
- Annual Leave: <2 years=8 days, 2-5 years=12 days, >5 years=16 days
- Sick Leave (with MC): <2 years=14 days, 2-5 years=18 days, >5 years=22 days
- Hospitalization: up to 60 days/year | Maternity: 98 days
- All leave must be applied in WorkNest and approved before taking leave
- Unpaid leave is deducted from payroll

CLAIMS:
- Types: Medical, Travel, Meal, Accommodation, Others
- All claims need receipts and must be approved by HR
- Reimbursed through monthly payroll

OVERTIME:
- Must be pre-approved in WorkNest before working OT
- Hourly rate = Basic Salary ÷ Working Days per Month ÷ Hours per Day

ATTENDANCE:
- Office: GPS must be within office location radius
- WFH: select WFH mode, no GPS required
- Late arrivals flagged based on company work start time

Be concise, friendly and professional. Always reply in English regardless of the language the user writes in.
If unsure, advise the user to check with HR directly.
''';

  Future<String> send(String message, List<ChatMessage> history) async {
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => {'role': m.role, 'content': m.text}),
      {'role': 'user', 'content': message},
    ];

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': messages,
      'max_tokens': 1024,
    });

    final res = await http.post(
      Uri.parse(_url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: body,
    );

    final data = jsonDecode(res.body);

    if (data['error'] != null) {
      throw Exception(data['error']['message'] ?? 'Groq API error');
    }

    return data['choices'][0]['message']['content'] as String;
  }
}
