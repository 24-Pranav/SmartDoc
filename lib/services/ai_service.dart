import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String apiKey;

  AIService({required this.apiKey});

  Future<Map<String, dynamic>> verifyDocument(String text, String category, String userName) async {
    // DEFINITIVE FIX: This combines the correct v1beta endpoint with a compatible model and a valid request body.
    // This resolves all previous 'model not found' and 'invalid payload' errors.
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey');

    final prompt = '''
You are an intelligent document verification system for a university. Your task is to analyze the extracted OCR text from a student's document and determine if it should be approved or rejected.

**Student Information:**
- Name: "$userName"

**Document to Verify:**
- Provided Category: "$category"
- Extracted Text: """$text"""

**Your Task:**
Analyze the document and return ONLY a valid JSON object with your findings. The JSON object must have the following structure and nothing else:
{
  "is_category_match": boolean,
  "is_name_match": boolean,
  "status": "approved" | "rejected",
  "comments": "Your detailed explanation for the decision. Mention what matched and what didn't."
}
''';

    final requestBody = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 2048,
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
        final content = responseBody['candidates'][0]['content']['parts'][0]['text'];
        final cleanedContent = content.replaceAll('```json\n', '').replaceAll('\n```', '');
        return jsonDecode(cleanedContent) as Map<String, dynamic>;
      } else {
        throw Exception('AI service failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('An error occurred during AI verification: $e');
    }
  }
}
