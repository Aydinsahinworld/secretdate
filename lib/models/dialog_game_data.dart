import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/content_item.dart';
import 'dart:math';

class DialogQuestion {
  final String question;
  final Map<String, String> choices;
  final String correctAnswer;
  final String? hint;

  DialogQuestion({
    required this.question,
    required this.choices,
    required this.correctAnswer,
    this.hint,
  });

  factory DialogQuestion.fromJson(Map<String, dynamic> json) {
    // Null kontrolü yaparak güvenli bir şekilde dönüştür
    Map<String, String> choicesMap = {};
    
    if (json['choices'] != null) {
      if (json['choices'] is Map) {
        // Map'i String, String formatına dönüştür
        (json['choices'] as Map).forEach((key, value) {
          choicesMap[key.toString()] = value.toString();
        });
      }
    }
    
    if (choicesMap.isEmpty) {
      choicesMap = {'A': 'Seçenek bulunamadı'};
    }
    
    return DialogQuestion(
      question: json['question']?.toString() ?? 'Soru bulunamadı',
      choices: choicesMap,
      correctAnswer: json['correct_answer']?.toString() ?? json['correctAnswer']?.toString() ?? 'A',
      hint: json['hint']?.toString(),
    );
  }
}

class DialogGameData {
  // Belirli bir klasördeki tüm JSON dosyalarını listeleyen yardımcı metod
  static Future<List<String>> _listJsonFiles(String basePath) async {
    try {
      // AssetManifest.json'u kullanarak tüm varlıkları listele
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Belirtilen klasördeki tüm JSON dosyalarını filtrele
      final jsonFiles = manifestMap.keys
          .where((String key) => 
              key.startsWith(basePath) && 
              key.endsWith('.json') &&
              key.contains('level_'))
          .toList();
      
      if (jsonFiles.isEmpty) {
        print('Uyarı: $basePath klasöründe hiç JSON dosyası bulunamadı.');
        
        // Sabit bir dosya listesi oluştur (level_001.json'dan level_009.json'a kadar)
        List<String> defaultFiles = [];
        for (int i = 1; i <= 9; i++) {
          final fileName = '$basePath/level_${i.toString().padLeft(3, '0')}.json';
          defaultFiles.add(fileName);
        }
        
        // Dosyaların varlığını kontrol et
        List<String> existingFiles = [];
        for (String file in defaultFiles) {
          try {
            await rootBundle.loadString(file);
            existingFiles.add(file);
          } catch (e) {
            // Dosya bulunamadı, atla
          }
        }
        
        print('Varsayılan dosyalardan bulunanlar: $existingFiles');
        return existingFiles;
      }
      
      print('Bulunan JSON dosyaları: $jsonFiles'); // Debug için
      return jsonFiles;
    } catch (e) {
      print('JSON dosyaları listelenirken hata: $e');
      
      // Hata durumunda, sadece level_001.json'u döndür
      final defaultFile = '$basePath/level_001.json';
      return [defaultFile];
    }
  }
  
  // Rastgele bir JSON dosyası seçen metod
  static Future<String> _selectRandomJsonFile(String gender, String category) async {
    final basePath = 'assets/data/dialog_games/$gender/$category';
    final jsonFiles = await _listJsonFiles(basePath);
    
    if (jsonFiles.isEmpty) {
      throw Exception('Hiç JSON dosyası bulunamadı: $basePath');
    }
    
    // Rastgele bir dosya seç
    final random = Random();
    final randomFile = jsonFiles[random.nextInt(jsonFiles.length)];
    
    print('Seçilen rastgele JSON dosyası: $randomFile'); // Debug için
    return randomFile;
  }

  static Future<List<DialogQuestion>> loadQuestions({
    required ContentType type,
    required bool isMale,
    required int level,
  }) async {
    try {
      // Cinsiyet ve kategori bilgilerini belirle
      final gender = isMale ? 'male' : 'female';
      
      // Kategori adını belirle
      String category;
      if (type == ContentType.karakter) {
        category = 'character';
      } else {
        category = type.toString().split('.').last.toLowerCase();
      }
      
      // Bölüm numarasına göre JSON dosyasını seç
      String path;
      
      // Eğer bölüm numarası 1, 4, 7 ise (her satırın ilk bölümü)
      // rastgele bir JSON dosyası seç
      if (level % 3 == 1) {
        try {
          path = await _selectRandomJsonFile(gender, category);
        } catch (e) {
          print('Rastgele JSON dosyası seçilirken hata: $e');
          // Hata durumunda varsayılan dosyayı kullan
          path = 'assets/data/dialog_games/$gender/$category/level_001.json';
        }
      } else {
        // Diğer bölümler için sabit JSON dosyası kullan
        final fileName = 'level_${level.toString().padLeft(3, '0')}.json';
        path = 'assets/data/dialog_games/$gender/$category/$fileName';
      }

      print('JSON dosya yolu: $path'); // Debug için

      // JSON dosyasını oku
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(path);
      } catch (e) {
        print('JSON dosyası okunamadı: $e');
        // Varsayılan dosyayı dene
        path = 'assets/data/dialog_games/$gender/$category/level_001.json';
        jsonString = await rootBundle.loadString(path);
      }
      
      final dynamic jsonData = json.decode(jsonString);
      
      // JSON formatını kontrol et ve uyarla
      List<dynamic> jsonList;
      if (jsonData is List) {
        // Doğrudan liste formatı
        jsonList = jsonData;
      } else if (jsonData is Map && jsonData.containsKey('questions')) {
        // Sorular bir alt anahtar içinde
        jsonList = jsonData['questions'];
      } else {
        // Tek bir soru objesi
        jsonList = [jsonData];
      }
      
      print('JSON formatı: ${jsonList.length} soru bulundu'); // Debug için

      // JSON'ı DialogQuestion listesine dönüştür
      return jsonList.map((json) => DialogQuestion.fromJson(json)).toList();
    } catch (e) {
      print('Dialog soruları yüklenirken hata: $e');
      
      // Son çare olarak sabit bir soru listesi döndür
      return [
        DialogQuestion(
          question: 'Oyun verisi yüklenemedi. Lütfen daha sonra tekrar deneyin.',
          choices: {'A': 'Tamam'},
          correctAnswer: 'A',
          hint: 'Teknik bir sorun oluştu.',
        )
      ];
    }
  }
} 