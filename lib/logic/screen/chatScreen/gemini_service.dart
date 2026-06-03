// lib/logic/screen/chatScreen/gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // ── Groq API — dùng cho chat text ────────────────────────
  static const String _groqApiKey  = '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';   // ← groq key
  static const String _groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _groqModel   = 'llama-3.3-70b-versatile';

  // ── Gemini API — dùng cho phân tích ảnh (Vision) ─────────
  static const String _geminiApiKey  = 'AIzaSyC-TvfbwVBxj9JdENs-w1e9nSrYP6Sq4fc'; // ← gemini key
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  static const String _systemPrompt = '''
Bạn là trợ lý AI chuyên về nông nghiệp, đặc biệt là chẩn đoán bệnh cây trồng.
Hãy trả lời bằng tiếng Việt, ngắn gọn, dễ hiểu cho nông dân.
Khi được cung cấp kết quả chẩn đoán bệnh, hãy giải thích:
1. Nguyên nhân gây bệnh
2. Triệu chứng nhận biết
3. Cách điều trị cụ thể
4. Biện pháp phòng ngừa
Luôn kết thúc bằng lời khuyến nghị đi thăm cơ quan nông nghiệp địa phương nếu bệnh nghiêm trọng.
''';

  // ── Chat text → Groq ──────────────────────────────────────

  Future<String> sendMessage(List<Map<String, dynamic>> history) async {
    try {
      // Chuyển format Gemini → OpenAI (Groq dùng format OpenAI)
      final messages = [
        {'role': 'system', 'content': _systemPrompt},
        ...history.map((m) => {
          'role':    m['role'] == 'model' ? 'assistant' : m['role'],
          'content': (m['parts'] as List).first['text'],
        }),
      ];

      final response = await http.post(
        Uri.parse(_groqBaseUrl),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model':       _groqModel,
          'messages':    messages,
          'temperature': 0.7,
          'max_tokens':  4096,
        }),
      ).timeout(const Duration(seconds: 30));

      print('>>> [Groq] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] as String;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Groq API lỗi');
    } catch (e) {
      print('>>> [Groq] Exception: $e');
      throw Exception('Không thể kết nối AI: $e');
    }
  }

  // ── Phân tích ảnh → Gemini 2.5 Flash Vision ──────────────

  Future<String> analyzeImageWithAI(String imagePath) async {
    try {
      final imageBytes  = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);
      final ext         = imagePath.split('.').last.toLowerCase();
      final mimeType    = ext == 'png' ? 'image/png' : 'image/jpeg';

      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'system_instruction': {
            'parts': [{'text': _systemPrompt}]
          },
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data':      base64Image,
                  }
                },
                {
                  'text': 'Hãy phân tích lá cây trong ảnh và chẩn đoán bệnh. '
                      'Nếu phát hiện bệnh: cho biết tên bệnh, nguyên nhân, '
                      'triệu chứng, cách điều trị và phòng ngừa. '
                      'Nếu cây khỏe mạnh: xác nhận và đưa lời khuyên chăm sóc.',
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature':     0.4,
            'maxOutputTokens': 8192,
          },
        }),
      ).timeout(const Duration(seconds: 45));

      print('>>> [Gemini Vision] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['error']['message'] ?? 'Gemini Vision lỗi');
    } catch (e) {
      print('>>> [Gemini Vision] Exception: $e');
      rethrow; // chat_notifier sẽ fallback TFLite
    }
  }
}