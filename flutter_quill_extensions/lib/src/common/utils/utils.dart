import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show Uint8List, immutable;
import 'package:http/http.dart' as http;

import 'patterns.dart';

bool isBase64(String str) {
  return base64RegExp.hasMatch(str);
}

bool isHttpBasedUrl(String url) {
  try {
    final uri = Uri.parse(url.trim());
    return uri.isScheme('HTTP') || uri.isScheme('HTTPS');
  } catch (_) {
    return false;
  }
}

bool isImageBase64(String imageUrl) {
  return !isHttpBasedUrl(imageUrl) && isBase64(imageUrl);
}

bool isYouTubeUrl(String videoUrl) {
  try {
    final uri = Uri.parse(videoUrl);
    return uri.host == 'www.youtube.com' ||
        uri.host == 'youtube.com' ||
        uri.host == 'youtu.be' ||
        uri.host == 'www.youtu.be';
  } catch (_) {
    return false;
  }
}

enum SaveImageResultMethod { network, localStorage }

@immutable
class SaveImageResult {
  const SaveImageResult({required this.error, required this.method});

  final String? error;
  final SaveImageResultMethod method;
}

Future<Uint8List?> convertImageToUint8List(String image) async {
  if (isHttpBasedUrl(image)) {
    final response = await http.get(Uri.parse(image));
    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    }
    return null;
  }
  // TODO: Add support for all image providers like AssetImage
  try {
    final file = XFile(image);
    return await file.readAsBytes();
  } catch (e) {
    return null;
  }
}
