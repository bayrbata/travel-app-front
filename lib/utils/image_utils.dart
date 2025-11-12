import 'dart:convert';
import 'dart:typed_data';

class ImageUtils {
  /// Base64 string-ийг Uint8List болгон хөрвүүлнэ
  /// data:image/jpeg;base64, префикс байвал устгана
  static Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }

    try {
      // data:image/jpeg;base64, префикс байвал устгана
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',').last;
      }

      return base64Decode(base64Data);
    } catch (e) {
      print('Base64 decode алдаа: $e');
      return null;
    }
  }

  /// Base64 string зөв эсэхийг шалгана
  static bool isValidBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return false;
    }

    try {
      decodeBase64Image(base64String);
      return true;
    } catch (e) {
      return false;
    }
  }
}

