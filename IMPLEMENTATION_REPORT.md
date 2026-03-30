# SmartDoc - Technical Implementation Report

This report explains the technical architecture, design patterns, and library implementations used to build the SmartDoc Flutter application.

## 1. Project Architecture

The project follows a standard feature-based / role-based directory structure inside the `lib/` directory:
- `screens/`: Contains the UI layers, partitioned by roles (`admin/`, `faculty/`, `student/`, `common/`).
- `services/`: Contains classes responsible for external network calls and third-party API integrations (`ai_service.dart`, `firebase_service.dart`, `ocr_service.dart`).
- `providers/`: Implements the `Provider` state management logic (`user_provider.dart`).
- `models/`: Contains data classes and enums (`role.dart`).
- `widgets/`: Reusable UI components.
- `utils/` & `extensions/`: Helper functions.

## 2. Tools & Technologies by Feature

| Feature | Technologies & Libraries Used | Implementation Details |
| :--- | :--- | :--- |
| **Authentication** | `firebase_auth`, `supabase_flutter` | Students and Faculty register via Firebase Email/Password Auth. The Firebase JWT token is synced with Supabase for unified session management (`_initializeSupabaseAuth` in `main.dart`). |
| **Database & Storage** | `cloud_firestore`, `supabase_flutter` | Firestore holds collections for `users`, `faculty`, `documents`, and `categories`. PDF/Image files are uploaded and securely stored in Supabase Storage (`documents` bucket). |
| **State Management** | `provider` | `UserProvider` wraps the app at the root level (`main.dart`), notifying descendant UI components of Auth changes and role shifts. |
| **OCR (Text Extraction)** | `google_mlkit_text_recognition`, `syncfusion_flutter_pdf`, `pdfx` | Handled by `OcrService`. For images, it uses ML Kit directly. For PDFs, it attempts text extraction via `syncfusion`. If text is missing (scanned document), it converts the PDF to an image via `pdfx` and runs ML Kit OCR on it. |
| **AI Verification** | `http`, Gemini API (Flash 2.5) | Implemented in `AIService`. Uses a prompt engineering approach. It passes OCR text, student name, and category to Gemini, expecting a JSON response (`{"status": "...", "comments": "..."}`) to automatically evaluate the document. |
| **AI Student Chatbot** | Gemini API | The `AIService` injects the student's document history (fetched from Firestore) into the system prompt window. The LLM then answers the student's specific queries using RAG (Retrieval-Augmented Generation) context. |
| **Document Scanning** | `google_mlkit_document_scanner` | Allows students to cleanly scan physical paper documents using their device camera, offering auto-crop functionality before uploading. |
| **Push Notifications** | `firebase_messaging` | FCM tokens are saved to the user's Firestore document. Handled via background and foreground listeners configured in `main.dart`. Let faculty ping students. |

## 3. Database Schema Overview (Firestore)

- **`users/`**: Stores base authentication details (email, role, name, fcmToken)
- **`faculty/`**: Stores specific faculty traits (department, verification status)
- **`documents/`**: Heart of the system. Stores metadata linking `studentId` -> `document_url` -> `category` -> `status` (approved/rejected/pending) -> `ai_comment`.
- **`categories/`**: Global rules defined by admins (e.g., max file size, required format).

## 4. Security
- **Firebase App Check**: Implemented with `ReCaptchaV3` for web/mobile protection against abuse.
- **Firestore Rules**: Secures document reads/writes so students can only see their own files, while faculty and admins have broader access.

## 5. Potential Improvements
- Move the Gemini API calls from the client-side (`AIService`) to a backend environment (like Firebase Cloud Functions) to prevent API key exposure in the `.env` file upon decompilation.
- Implement robust local caching (e.g., Hive or SQLite) for documents to reduce Firestore read costs.
