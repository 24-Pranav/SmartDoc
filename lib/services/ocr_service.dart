import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart'; // For initial text extraction
import 'package:path_provider/path_provider.dart'; // To get a temporary directory
import 'package:pdfx/pdfx.dart' as pdfx; // To convert PDF pages to images

// IMPORTANT: You must add the following packages to your pubspec.yaml file:
//   pdfx: ^2.5.0
//   path_provider: ^2.0.11

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText =
    await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  // REVISED: Now handles both text-based and scanned (image) PDFs.
  Future<String> processPdf(File file) async {
    // 1. Try to extract text directly using Syncfusion for text-based PDFs.
    String text;
    try {
      final PdfDocument document =
      PdfDocument(inputBytes: await file.readAsBytes());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      text = extractor.extractText();
      document.dispose();
    } catch (e) {
      text = ''; // If it fails, treat as empty and proceed to OCR.
      print("Syncfusion text extraction failed: $e");
    }


    // 2. If text is empty (or very short), it's likely a scanned PDF. Process it as an image using pdfx.
    if (text.trim().length < 50) {
      print("No significant text found, attempting OCR on PDF image.");
      try {
        // Open the PDF document using the pdfx package
        final pdfx.PdfDocument pdfxDoc = await pdfx.PdfDocument.openFile(file.path);
        // Get the first page
        final page = await pdfxDoc.getPage(1);
        // Render the page as a high-resolution image for better OCR results
        final pageImage = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: pdfx.PdfPageImageFormat.jpeg); // Render as JPEG
        await page.close();
        await pdfxDoc.close();

        if (pageImage != null) {
          // Get a temporary directory to save the image file
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/temp_pdf_page.jpg');
          await tempFile.writeAsBytes(pageImage.bytes);

          // Use the existing image processing method to perform OCR on the new image
          text = await processImage(tempFile);

          // Clean up the temporary file
          await tempFile.delete();
        } else {
          throw Exception("Failed to render PDF page into an image.");
        }
      } catch (e) {
        // If processing the PDF as an image fails, we'll proceed with the empty `text` string.
        // The AI will then correctly reject the document, which is the expected behavior for a corrupt/unreadable file.
        print("Error processing scanned PDF with pdfx: $e");
      }
    }

    return text;
  }
}
