import 'dart:convert';
import 'package:flutter/services.dart';
import 'content_item.dart';

class DialogQuestion {
  final String character;
  final int difficultyLevel;
  final String hint;
  final String question;
  final Map<String, String> choices;
  final String correctAnswer;

  DialogQuestion({
    required this.character,
    required this.difficultyLevel,
    required this.hint,
    required this.question,
    required this.choices,
    required this.correctAnswer,
  });

  factory DialogQuestion.fromJson(Map<String, dynamic> json) {
    return DialogQuestion(
      character: json['character'] as String,
      difficultyLevel: json['difficulty_level'] as int,
      hint: json['hint'] as String,
      question: json['question'] as String,
      choices: Map<String, String>.from(json['choices'] as Map),
      correctAnswer: json['correct_answer'] as String,
    );
  }
}

class DialogGameData {
  static Future<List<DialogQuestion>> loadQuestions({
    required ContentType type,
    required bool isMale,
    required int level,
  }) async {
    try {
      // JSON dosya yolunu oluştur
      final gender = isMale ? 'male' : 'female';
      
      // Kategori adını belirle
      String category;
      if (type == ContentType.karakter) {
        category = 'character';
      } else {
        category = type.toString().split('.').last.toLowerCase();
      }
      
      // Level doğrudan zorluk seviyesini temsil eder (1-9 arası)
      final fileName = 'level_${level.toString().padLeft(3, '0')}.json';
      final path = 'assets/data/dialog_games/$gender/$category/$fileName';

      print('JSON dosya yolu: $path'); // Debug için

      // JSON dosyasını oku
      final jsonString = await rootBundle.loadString(path);
      final List<dynamic> jsonList = json.decode(jsonString);

      // JSON'ı DialogQuestion listesine dönüştür
      return jsonList.map((json) => DialogQuestion.fromJson(json)).toList();
    } catch (e) {
      print('Dialog soruları yüklenirken hata: $e');
      rethrow; // Hatayı yukarı fırlat
    }
  }
} 