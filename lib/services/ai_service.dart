import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey;

  AIService({required this.apiKey});

  Future<Map<String, dynamic>> verifyDocument(String text, String category, String userName) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey');

    final prompt = '''
You are an intelligent document verification system for a university.
Analyze the extracted OCR text from the student's document and determine if it should be approved or rejected.
- Student Name: "$userName"
- Document Category: "$category"
- Extracted Text: """$text"""

Based on your analysis, provide the following information:
- is_category_match: Does the document content match the provided category?
- is_name_match: Does the student's name appear in the document?
- status: "approved" or "rejected".
- comments: Your detailed explanation for the decision.
''';

    final requestBody = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 2048,
        "responseMimeType": "application/json",
        "responseSchema": {
          "type": "object",
          "properties": {
            "is_category_match": {"type": "boolean"},
            "is_name_match": {"type": "boolean"},
            "status": {"type": "string"},
            "comments": {"type": "string"}
          },
          "required": ["is_category_match", "is_name_match", "status", "comments"]
        }
      },
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['candidates'] == null || (responseBody['candidates'] as List).isEmpty) {
          return {
            'status': 'pending',
            'comments': 'AI verification failed: Model did not return a response. Sent for faculty review.',
            'is_category_match': false,
            'is_name_match': false,
          };
        }

        final content = responseBody['candidates'][0]['content']['parts'][0]['text'];

        try {
          final decodedJson = jsonDecode(content) as Map<String, dynamic>;

          if (decodedJson.containsKey('status') && decodedJson.containsKey('comments')) {
            return decodedJson;
          } else {
            throw Exception('AI response is missing required fields, even with schema.');
          }
        } catch (e) {
          return {
            'status': 'pending',
            'comments': 'AI verification failed: Could not parse model JSON response. Sent for faculty review. Error: $e',
            'is_category_match': false,
            'is_name_match': false,
          };
        }
      } else {
        return {
          'status': 'pending',
          'comments': 'AI verification service failed with status ${response.statusCode}. Sent for faculty review. Body: ${response.body}',
          'is_category_match': false,
          'is_name_match': false,
        };
      }
    } catch (e) {
      return {
        'status': 'pending',
        'comments': 'An error occurred during AI verification: $e. Sent for faculty review.',
        'is_category_match': false,
        'is_name_match': false,
      };
    }
  }

  Future<String> generateChatResponse(String userMessage) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey');

    final prompt = 'You are a helpful university assistant. Respond to the following user message: $userMessage';

    final requestBody = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ],
      "generationConfig": {
        "temperature": 0.7,
        "maxOutputTokens": 2048,
      }
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['candidates'] != null && (responseBody['candidates'] as List).isNotEmpty) {
          final content = responseBody['candidates'][0]['content']['parts'][0]['text'];
          return content;
        } else {
          return 'Error: The model did not return a response.';
        }
      } else {
        return 'Error: AI service failed with status ${response.statusCode}.\n${response.body}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }
}
