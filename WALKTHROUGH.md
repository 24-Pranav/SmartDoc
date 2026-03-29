# SmartDoc - User Flow Walkthrough

This document outlines the user journeys for the three primary roles in the SmartDoc system: Student, Faculty, and Administrator.

## 1. Initial Launch
Upon launching the application, users are greeted with a `SplashScreen` and then navigated to the `RoleSelectionScreen`. Here, they must choose their identity: Student, Faculty, or Admin. This selection dictates the login flow and subsequent dashboard.

---

## 2. Student Walkthrough
**Goal:** Upload documents, track their status, and communicate with the system.

1. **Authentication:** 
   - New students navigate to the `RegistrationScreen` to create an account.
   - Returning students log in via the `LoginScreen`.
2. **Dashboard (`StudentDashboardScreen`):**
   - Incorporates a bottom navigation bar (`curved_navigation_bar`) to navigate between tabs.
3. **Home Tab:** View a summary of uploaded documents and their current statuses (Approved, Pending, Rejected).
4. **Upload Tab:**
   - Students can pick images or PDFs using `image_picker` / `file_picker` or scan physical documents using `google_mlkit_document_scanner`.
   - After selecting a category and file, the app runs OCR on the document and sends the text to the Gemini AI API for preliminary verification.
5. **Chat Tab:**
   - Interacts with a specialized Gemini-powered assistant. The assistant is contextualized with the student's document history from Firestore and can answer questions like "Why was my ID rejected?".
6. **Notifications Tab:** View push notifications received via Firebase Cloud Messaging (FCM).

---

## 3. Faculty Walkthrough
**Goal:** Review AI-flagged documents and manage student submissions.

1. **Authentication:** 
   - Faculty members register via `FacultyRegistrationScreen`. They are placed in a 'pending' state and cannot access the app until verified by an Admin.
   - Once verified, they log in via `LoginScreen`.
2. **Dashboard (`FacultyDashboardScreen`):**
   - Navigation bar allows switching between Home, Verification, Notifications, and Profile.
3. **Verification Tab:** 
   - Displays a list of student documents that require manual review (usually documents the AI marked as 'pending' or 'rejected').
   - Faculty can view the full document and either Approve or Reject it, overriding or confirming the AI's decision.
4. **Notifications:** Faculty can use `SendNotificationScreen` to broadcast or specifically target students regarding missing or incorrect documents.

---

## 4. Admin Walkthrough
**Goal:** Supervise the system, manage users, and specify document requirements.

1. **Authentication:** Uses secure credentials to log in.
2. **Dashboard (`AdminDashboardScreen`):** A customized panel with tabs for Home, Users, Verification, and Categories.
3. **Faculty Verification Tab:** Reviews new faculty registrations and approves them to access the system.
4. **Categories Tab:** Defines which types of documents students are required to upload (e.g., "Aadhar Card", "10th Marksheet").
5. **User Management:** Views lists of all registered students and faculty, with the ability to delete or manage accounts.

---

## Summary of App Flow
**User logs in -> AI does initial heavy lifting -> Faculty manual review for edge cases -> Student tracks progress real-time.**
