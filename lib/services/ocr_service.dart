import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  Future<String> processPdf(File file) async {
    //Load an existing PDF document.
    final PdfDocument document =
    PdfDocument(inputBytes: await file.readAsBytes());

    //Create a new instance of the PdfTextExtractor.
    final PdfTextExtractor extractor = PdfTextExtractor(document);

    //Extract all the text from the document.
    final String text = extractor.extractText();

    // WRONG LINE REMOVED: No dispose method on the extractor.

    //Release the resources used by the PDF document.
    document.dispose();

    return text;
  }
}
