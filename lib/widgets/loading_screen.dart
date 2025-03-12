import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';

class LoadingScreen extends StatefulWidget {
  final String backgroundImageUrl;
  final double progress;
  final String? loadingText;
  final List<String> hints;

  const LoadingScreen({
    Key? key,
    required this.backgroundImageUrl,
    required this.progress,
    this.loadingText,
    this.hints = const [
      'Karakterin ruh haline uygun cevaplar verin',
      'Doğru cevaplar bulanıklığı azaltır',
      'Her yanlış cevapta bir kalp kaybedersiniz',
      'Karakterin ipuçlarını dikkatlice okuyun',
      'Cevaplarınızı düşünerek verin',
      'Karakterin tarzına uygun seçimler yapın',
      'Her bölümde zorluk seviyesi artar',
      'Tüm kalplerinizi kaybetmeden bölümü tamamlayın',
      'Doğru cevaplar karakteri daha net gösterir',
    ],
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final String _selectedTip;

  @override
  void initState() {
    super.initState();
    // Rastgele bir ipucu seç ve kaydet
    _selectedTip = widget.hints[Random().nextInt(widget.hints.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Arkaplan resmi
        Positioned.fill(
          child: Image.asset(
            widget.backgroundImageUrl,
            fit: BoxFit.cover,
          ),
        ),

        // Bulanık overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ),

        // Yükleme içeriği
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Yükleme animasyonu
              Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Stack(
                  children: [
                    AnimatedFractionallySizedBox(
                      duration: const Duration(milliseconds: 300),
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.withOpacity(0.8),
                              Colors.purple.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.pink.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Yükleme metni
              if (widget.loadingText != null)
                Text(
                  widget.loadingText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // İpucu alanı
        Positioned(
          left: 20,
          right: 20,
          bottom: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.yellow.withOpacity(0.8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedTip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 