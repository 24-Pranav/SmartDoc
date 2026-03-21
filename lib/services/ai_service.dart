
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AIService {
  final String apiKey;

  AIService({required this.apiKey});

  Future<Map<String, dynamic>> verifyDocument(
      String text, String category, String userName) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    final prompt = '''
You are an intelligent document verification system for a university.
Analyze the extracted OCR text from the student's document and determine if it should be approved or rejected.
- Student Name: "$userName"
- Document Category: "$category"
- Extracted Text: """$text"""

Based on your analysis, provide the following information in JSON format:
- status: "approved", "rejected", or "pending".
- comments: Your detailed explanation for the decision. Base the status on whether the content clearly matches the category and includes the student's name.
''';

    final requestBody = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ],
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 2048,
        "responseMimeType": "application/json",
      },
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
        {
          "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold": "BLOCK_NONE"
        },
        {
          "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
          "threshold": "BLOCK_NONE"
        }
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

        if (responseBody['candidates'] == null ||
            (responseBody['candidates'] as List).isEmpty) {
          return {
            'status': 'pending',
            'comments':
                'AI verification failed: Model did not return a response. Sent for faculty review.',
          };
        }

        final content =
            responseBody['candidates'][0]['content']['parts'][0]['text'];
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        return {
          'status': 'pending',
          'comments':
              'AI verification service failed with status ${response.statusCode}. Sent for faculty review. Body: ${response.body}',
        };
      }
    } catch (e) {
      return {
        'status': 'pending',
        'comments':
            'An error occurred during AI verification: $e. Sent for faculty review.',
      };
    }
  }

  Future<String> generateChatResponse(String userMessage) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return "You must be logged in to use the chat assistant.";
    }

    final documentsSnapshot = await FirebaseFirestore.instance
        .collection('documents')
        .where('studentId', isEqualTo: user.uid)
        .get();

    final documents = documentsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'category': data['category'],
        'status': data['status'],
        'ai_comment': data['ai_comment'] ?? 'No comments available.'
      };
    }).toList();

    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

    final prompt = '''
You are a specialized University Assistant AI for the "Smart Doc" mobile app. Your primary function is to help students with questions about their document submissions.

**Your Persona:**
- You are helpful, concise, and knowledgeable about the app's features.
- You must always answer based *only* on the information provided to you about the student's documents.
- Do not provide generic advice or information from outside the app's context.
- If a student asks how to check their status, tell them to go to the "Home" or "My Documents" screen.

**Student's Document Information (in JSON format):**
${jsonEncode(documents)}

**User's Question:**
"$userMessage"

**Your Task:**
Based on the provided document list, answer the user's question accurately.
- If the user asks about a specific document, use the information from the list to tell them the status and any comments.
- If the user asks a general question (like "Why was my document rejected?"), you can use the data to see which documents are rejected and provide the associated `ai_comment`.
- If the document list is empty, inform the user that they have not uploaded any documents yet.
''';

    final requestBody = jsonEncode({
      "contents": [
        {"parts": [{"text": prompt}]}
      ],
      "generationConfig": {
        "temperature": 0.5,
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
        if (responseBody['candidates'] != null &&
            (responseBody['candidates'] as List).isNotEmpty) {
          final content =
              responseBody['candidates'][0]['content']['parts'][0]['text'];
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
