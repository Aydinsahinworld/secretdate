import 'package:flutter/material.dart';

// Oyun türlerini tanımlayan enum
enum GameType {
  dialog,    // Diyalog oyunu
  matching,  // Eşleştirme oyunu
  // Diğer oyun türleri buraya eklenecek
}

// Tüm oyunlar için temel arayüz
abstract class GameInterface {
  // Oyunu başlatma
  Future<void> initialize();
  
  // Oyun mantığını güncelleme
  void update();
  
  // Oyun arayüzünü oluşturma
  Widget buildGame(BuildContext context);
  
  // İlerleme durumunu alma (0.0 - 1.0 arası)
  double getProgress();
  
  // Oyunun bitip bitmediğini kontrol etme
  bool isGameComplete();
  
  // Oyunu temizleme/sıfırlama
  void dispose();
  
  // Kalan can sayısını alma
  int getRemainingHearts();
} 