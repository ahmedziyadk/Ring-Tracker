import '../models/shared_order_draft.dart';

class SharedOrderParser {
  static SharedOrderDraft parse(String text, {List<String> imagePaths = const []}) {
    final cleanedText = text.trim();

    return SharedOrderDraft(
      customerName: _valueFor(cleanedText, 'NAME'),
      phoneNumber: _digitsOnly(_valueFor(cleanedText, 'PHONE')),
      stoneType: _valueFor(cleanedText, 'STONE'),
      makingType: _normalizeMakingType(_valueFor(cleanedText, 'TYPE')),
      ringSize: _valueFor(cleanedText, 'SIZE'),
      totalAmount: _numberOnly(_valueFor(cleanedText, 'TOTAL')),
      advanceAmount: _numberOnly(_valueFor(cleanedText, 'ADVANCE')),
      urgent: _isYes(_valueFor(cleanedText, 'URGENT')),
      note: _valueFor(cleanedText, 'NOTE'),
      imagePaths: imagePaths,
      rawText: cleanedText,
    );
  }

  static String _valueFor(String text, String label) {
    final pattern = RegExp(
      '^\\s*$label\\s*:\\s*(.*?)(?=\\n\\s*[A-Z ]+\\s*:|\\r?\\n?\\s*\\z)',
      caseSensitive: false,
      multiLine: true,
      dotAll: true,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  static String _numberOnly(String value) {
    final match = RegExp(r'\d+(?:\.\d+)?').firstMatch(value.replaceAll(',', ''));
    return match?.group(0) ?? '';
  }

  static bool _isYes(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'yes' ||
        normalized == 'y' ||
        normalized == 'true' ||
        normalized == 'urgent' ||
        normalized == '1';
  }

  static String _normalizeMakingType(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'bracelet':
        return 'Bracelet';
      case 'pendant':
        return 'Pendant';
      case 'necklace':
        return 'Necklace';
      case 'earring':
      case 'earrings':
        return 'Earring';
      case 'ring':
      default:
        return 'Ring';
    }
  }
}
