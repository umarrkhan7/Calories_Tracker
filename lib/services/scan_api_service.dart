import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/api_config.dart';

/// Result of a single fruit-scan prediction (single-fruit mode).
class ScanResult {
  final String label;
  final double confidence;

  ScanResult({required this.label, required this.confidence});

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// One detected fruit within a multi-fruit scan.
class Detection {
  final String label;
  final double confidence;

  Detection({required this.label, required this.confidence});

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

/// Result of a multi-fruit scan — zero or more detected fruits.
class MultiScanResult {
  final List<Detection> detections;

  MultiScanResult({required this.detections});

  factory MultiScanResult.fromJson(Map<String, dynamic> json) {
    final list = (json['detections'] as List)
        .map((d) => Detection.fromJson(d as Map<String, dynamic>))
        .toList();
    return MultiScanResult(detections: list);
  }
}

class ScanApiService {
  /// Single-fruit mode — sends [imageFile] and returns one label +
  /// confidence for the whole image.
  static Future<ScanResult> predict(File imageFile) async {
    try {
      final response = await _sendImage(imageFile, ApiConfig.predictEndpoint);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ScanResult.fromJson(data);
    } on SocketException {
      throw _unreachableError();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Multi-fruit mode — sends [imageFile] to the YOLO+MobileNetV3
  /// pipeline and returns every fruit detected in the image.
  static Future<MultiScanResult> predictMulti(File imageFile) async {
    try {
      final response = await _sendImage(imageFile, ApiConfig.predictMultiEndpoint);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MultiScanResult.fromJson(data);
    } on SocketException {
      throw _unreachableError();
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<http.Response> _sendImage(File imageFile, String endpoint) async {
    final uri = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', uri);

    // Needed because api_server.py explicitly checks the content-type
    // of the upload — without this, some image_picker temp files get
    // sent as application/octet-stream and get rejected.
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 90));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Server error (${response.statusCode}): ${response.body}');
    }

    return response;
  }

  static Exception _unreachableError() {
    return Exception(
      '❌ Cannot reach server!\nMake sure the Colab notebook is running '
          'and the URL in ApiConfig is correct.',
    );
  }
}