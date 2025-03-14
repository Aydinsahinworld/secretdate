import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/game_interface.dart';
import '../models/content_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

// GameInterface için mixin
mixin GameInterfaceMixin on StatefulWidget {
  Future<void> initialize() async {
    // Oyun başlatma işlemleri
    print('Oyun başlatılıyor...');
  }
  
  void update() {
    // Oyun mantığını güncelleme
  }
  
  Widget buildGame(BuildContext context) {
    // Varsayılan olarak widget'ın kendisini döndür
    return this;
  }
  
  double getProgress() {
    // İlerleme durumunu alma (0.0 - 1.0 arası)
    return 0.0;
  }
  
  bool isGameComplete() {
    // Oyunun bitip bitmediğini kontrol etme
    return false;
  }
  
  void disposeGame() {
    // Oyunu temizleme/sıfırlama
  }
  
  int getRemainingHearts() {
    // Kalan can sayısını alma
    return 5;
  }
}

class ImageRevealGame extends StatefulWidget with GameInterfaceMixin implements GameInterface {
  final ContentItem item;
  final Function(double) onBlurLevelChanged;
  final Function(bool) onGameComplete;
  final bool isMale;

  const ImageRevealGame({
    Key? key,
    required this.item,
    required this.onBlurLevelChanged,
    required this.onGameComplete,
    required this.isMale,
  }) : super(key: key);

  @override
  State<ImageRevealGame> createState() => _ImageRevealGameState();
  
  @override
  Future<void> initialize() async {
    print('Resim açma oyunu başlatılıyor...');
  }
  
  @override
  void disposeGame() {
    // GameInterface'in disposeGame metodu
    // Oyunla ilgili kaynakları temizle
  }
}

class _ImageRevealGameState extends State<ImageRevealGame> with TickerProviderStateMixin {
  // Oyun alanı boyutları
  late double width;
  late double height;
  
  // Resim ile ilgili değişkenler
  ui.Image? originalImage;
  ui.Image? blurredImage;
  bool imagesLoaded = false;
  
  // Çizim ile ilgili değişkenler
  List<Offset> currentLine = [];
  List<Path> revealedAreas = [];
  double revealedPercentage = 0.0;
  
  // Engeller
  List<Obstacle> obstacles = [];
  
  // Oyun durumu
  bool isDrawing = false;
  bool gameOver = false;
  bool gameWon = false;
  int remainingTime = 60; // 60 saniye
  late Timer gameTimer;

  @override
  void initState() {
    super.initState();
    
    // Oyun zamanlayıcısını başlat
    gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingTime > 0) {
            remainingTime--;
          } else {
            gameOver = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Şimdilik basit bir mesaj göster
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 100, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'Resim Açma Oyunu',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Bu oyun türü yakında eklenecek!',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              // Test amaçlı olarak oyunu kazandı olarak işaretle
              widget.onGameComplete(true);
              Navigator.pop(context);
            },
            child: Text('Oyunu Tamamla (Test)'),
          ),
        ],
      ),
    );
  }
}

// Engel sınıfı
class Obstacle {
  Offset position;
  Offset velocity;
  double radius;
  
  Obstacle({
    required this.position,
    required this.velocity,
    required this.radius,
  });
} 