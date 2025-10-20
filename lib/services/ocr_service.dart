
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> processImage(File imageFile) async {
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  bool isDocumentExpired(String text) {
    final List<DateTime> dates = _extractDates(text);
    final DateTime now = DateTime.now();

    for (final date in dates) {
      if (date.isBefore(now)) {
        return true; // Found an expired date
      }
    }
    return false; // No expired dates found
  }

  List<DateTime> _extractDates(String text) {
    final List<DateTime> dates = [];
    final RegExp datePattern = RegExp(r'\b(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b');
    final Iterable<RegExpMatch> matches = datePattern.allMatches(text);

    for (final match in matches) {
      final String dateString = match.group(0)!;
      try {
        final DateTime? date = _parseDate(dateString);
        if (date != null) {
          dates.add(date);
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }
    return dates;
  }

  DateTime? _parseDate(String dateString) {
    final List<String> formats = [
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'yyyy-MM-dd',
      'dd/MM/yy',
      'MM/dd/yy',
    ];

    for (final format in formats) {
      try {
        return DateFormat(format).parseStrict(dateString);
      } catch (e) {
        // Try the next format
      }
    }
    return null;
  }
}
