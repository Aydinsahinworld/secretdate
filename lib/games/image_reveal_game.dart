import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import '../models/game_interface.dart';
import '../models/content_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Yön enum'u
enum Direction { up, down, left, right, none }

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
  bool imagesLoaded = false;
  
  // Çizim ile ilgili değişkenler
  List<Rect> revealedAreas = []; // Dikdörtgen alanlar için değiştirildi
  double revealedPercentage = 0.0;
  double winThreshold = 50.0; // Kazanmak için gereken açılan alan yüzdesi
  bool gameOver = false;
  bool gameWon = false;
  int remainingTime = 60; // 60 saniye
  late Timer gameTimer;
  
  // Bulanıklık seviyesi
  double blurLevel = 5.0;
  
  // Kesici alet ile ilgili değişkenler
  Offset cutterPosition = Offset.zero;
  bool isCutterActive = false;
  Offset? cutStartPosition;
  final double cutterSize = 60.0; // Kesici aletin boyutunu 30.0'dan 60.0'a çıkarıyorum (2 kat büyütme)
  
  // Makas hareketi için değişkenler
  List<Offset> cutPath = []; // Kesim yolu
  Offset? lastGridPosition; // Son ızgara pozisyonu
  final double gridSize = 20.0; // Izgara boyutu
  Direction currentDirection = Direction.none; // Şu anki yön
  
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
            widget.onGameComplete(false); // Süre dolduğunda oyunu kaybetmiş sayılır
          }
        });
      }
    });
    
    // 100ms sonra makasın başlangıç konumunu ayarla
    // Bu gecikme, widget'ın boyutlarının hesaplanması için gerekli
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // Makası maskenin alt çizgisine konumlandır
          final maskPadding = 20.0;
          final maskBottom = height - maskPadding;
          cutterPosition = Offset(width / 2, maskBottom);
        });
      }
    });
  }

  @override
  void dispose() {
    gameTimer.cancel();
    super.dispose();
  }
  
  // Açılan alan yüzdesini hesapla
  void _calculateRevealedPercentage() {
    // Açılan alanların toplam yüzeyini hesapla
    
    if (revealedAreas.isEmpty) {
      revealedPercentage = 0.0;
      return;
    }
    
    // Her alan için yaklaşık bir değer hesapla
    double totalArea = 0;
    final gameAreaSize = width * height; // Oyun alanının gerçek boyutu
    
    for (var rect in revealedAreas) {
      // Her dikdörtgen için alan hesapla
      double rectArea = rect.width * rect.height;
      totalArea += rectArea;
    }
    
    // Toplam açılan alanın yüzdesini hesapla
    double percentage = (totalArea / gameAreaSize) * 100;
    
    // Yüzdeyi sınırla (maksimum 100)
    revealedPercentage = percentage.clamp(0.0, 100.0);
    
    // Debug için
    print('Açılan alan yüzdesi: $revealedPercentage');
    
    // Kazanma durumunu kontrol et
    if (revealedPercentage >= winThreshold && !gameWon) {
      gameWon = true;
      _showWinDialog();
    }
    
    // Bulanıklık seviyesini güncelle (5.0 maksimum bulanıklık)
    blurLevel = 5.0 * (1 - revealedPercentage / 100.0);
    widget.onBlurLevelChanged(blurLevel);
  }
  
  // Kesici aleti başlat
  void _startCutting(Offset position) {
    if (gameOver || gameWon) return;
    
    // Eğer tıklama makasın yakınındaysa, kesme işlemini başlat
    final distance = (position - cutterPosition).distance;
    
    // Pozisyonu oyun alanı sınırları içinde tut
    final clampedPos = Offset(
      position.dx.clamp(0.0, width),
      position.dy.clamp(0.0, height)
    );
    
    setState(() {
      // Eğer tıklama makasın yakınındaysa, sadece makası hareket ettir
      if (distance <= cutterSize * 1.5) {
        // Maskenin kenar boşluğu
        final maskPadding = 20.0;
        final maskLeft = maskPadding;
        final maskRight = width - maskPadding;
        final maskTop = maskPadding;
        final maskBottom = height - maskPadding;
        
        // Makası sadece maskenin kenarlarına taşı
        double nearestX = clampedPos.dx;
        double nearestY = clampedPos.dy;
        
        // X koordinatı için en yakın kenarı bul
        if (clampedPos.dx < maskLeft) {
          nearestX = maskLeft;
        } else if (clampedPos.dx > maskRight) {
          nearestX = maskRight;
        } else {
          // Eğer X koordinatı maskenin içindeyse, en yakın X kenarını bul
          double distanceToLeft = (clampedPos.dx - maskLeft).abs();
          double distanceToRight = (clampedPos.dx - maskRight).abs();
          nearestX = distanceToLeft < distanceToRight ? maskLeft : maskRight;
        }
        
        // Y koordinatı için en yakın kenarı bul
        if (clampedPos.dy < maskTop) {
          nearestY = maskTop;
        } else if (clampedPos.dy > maskBottom) {
          nearestY = maskBottom;
        } else {
          // Eğer Y koordinatı maskenin içindeyse, en yakın Y kenarını bul
          double distanceToTop = (clampedPos.dy - maskTop).abs();
          double distanceToBottom = (clampedPos.dy - maskBottom).abs();
          nearestY = distanceToTop < distanceToBottom ? maskTop : maskBottom;
        }
        
        // En yakın kenar noktasını seç (X veya Y)
        double distanceToNearestX = min((clampedPos.dx - maskLeft).abs(), (clampedPos.dx - maskRight).abs());
        double distanceToNearestY = min((clampedPos.dy - maskTop).abs(), (clampedPos.dy - maskBottom).abs());
        
        if (distanceToNearestX < distanceToNearestY) {
          // X kenarı daha yakın
          cutterPosition = Offset(nearestX, clampedPos.dy);
        } else {
          // Y kenarı daha yakın
          cutterPosition = Offset(clampedPos.dx, nearestY);
        }
        
        // Eğer makas maskenin kenarındaysa ve henüz kesim başlamamışsa, kesim işlemini başlat
        if (_isPositionOnEdge(cutterPosition, Size(width, height)) && !isCutterActive) {
          isCutterActive = true;
          lastGridPosition = cutterPosition;
          cutPath = [cutterPosition];
          cutStartPosition = cutterPosition;
          currentDirection = Direction.none;
        }
      } 
      // Eğer tıklama makasın yakınında değilse, makası tıklanan konuma taşı
      else {
        // Makası sadece maskenin kenarlarına taşı
        final maskPadding = 20.0;
        final maskLeft = maskPadding;
        final maskRight = width - maskPadding;
        final maskTop = maskPadding;
        final maskBottom = height - maskPadding;
        
        // En yakın kenar noktasını bul
        double nearestX = clampedPos.dx;
        double nearestY = clampedPos.dy;
        
        // X koordinatı için en yakın kenarı bul
        if (clampedPos.dx < maskLeft) {
          nearestX = maskLeft;
        } else if (clampedPos.dx > maskRight) {
          nearestX = maskRight;
        } else {
          // Eğer X koordinatı maskenin içindeyse, en yakın X kenarını bul
          double distanceToLeft = (clampedPos.dx - maskLeft).abs();
          double distanceToRight = (clampedPos.dx - maskRight).abs();
          nearestX = distanceToLeft < distanceToRight ? maskLeft : maskRight;
        }
        
        // Y koordinatı için en yakın kenarı bul
        if (clampedPos.dy < maskTop) {
          nearestY = maskTop;
        } else if (clampedPos.dy > maskBottom) {
          nearestY = maskBottom;
        } else {
          // Eğer Y koordinatı maskenin içindeyse, en yakın Y kenarını bul
          double distanceToTop = (clampedPos.dy - maskTop).abs();
          double distanceToBottom = (clampedPos.dy - maskBottom).abs();
          nearestY = distanceToTop < distanceToBottom ? maskTop : maskBottom;
        }
        
        // En yakın kenar noktasını seç (X veya Y)
        double distanceToNearestX = min((clampedPos.dx - maskLeft).abs(), (clampedPos.dx - maskRight).abs());
        double distanceToNearestY = min((clampedPos.dy - maskTop).abs(), (clampedPos.dy - maskBottom).abs());
        
        if (distanceToNearestX < distanceToNearestY) {
          // X kenarı daha yakın
          cutterPosition = Offset(nearestX, clampedPos.dy);
        } else {
          // Y kenarı daha yakın
          cutterPosition = Offset(clampedPos.dx, nearestY);
        }
      }
    });
  }
  
  // Kesici aleti hareket ettir
  void _moveCutter(Offset position) {
    if (gameOver || gameWon) return;
    
    // Pozisyonu oyun alanı sınırları içinde tut
    final clampedPos = Offset(
      position.dx.clamp(0.0, width),
      position.dy.clamp(0.0, height)
    );
    
    setState(() {
      // Eğer kesim işlemi aktifse
      if (isCutterActive && lastGridPosition != null) {
        // Maskenin kenar boşluğu
        final maskPadding = 20.0;
        final maskLeft = maskPadding;
        final maskRight = width - maskPadding;
        final maskTop = maskPadding;
        final maskBottom = height - maskPadding;
        
        // Makası sadece maskenin kenarlarında hareket ettir
        double nearestX = clampedPos.dx;
        double nearestY = clampedPos.dy;
        
        // Makası maskenin kenarlarında tut
        if (clampedPos.dx < maskLeft) nearestX = maskLeft;
        if (clampedPos.dx > maskRight) nearestX = maskRight;
        if (clampedPos.dy < maskTop) nearestY = maskTop;
        if (clampedPos.dy > maskBottom) nearestY = maskBottom;
        
        // Eğer son pozisyon ile aynı pozisyondaysa, hiçbir şey yapma
        if (lastGridPosition == Offset(nearestX, nearestY)) return;
        
        // Yeni yönü belirle
        Direction newDirection;
        
        // Eğer henüz bir yön belirlenmemişse
        if (currentDirection == Direction.none) {
          // İlk hareket için, yatay veya dikey yönü belirle
          final dx = nearestX - lastGridPosition!.dx;
          final dy = nearestY - lastGridPosition!.dy;
          
          // Yatay hareket daha fazlaysa
          if (dx.abs() > dy.abs()) {
            newDirection = dx > 0 ? Direction.right : Direction.left;
            // Sadece X koordinatını değiştir, Y sabit kalsın
            nearestY = lastGridPosition!.dy;
          } 
          // Dikey hareket daha fazlaysa
          else {
            newDirection = dy > 0 ? Direction.down : Direction.up;
            // Sadece Y koordinatını değiştir, X sabit kalsın
            nearestX = lastGridPosition!.dx;
          }
        } else {
          // Mevcut yönde devam et veya 90 derece dön
          final dx = nearestX - lastGridPosition!.dx;
          final dy = nearestY - lastGridPosition!.dy;
          
          // Mevcut yön yatay ise
          if (currentDirection == Direction.left || currentDirection == Direction.right) {
            // Eğer yatay hareket daha fazlaysa, aynı yönde devam et
            if (dx.abs() > dy.abs()) {
              newDirection = dx > 0 ? Direction.right : Direction.left;
              // Sadece X koordinatını değiştir, Y sabit kalsın
              nearestY = lastGridPosition!.dy;
            } 
            // Eğer dikey hareket daha fazlaysa, 90 derece dön
            else {
              newDirection = dy > 0 ? Direction.down : Direction.up;
              // Sadece Y koordinatını değiştir, X sabit kalsın
              nearestX = lastGridPosition!.dx;
            }
          } 
          // Mevcut yön dikey ise
          else {
            // Eğer dikey hareket daha fazlaysa, aynı yönde devam et
            if (dy.abs() > dx.abs()) {
              newDirection = dy > 0 ? Direction.down : Direction.up;
              // Sadece Y koordinatını değiştir, X sabit kalsın
              nearestX = lastGridPosition!.dx;
            } 
            // Eğer yatay hareket daha fazlaysa, 90 derece dön
            else {
              newDirection = dx > 0 ? Direction.right : Direction.left;
              // Sadece X koordinatını değiştir, Y sabit kalsın
              nearestY = lastGridPosition!.dy;
            }
          }
        }
        
        // Makası yeni pozisyona taşı
        cutterPosition = Offset(nearestX, nearestY);
        
        // Yeni yönü kaydet
        currentDirection = newDirection;
        
        // Kesim yolunu güncelle
        cutPath.add(cutterPosition);
        lastGridPosition = cutterPosition;
        
        // Eğer kenarlardan birine ulaştıysa ve başlangıç noktası da kenardaysa, kesim işlemini bitir
        if (_isPositionOnEdge(cutterPosition, Size(width, height)) && 
            cutPath.length > 1 && 
            _isPositionOnEdge(cutPath.first, Size(width, height)) &&
            cutPath.first != cutterPosition) {
          _endCutting();
        }
      }
      // Eğer kesim işlemi aktif değilse, makası maskenin kenarlarında hareket ettir
      else {
        // Makası sadece maskenin kenarlarına taşı
        final maskPadding = 20.0;
        final maskLeft = maskPadding;
        final maskRight = width - maskPadding;
        final maskTop = maskPadding;
        final maskBottom = height - maskPadding;
        
        // En yakın kenar noktasını bul
        double nearestX = clampedPos.dx;
        double nearestY = clampedPos.dy;
        
        // X koordinatı için en yakın kenarı bul
        if (clampedPos.dx < maskLeft) {
          nearestX = maskLeft;
        } else if (clampedPos.dx > maskRight) {
          nearestX = maskRight;
        } else {
          // Eğer X koordinatı maskenin içindeyse, en yakın X kenarını bul
          double distanceToLeft = (clampedPos.dx - maskLeft).abs();
          double distanceToRight = (clampedPos.dx - maskRight).abs();
          nearestX = distanceToLeft < distanceToRight ? maskLeft : maskRight;
        }
        
        // Y koordinatı için en yakın kenarı bul
        if (clampedPos.dy < maskTop) {
          nearestY = maskTop;
        } else if (clampedPos.dy > maskBottom) {
          nearestY = maskBottom;
        } else {
          // Eğer Y koordinatı maskenin içindeyse, en yakın Y kenarını bul
          double distanceToTop = (clampedPos.dy - maskTop).abs();
          double distanceToBottom = (clampedPos.dy - maskBottom).abs();
          nearestY = distanceToTop < distanceToBottom ? maskTop : maskBottom;
        }
        
        // En yakın kenar noktasını seç (X veya Y)
        double distanceToNearestX = min((clampedPos.dx - maskLeft).abs(), (clampedPos.dx - maskRight).abs());
        double distanceToNearestY = min((clampedPos.dy - maskTop).abs(), (clampedPos.dy - maskBottom).abs());
        
        if (distanceToNearestX < distanceToNearestY) {
          // X kenarı daha yakın
          cutterPosition = Offset(nearestX, clampedPos.dy);
        } else {
          // Y kenarı daha yakın
          cutterPosition = Offset(clampedPos.dx, nearestY);
        }
        
        // Eğer makas maskenin kenarındaysa ve henüz kesim başlamamışsa, kesim işlemini başlat
        if (_isPositionOnEdge(cutterPosition, Size(width, height)) && !isCutterActive) {
          isCutterActive = true;
          lastGridPosition = cutterPosition;
          cutPath = [cutterPosition];
          cutStartPosition = cutterPosition;
          currentDirection = Direction.none;
        }
      }
    });
  }
  
  // Kesme işlemini bitir
  void _endCutting() {
    if (!isCutterActive || gameOver || gameWon) return;
    
    bool cuttingCompleted = false;
    
    if (cutStartPosition != null && cutPath.length > 1) {
      // Başlangıç ve bitiş noktalarının kenarda olup olmadığını kontrol et
      bool isStartOnEdge = _isPositionOnEdge(cutStartPosition!, Size(width, height));
      bool isEndOnEdge = _isPositionOnEdge(cutterPosition, Size(width, height));
      
      if (isStartOnEdge && isEndOnEdge) {
        // Kesim çizgisini kullanarak oyun alanını ikiye böl
        final cuttingRect = _createCuttingRect();
        
        if (cuttingRect != null) {
          setState(() {
            // Yeni kesilen alanı ekle
            revealedAreas.add(cuttingRect);
            _calculateRevealedPercentage();
            
            // Kullanıcıya geri bildirim ver
            HapticFeedback.mediumImpact();
          });
          
          // Kesim tamamlandı olarak işaretle
          cuttingCompleted = true;
        }
      }
    }
    
    setState(() {
      isCutterActive = false;
      cutStartPosition = null;
      lastGridPosition = null;
      cutPath.clear();
      currentDirection = Direction.none;
      
      // Eğer kesim tamamlanmadıysa ve makas maskenin kenarında değilse
      if (!cuttingCompleted && !_isPositionOnEdge(cutterPosition, Size(width, height))) {
        // Maskenin kenar boşluğu
        final maskPadding = 20.0;
        final maskLeft = maskPadding;
        final maskRight = width - maskPadding;
        final maskTop = maskPadding;
        final maskBottom = height - maskPadding;
        
        // En yakın kenar noktasını bul
        double nearestX = cutterPosition.dx;
        double nearestY = cutterPosition.dy;
        
        // X koordinatı için en yakın kenarı bul
        if (cutterPosition.dx < maskLeft) {
          nearestX = maskLeft;
        } else if (cutterPosition.dx > maskRight) {
          nearestX = maskRight;
        } else {
          // Eğer X koordinatı maskenin içindeyse, en yakın X kenarını bul
          double distanceToLeft = (cutterPosition.dx - maskLeft).abs();
          double distanceToRight = (cutterPosition.dx - maskRight).abs();
          nearestX = distanceToLeft < distanceToRight ? maskLeft : maskRight;
        }
        
        // Y koordinatı için en yakın kenarı bul
        if (cutterPosition.dy < maskTop) {
          nearestY = maskTop;
        } else if (cutterPosition.dy > maskBottom) {
          nearestY = maskBottom;
        } else {
          // Eğer Y koordinatı maskenin içindeyse, en yakın Y kenarını bul
          double distanceToTop = (cutterPosition.dy - maskTop).abs();
          double distanceToBottom = (cutterPosition.dy - maskBottom).abs();
          nearestY = distanceToTop < distanceToBottom ? maskTop : maskBottom;
        }
        
        // En yakın kenar noktasını seç (X veya Y)
        double distanceToNearestX = min((cutterPosition.dx - maskLeft).abs(), (cutterPosition.dx - maskRight).abs());
        double distanceToNearestY = min((cutterPosition.dy - maskTop).abs(), (cutterPosition.dy - maskBottom).abs());
        
        if (distanceToNearestX < distanceToNearestY) {
          // X kenarı daha yakın
          cutterPosition = Offset(nearestX, cutterPosition.dy);
        } else {
          // Y kenarı daha yakın
          cutterPosition = Offset(cutterPosition.dx, nearestY);
        }
      }
    });
  }
  
  // Kesim çizgisini kullanarak oyun alanını ikiye bölen dikdörtgen oluştur
  Rect? _createCuttingRect() {
    if (cutPath.length < 2) return null;
    
    // Başlangıç ve bitiş noktaları
    final start = cutPath.first;
    final end = cutPath.last;
    
    // Bitiş noktası kenarda mı kontrol et
    if (!_isPositionOnEdge(end, Size(width, height))) return null;
    
    // Maskenin kenar boşluğu
    final maskPadding = 20.0;
    
    // Maskenin kenarları
    final maskLeft = maskPadding;
    final maskRight = width - maskPadding;
    final maskTop = maskPadding;
    final maskBottom = height - maskPadding;
    
    // Kesim yolundaki tüm noktaları kullanarak bir dikdörtgen oluştur
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = 0;
    double maxY = 0;
    
    // Kesim yolundaki tüm noktaları kontrol et
    for (var point in cutPath) {
      minX = min(minX, point.dx);
      minY = min(minY, point.dy);
      maxX = max(maxX, point.dx);
      maxY = max(maxY, point.dy);
    }
    
    // Dikdörtgenin sınırlarını maskenin sınırlarına göre ayarla
    minX = max(minX, maskLeft);
    minY = max(minY, maskTop);
    maxX = min(maxX, maskRight);
    maxY = min(maxY, maskBottom);
    
    // Dikdörtgeni oluştur
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
  
  // Bir noktanın maskenin kenarında olup olmadığını kontrol et
  bool _isPositionOnEdge(Offset position, Size size) {
    final maskPadding = 20.0; // Maskenin kenar boşluğu
    final edgeThreshold = 5.0; // Kenar algılama eşiği
    
    // Maskenin kenarları
    final maskLeft = maskPadding;
    final maskRight = size.width - maskPadding;
    final maskTop = maskPadding;
    final maskBottom = size.height - maskPadding;
    
    // Maskenin kenarlarında mı kontrol et
    return (position.dx >= maskLeft - edgeThreshold && position.dx <= maskLeft + edgeThreshold) || // Sol kenar
           (position.dx >= maskRight - edgeThreshold && position.dx <= maskRight + edgeThreshold) || // Sağ kenar
           (position.dy >= maskTop - edgeThreshold && position.dy <= maskTop + edgeThreshold) || // Üst kenar
           (position.dy >= maskBottom - edgeThreshold && position.dy <= maskBottom + edgeThreshold); // Alt kenar
  }
  
  // Çizgiden dikdörtgen oluştur
  Rect _createRectFromLine(Offset start, Offset end, double thickness) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    
    if (distance < 0.1) {
      // Çok kısa çizgi, minimum bir dikdörtgen döndür
      return Rect.fromCenter(
        center: start,
        width: thickness,
        height: thickness
      );
    }
    
    // Çizgiye dik açıları hesapla
    final normalizedDx = dx / distance;
    final normalizedDy = dy / distance;
    
    // Çizgiye dik vektör (-normalizedDy, normalizedDx)
    final halfThickness = thickness / 2;
    final offsetX = normalizedDy * halfThickness;
    final offsetY = -normalizedDx * halfThickness;
    
    // Dikdörtgenin 4 köşesini hesapla
    final p1 = Offset(start.dx + offsetX, start.dy + offsetY);
    final p2 = Offset(start.dx - offsetX, start.dy - offsetY);
    final p3 = Offset(end.dx - offsetX, end.dy - offsetY);
    final p4 = Offset(end.dx + offsetX, end.dy + offsetY);
    
    // Dikdörtgenin sınırlayıcı kutusunu oluştur
    final left = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(min);
    final top = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(min);
    final right = [p1.dx, p2.dx, p3.dx, p4.dx].reduce(max);
    final bottom = [p1.dy, p2.dy, p3.dy, p4.dy].reduce(max);
    
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resmi Aç'),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Nasıl Oynanır?'),
                  content: Text(
                    'Makası kullanarak resmin üzerini kesin. '
                    'Makas sadece düz çizgiler ve 90 derece dönüşler yapabilir. '
                    'Kesme işlemi bir kenardan başlamalı ve başka bir kenarda bitmelidir. '
                    'Kesilen bölgeler açılacak ve alttaki resim görünecektir. '
                    'Resmin %${winThreshold.toInt()} kadarını açmaya çalışın.'
                  ),
                  actions: [
                    TextButton(
                      child: Text('Anladım'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Açılan Alan: %${revealedPercentage.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 3),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    width = constraints.maxWidth;
                    height = constraints.maxHeight;
                    
                    // Makasın başlangıç konumunu ayarla (eğer henüz ayarlanmadıysa)
                    if (cutterPosition == Offset.zero) {
                      final maskPadding = 20.0;
                      final maskBottom = height - maskPadding;
                      cutterPosition = Offset(width / 2, maskBottom);
                    }
                    
                    return Stack(
                      children: [
                        // Orijinal resim (bulanık olmayan)
                        Positioned.fill(
                          child: Image.asset(
                            widget.item.imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                        
                        // Siyah maske (kesilen alanlar hariç)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MaskPainter(revealedAreas),
                            size: Size(width, height),
                          ),
                        ),
                        
                        // Kesme çerçevesi (aktif kesme sırasında)
                        if (isCutterActive && cutPath.isNotEmpty)
                          CustomPaint(
                            painter: CutFramePainter(
                              cutPath: cutPath,
                            ),
                            size: Size(width, height),
                          ),
                        
                        // Kesici alet - makası oyun alanının sınırında konumlandırıyoruz
                        Positioned(
                          left: cutterPosition.dx - cutterSize / 2,
                          top: cutterPosition.dy - cutterSize / 2,
                          child: Container(
                            width: cutterSize,
                            height: cutterSize,
                            decoration: BoxDecoration(
                              color: Colors.yellow,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.content_cut,
                                color: Colors.black,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        
                        // Dokunma alanı - hitTest: false ekleyerek alttaki widget'ların dokunuşları almasını sağlıyoruz
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onPanStart: (details) {
                              _startCutting(details.localPosition);
                            },
                            onPanUpdate: (details) {
                              _moveCutter(details.localPosition);
                            },
                            onPanEnd: (details) {
                              _endCutting();
                            },
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Oyun durumu mesajı
  Widget _buildGameStatusMessage(String message, Color color) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tebrikler!'),
          content: Text('Resmi başarıyla açtınız!'),
          actions: <Widget>[
            TextButton(
              child: Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onGameComplete(true);
              },
            ),
          ],
        );
      },
    );
  }

  // Yeni yönü belirle
  Direction _getNewDirection(Offset from, Offset to) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    
    // Yatay hareket daha fazlaysa
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? Direction.right : Direction.left;
    } 
    // Dikey hareket daha fazlaysa
    else {
      return dy > 0 ? Direction.down : Direction.up;
    }
  }

  // Yöne göre bir sonraki pozisyonu hesapla
  Offset _getNextPosition(Offset current, Direction direction) {
    switch (direction) {
      case Direction.up:
        return Offset(current.dx, current.dy - gridSize);
      case Direction.down:
        return Offset(current.dx, current.dy + gridSize);
      case Direction.left:
        return Offset(current.dx - gridSize, current.dy);
      case Direction.right:
        return Offset(current.dx + gridSize, current.dy);
      case Direction.none:
        return current;
    }
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

// Maske çizici
class MaskPainter extends CustomPainter {
  final List<Rect> revealedAreas;
  
  MaskPainter(this.revealedAreas);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Maskeyi küçültmek için kenar boşluğu
    final maskPadding = 20.0;
    
    // Küçültülmüş maske alanı
    final maskRect = Rect.fromLTRB(
      maskPadding, 
      maskPadding, 
      size.width - maskPadding, 
      size.height - maskPadding
    );
    
    if (revealedAreas.isEmpty) {
      // Hiç kesilen alan yoksa, küçültülmüş alanı siyah maske ile kapla
      final maskPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(maskRect, maskPaint);
      return;
    }
    
    // Önce bir katman oluştur
    canvas.saveLayer(maskRect, Paint());
    
    // Küçültülmüş alanı siyah maske ile kapla
    final maskPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(maskRect, maskPaint);
    
    // Kesilen alanları temizle
    final clearPaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    
    for (var rect in revealedAreas) {
      // Kesilen alanı maske alanı ile kesiştir
      final intersectedRect = rect.intersect(maskRect);
      
      // Kesişen alanı temizle
      canvas.drawRect(intersectedRect, clearPaint);
      
      // Kesilen alanların sınırlarını belirginleştir
      final borderPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRect(intersectedRect, borderPaint);
    }
    
    // Katmanı geri yükle
    canvas.restore();
    
    // Maskenin sınırlarını belirginleştir
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(maskRect, borderPaint);
  }
  
  @override
  bool shouldRepaint(MaskPainter oldDelegate) {
    return oldDelegate.revealedAreas != revealedAreas;
  }
}

// Kesme çerçevesi çizici
class CutFramePainter extends CustomPainter {
  final List<Offset> cutPath;
  
  CutFramePainter({
    required this.cutPath,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (cutPath.isEmpty) return;
    
    // Maskenin kenar boşluğu
    final maskPadding = 20.0;
    
    // Maskenin kenarları
    final maskLeft = maskPadding;
    final maskRight = size.width - maskPadding;
    final maskTop = maskPadding;
    final maskBottom = size.height - maskPadding;
    
    // Kesim sonrası açılacak alanı göster
    if (cutPath.length >= 2) {
      final start = cutPath.first;
      final end = cutPath.last;
      
      // Başlangıç ve bitiş noktaları kenarda mı kontrol et
      bool isStartOnEdge = _isPositionOnEdge(start, size);
      bool isEndOnEdge = _isPositionOnEdge(end, size);
      
      // Eğer başlangıç noktası kenarda ise ve bitiş noktası da kenarda veya son noktaysa
      if (isStartOnEdge && (isEndOnEdge || end == cutPath.last)) {
        // Kesim yolundaki tüm noktaları kullanarak bir dikdörtgen oluştur
        double minX = double.infinity;
        double minY = double.infinity;
        double maxX = 0;
        double maxY = 0;
        
        // Kesim yolundaki tüm noktaları kontrol et
        for (var point in cutPath) {
          minX = min(minX, point.dx);
          minY = min(minY, point.dy);
          maxX = max(maxX, point.dx);
          maxY = max(maxY, point.dy);
        }
        
        // Dikdörtgenin sınırlarını maskenin sınırlarına göre ayarla
        minX = max(minX, maskLeft);
        minY = max(minY, maskTop);
        maxX = min(maxX, maskRight);
        maxY = min(maxY, maskBottom);
        
        // Dikdörtgeni çiz
        final highlightPaint = Paint()
          ..color = Colors.yellow.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        
        final borderPaint = Paint()
          ..color = Colors.yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        
        final rect = Rect.fromLTRB(minX, minY, maxX, maxY);
        canvas.drawRect(rect, highlightPaint);
        canvas.drawRect(rect, borderPaint);
      }
    }
    
    // Başlangıç ve bitiş noktalarını belirginleştir
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    // Başlangıç noktası
    canvas.drawCircle(cutPath.first, 8.0, pointPaint);
    
    // Bitiş noktası (son nokta)
    canvas.drawCircle(cutPath.last, 8.0, pointPaint);
    
    // Maskenin sınırlarını belirginleştir
    final maskBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final maskRect = Rect.fromLTRB(maskLeft, maskTop, maskRight, maskBottom);
    canvas.drawRect(maskRect, maskBorderPaint);
  }
  
  // Bir noktanın kenarda olup olmadığını kontrol et
  bool _isPositionOnEdge(Offset position, Size size) {
    final maskPadding = 20.0; // Maskenin kenar boşluğu
    final edgeThreshold = 5.0; // Kenar algılama eşiği
    
    // Maskenin kenarları
    final maskLeft = maskPadding;
    final maskRight = size.width - maskPadding;
    final maskTop = maskPadding;
    final maskBottom = size.height - maskPadding;
    
    // Maskenin kenarlarında mı kontrol et
    return (position.dx >= maskLeft - edgeThreshold && position.dx <= maskLeft + edgeThreshold) || // Sol kenar
           (position.dx >= maskRight - edgeThreshold && position.dx <= maskRight + edgeThreshold) || // Sağ kenar
           (position.dy >= maskTop - edgeThreshold && position.dy <= maskTop + edgeThreshold) || // Üst kenar
           (position.dy >= maskBottom - edgeThreshold && position.dy <= maskBottom + edgeThreshold); // Alt kenar
  }
  
  @override
  bool shouldRepaint(CutFramePainter oldDelegate) {
    return oldDelegate.cutPath != cutPath;
  }
} 