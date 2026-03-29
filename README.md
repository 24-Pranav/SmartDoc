# SmartDoc - Intelligent University Document Verification

SmartDoc is a Flutter-based cross-platform mobile application designed to streamline the document submission and verification process for educational institutions. It provides a secure, role-based platform for Students, Faculty, and Administrators to manage and process academic documents efficiently. 

By leveraging **Google's Gemini AI** and **Google ML Kit OCR**, SmartDoc automates the initial verification of uploaded documents, saving faculty time and providing immediate feedback to students.

## Key Features

### Role-Based Access Control
The application supports three distinct user roles, each with tailored interfaces and capabilities:
- **Student**: Can upload documents, track verification status in real-time, view notifications, and interact with a smart AI chatbot for assistance.
- **Faculty**: Responsible for reviewing documents (especially those flagged or pending by AI), approving/rejecting submissions, and sending targeted notifications to students.
- **Admin**: Manages the overall system, configures document categories, monitors user metrics, and verifies pending faculty registrations.

### AI-Powered Document Verification
- **OCR Integration**: Extracts text from uploaded images and PDFs using `google_mlkit_text_recognition` and `syncfusion_flutter_pdf`.
- **Gemini AI Analysis**: Automatically analyzes the extracted text to verify if it matches the required document category and belongs to the submitted student, automatically marking clear matches as "approved" or "rejected", and ambiguous cases as "pending" for manual faculty review.
- **AI Chat Assistant**: A contextual Gemini-powered chatbot allows students to ask natural language questions about their document status.

## Technologies Used
- **Frontend Engine**: Flutter (Dart)
- **Backend & Database**: Firebase (Authentication, Firestore, Storage, Cloud Messaging) and Supabase
- **State Management**: Provider
- **Artificial Intelligence**: Gemini API (Flash 2.5), Google ML Kit (Text Recognition, Document Scanner)
- **UI & UX**: Curved Navigation Bar, Lottie animations, Syncfusion PDF Viewer

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Firebase Project setup with Authentication, Firestore, and Storage enabled.
- Gemini API Key.
- Supabase Project setup.

### Installation

1. Clone the repository:
   ```bash
   git clone <repository_url>
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up environment variables:
   Create a `.env` file in the root directory and add your API keys.
4. Run the application:
   ```bash
   flutter run
   ```
