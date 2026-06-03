// lib/logic/chat/plant_disease_classifier.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DiseaseResult {
  final String label;       // VD: "Potato___Early_blight"
  final String displayName; // VD: "Khoai tây - Bệnh đốm vòng sớm"
  final double confidence;  // VD: 0.94

  DiseaseResult({
    required this.label,
    required this.displayName,
    required this.confidence,
  });
}

class PlantDiseaseClassifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoaded = false;

  // ── Khởi tạo model ────────────────────────────────────────

  Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      _interpreter = await Interpreter.fromAsset('assets/plant_disease.tflite');
      _labels = await _loadLabels();
      _isLoaded = true;
    } catch (e) {
      throw Exception('Không thể tải model TFLite: $e');
    }
  }

  Future<List<String>> _loadLabels() async {
    final data = await rootBundle.loadString('assets/labels.txt');
    return data
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  // ── Phân tích ảnh ─────────────────────────────────────────

  Future<DiseaseResult> classify(String imagePath) async {
    if (!_isLoaded) await loadModel();

    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('Không thể đọc ảnh');

    final resized = img.copyResize(image, width: 224, height: 224);

    final input = List.generate(
      1,
          (_) => List.generate(
        224,
            (y) => List.generate(
          224,
              (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    final output = List.generate(
      1,
          (_) => List.filled(_labels.length, 0.0),
    );

    _interpreter!.run(input, output);

    final scores = output[0];
    double maxScore = 0;
    int maxIndex = 0;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    final label = maxIndex < _labels.length ? _labels[maxIndex] : 'Unknown';

    return DiseaseResult(
      label: label,
      displayName: _translateLabel(label),
      confidence: maxScore,
    );
  }

  // ── Dịch nhãn sang tiếng Việt ────────────────────────────
  // Bảng dịch đầy đủ toàn bộ dataset PlantVillage (38 lớp)
  // Khi thêm cây mới, chỉ cần thêm nhãn mới vào đây

  String _translateLabel(String label) {
    const translations = {
      // ── Táo (Apple) ──────────────────────────────────────
      'Apple___Apple_scab':               'Táo - Bệnh ghẻ táo',
      'Apple___Black_rot':                'Táo - Bệnh thối đen',
      'Apple___Cedar_apple_rust':         'Táo - Bệnh gỉ sắt',
      'Apple___healthy':                  'Táo - Lá khỏe mạnh',

      // ── Việt quất (Blueberry) ─────────────────────────────
      'Blueberry___healthy':              'Việt quất - Lá khỏe mạnh',

      // ── Anh đào (Cherry) ─────────────────────────────────
      'Cherry_(including_sour)___Powdery_mildew': 'Anh đào - Bệnh phấn trắng',
      'Cherry_(including_sour)___healthy':         'Anh đào - Lá khỏe mạnh',

      // ── Ngô (Corn/Maize) ─────────────────────────────────
      'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': 'Ngô - Bệnh đốm lá xám',
      'Corn_(maize)___Common_rust_':      'Ngô - Bệnh gỉ sắt thông thường',
      'Corn_(maize)___Northern_Leaf_Blight': 'Ngô - Bệnh đốm lá phía Bắc',
      'Corn_(maize)___healthy':           'Ngô - Lá khỏe mạnh',

      // ── Nho (Grape) ──────────────────────────────────────
      'Grape___Black_rot':                'Nho - Bệnh thối đen',
      'Grape___Esca_(Black_Measles)':     'Nho - Bệnh Esca (sởi đen)',
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': 'Nho - Bệnh cháy lá',
      'Grape___healthy':                  'Nho - Lá khỏe mạnh',

      // ── Cam (Orange) ─────────────────────────────────────
      'Orange___Haunglongbing_(Citrus_greening)': 'Cam - Bệnh vàng lá greening (HLB)',

      // ── Đào (Peach) ──────────────────────────────────────
      'Peach___Bacterial_spot':           'Đào - Bệnh đốm vi khuẩn',
      'Peach___healthy':                  'Đào - Lá khỏe mạnh',

      // ── Ớt chuông (Pepper bell) ──────────────────────────
      'Pepper,_bell___Bacterial_spot':    'Ớt chuông - Bệnh đốm vi khuẩn',
      'Pepper,_bell___healthy':           'Ớt chuông - Lá khỏe mạnh',

      // ── Khoai tây (Potato) ───────────────────────────────
      'Potato___Early_blight':            'Khoai tây - Bệnh đốm vòng sớm',
      'Potato___Late_blight':             'Khoai tây - Bệnh mốc sương',
      'Potato___healthy':                 'Khoai tây - Lá khỏe mạnh',

      // ── Mâm xôi (Raspberry) ──────────────────────────────
      'Raspberry___healthy':              'Mâm xôi - Lá khỏe mạnh',

      // ── Đậu nành (Soybean) ───────────────────────────────
      'Soybean___healthy':                'Đậu nành - Lá khỏe mạnh',

      // ── Bí ngô (Squash) ──────────────────────────────────
      'Squash___Powdery_mildew':          'Bí ngô - Bệnh phấn trắng',

      // ── Dâu tây (Strawberry) ─────────────────────────────
      'Strawberry___Leaf_scorch':         'Dâu tây - Bệnh cháy lá',
      'Strawberry___healthy':             'Dâu tây - Lá khỏe mạnh',

      // ── Cà chua (Tomato) ─────────────────────────────────
      'Tomato___Bacterial_spot':          'Cà chua - Bệnh đốm vi khuẩn',
      'Tomato___Early_blight':            'Cà chua - Bệnh đốm vòng sớm',
      'Tomato___Late_blight':             'Cà chua - Bệnh mốc sương',
      'Tomato___Leaf_Mold':               'Cà chua - Bệnh mốc lá',
      'Tomato___Septoria_leaf_spot':      'Cà chua - Bệnh đốm lá Septoria',
      'Tomato___Spider_mites Two-spotted_spider_mite': 'Cà chua - Nhện đỏ hai đốm',
      'Tomato___Target_Spot':             'Cà chua - Bệnh đốm mục tiêu',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus': 'Cà chua - Virus xoăn vàng lá',
      'Tomato___Tomato_mosaic_virus':     'Cà chua - Virus khảm',
      'Tomato___healthy':                 'Cà chua - Lá khỏe mạnh',
    };

    // Nếu có trong bảng → trả về tiếng Việt
    if (translations.containsKey(label)) {
      return translations[label]!;
    }

    // Fallback: tự động chuyển đổi tên nhãn thành dạng dễ đọc
    // VD: "NewPlant___Some_disease" → "NewPlant - Some disease"
    return label
        .replaceAll('___', ' - ')
        .replaceAll('__', ' - ')
        .replaceAll('_', ' ')
        .replaceAll('(', '(')
        .trim();
  }

  void dispose() {
    _interpreter?.close();
    _isLoaded = false;
  }
}

// Singleton để không phải load model nhiều lần
final plantClassifier = PlantDiseaseClassifier();