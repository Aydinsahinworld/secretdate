import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/game_interface.dart';
import '../models/dialog_game_data.dart';
import '../games/dialog_game.dart';
import '../widgets/loading_screen.dart';
import '../models/content_item.dart';
import '../models/player_gender.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class GameScreen extends StatefulWidget {
  final ContentItem item;
  final bool isMale;

  const GameScreen({
    Key? key,
    required this.item,
    required this.isMale,
  }) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameInterface _game;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  Timer? _loadingTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (!mounted) return;

    // Yükleme ekranını göster
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
    });

    // Yükleme animasyonunu başlat
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _loadingProgress = (_loadingProgress + 0.05).clamp(0.0, 0.9);
      });
    });

    try {
      // Soruları yükle
      print('Sorular yükleniyor: ${widget.item.type}, ${widget.isMale}, ${widget.item.level}');
      final questions = await DialogGameData.loadQuestions(
        type: widget.item.type,
        isMale: widget.isMale,
        level: widget.item.level,
      );

      if (!mounted) return;

      if (questions.isEmpty) {
        throw Exception('Bu bölüm için soru bulunamadı.');
      }

      print('Yüklenen soru sayısı: ${questions.length}');

      // Oyunu oluştur
      setState(() {
        _game = DialogGame(
          questions: questions,
          type: widget.item.type,
          onBlurLevelChanged: (blurLevel) {
            if (mounted) {
              setState(() {
                widget.item.blurLevel = blurLevel;
              });
            }
          },
          onGameComplete: (isWon) async {
            if (isWon) {
              await _markLevelAsCompleted();
            }
          },
          isMale: widget.isMale,
        );
      });

      // Yükleme animasyonunu tamamla
      if (mounted) {
        setState(() {
          _loadingProgress = 1.0;
        });
      }

      // Minimum yükleme süresi için bekle
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Hata oluştu: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    } finally {
      _loadingTimer?.cancel();
    }
  }

  Future<void> _markLevelAsCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Benzersiz ID oluştur
      final gender = widget.isMale ? 'male' : 'female';
      final type = widget.item.type.toString().split('.').last.toLowerCase();
      final level = widget.item.level.toString().padLeft(2, '0');
      final levelId = '${gender}_${type}_$level';
      final imagePath = widget.item.imagePath;
      
      print('Mevcut tamamlanan seviyeler: ${prefs.getStringList('completedLevels')}');
      print('Mevcut arşiv resimleri: ${prefs.getStringList('completed_images')}');
      print('Kaydedilecek level ID: $levelId');
      print('Kaydedilecek resim yolu: $imagePath');
      
      // Eski formatı temizle
      final completedLevels = (prefs.getStringList('completedLevels') ?? [])
        .where((id) => !id.contains('${gender}_${type}_${widget.item.level}'))
        .toList();
      
      // Yeni ID'yi ekle
      if (!completedLevels.contains(levelId)) {
        completedLevels.add(levelId);
        await prefs.setStringList('completedLevels', completedLevels);
        print('Level ID kaydedildi: $levelId');
      }

      // Resmi arşive ekle
      final archiveImages = prefs.getStringList('completed_images') ?? [];
      if (!archiveImages.contains(imagePath)) {
        archiveImages.add(imagePath);
        await prefs.setStringList('completed_images', archiveImages);
        print('Resim arşive eklendi: $imagePath');
        print('Güncel arşiv resimleri: ${prefs.getStringList('completed_images')}');
      }
    } catch (e) {
      print('Hata oluştu: $e');
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Arkaplan resmi
            Positioned.fill(
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.item.imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    // Bulanıklık efekti
                    if (!_isLoading && widget.item.blurLevel > 0)
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: widget.item.blurLevel,
                            sigmaY: widget.item.blurLevel,
                          ),
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Hata mesajı
            if (_errorMessage != null)
              Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('GERİ DÖN'),
                      ),
                    ],
                  ),
                ),
              ),

            // Yükleme ekranı
            if (_isLoading)
              LoadingScreen(
                backgroundImageUrl: widget.item.imagePath,
                progress: _loadingProgress,
                loadingText: 'Oyun Yükleniyor...',
                hints: const [
                  'İpuçlarını dikkatlice oku...',
                  'Her yanlış cevap bir kalp kaybettirir...',
                  'Doğru cevaplar resmi netleştirir...',
                  'Tüm kalpleri kaybetmeden bitirmeye çalış...',
                ],
              ),

            // Oyun içeriği
            if (!_isLoading && _errorMessage == null) _game.buildGame(context),
          ],
        ),
      ),
    );
  }
} 