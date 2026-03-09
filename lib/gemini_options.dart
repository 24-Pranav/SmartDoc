import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiOptions {
  // Get the API key from the .env file
  // Make sure you have a .env file at the root of your project with the following content:
  // GEMINI_API_KEY="YOUR_API_KEY"
  static final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? 'API_KEY_NOT_FOUND';
}
