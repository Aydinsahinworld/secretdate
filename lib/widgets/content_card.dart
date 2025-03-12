import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/content_item.dart';
import '../screens/content_screen.dart';
import '../screens/game_screen.dart';
import '../models/player_gender.dart';

class ContentCard extends StatefulWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final bool isMale;
  final bool isLocked;
  final bool isCompleted;
  final int remainingHearts;

  const ContentCard({
    Key? key,
    required this.item,
    this.onTap,
    required this.isMale,
    required this.isLocked,
    required this.isCompleted,
    this.remainingHearts = 5,
  }) : super(key: key);

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isExpanded = false;
  bool _isPlayButtonPressed = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showOverlay(position, size);
    }
  }

  void _showOverlay(Offset position, Size size) {
    _overlayEntry = OverlayEntry(
      builder: (context) => WillPopScope(
        onWillPop: () async {
          if (_isExpanded) {
            _removeOverlay();
            return false;
          }
          return true;
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Arkaplan - Tıklanabilir karartma
              Positioned.fill(
                child: GestureDetector(
                  onTap: _removeOverlay,
                  child: AnimatedBuilder(
                    animation: _expandAnimation,
                    builder: (context, child) {
                      return Container(
                        color: Colors.black.withOpacity(0.7 * _expandAnimation.value),
                      );
                    },
                  ),
                ),
              ),

              // Animasyonlu kart
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  // Ekran boyutlarını al
                  final screenSize = MediaQuery.of(context).size;
                  
                  // Hedef boyutlar
                  final targetWidth = 280.0;
                  final targetHeight = 400.0;
                  
                  // AppBar yüksekliğini al
                  final appBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
                  
                  // Kullanılabilir ekran yüksekliği
                  final availableHeight = screenSize.height - appBarHeight;
                  
                  // Ekranın tam ortası için hedef pozisyonlar (AppBar'ı hesaba katarak)
                  final targetLeft = (screenSize.width - targetWidth) / 2;
                  final targetTop = appBarHeight + (availableHeight - targetHeight) / 2;
                  
                  // Mevcut pozisyon ve boyutlar için interpolasyon
                  final currentLeft = position.dx + (targetLeft - position.dx) * _expandAnimation.value;
                  final currentTop = position.dy + (targetTop - position.dy) * _expandAnimation.value;
                  final currentWidth = size.width + (targetWidth - size.width) * _expandAnimation.value;
                  final currentHeight = size.height + (targetHeight - size.height) * _expandAnimation.value;

                  return Positioned(
                    left: currentLeft,
                    top: currentTop,
                    width: currentWidth,
                    height: currentHeight,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: widget.item.type.color.withOpacity(0.6),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.type.color.withOpacity(0.4),
                              blurRadius: 10 + (10 * _expandAnimation.value),
                              spreadRadius: 1 + (3 * _expandAnimation.value),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              // Resim
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: widget.isCompleted ? 0 : 5.0,
                                  sigmaY: widget.isCompleted ? 0 : 5.0,
                                ),
                                child: Image.asset(
                                  widget.item.imageUrl,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                              ),

                              // İçerik
                              FadeTransition(
                                opacity: _expandAnimation,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Kalpler
                                    Padding(
                                      padding: const EdgeInsets.only(top: 20),
                                      child: _buildHearts(),
                                    ),
                                    
                                    // OYNA butonu
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 30),
                                      child: _buildPlayButton(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Overlay'i ekle
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(_overlayEntry!);
    
    // ContentScreen'e aktif overlay'i bildir
    final contentScreen = context.findAncestorStateOfType<ContentScreenState>();
    if (contentScreen != null) {
      contentScreen.setActiveOverlay(_overlayEntry);
    }
    
    setState(() => _isExpanded = true);
    _expandController.forward();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _expandController.reverse().whenComplete(() {
        // ContentScreen'e overlay'in kapandığını bildir
        final contentScreen = context.findAncestorStateOfType<ContentScreenState>();
        if (contentScreen != null) {
          contentScreen.setActiveOverlay(null);
        }
        
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() => _isExpanded = false);
      });
    }
  }

  Widget _buildHearts() {
    print('ContentCard - Kalp Bilgileri:');
    print('Bölüm tamamlandı mı: ${widget.isCompleted}');
    print('Kalan kalp sayısı: ${widget.remainingHearts}');

    // Eğer bölüm tamamlanmamışsa 5 kalp göster
    if (!widget.isCompleted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.favorite,
              color: widget.item.type.color,
              size: 24,
              shadows: [
                Shadow(
                  color: widget.item.type.color.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          );
        }),
      );
    }

    // Bölüm tamamlanmışsa kalan kalp sayısı kadar kalp göster
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.remainingHearts, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.favorite,
            color: widget.item.type.color,
            size: 24,
            shadows: [
              Shadow(
                color: widget.item.type.color.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPlayButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() => _isPlayButtonPressed = true);
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _isPlayButtonPressed = false);
            _removeOverlay();
            _navigateToGame(context);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _isPlayButtonPressed 
          ? widget.item.type.color.withOpacity(0.4)
          : widget.item.type.color.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: _isPlayButtonPressed ? 0 : 8,
        shadowColor: widget.item.type.color.withOpacity(0.5),
      ),
      child: const Text(
        'OYNA',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void _navigateToGame(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          item: widget.item,
          isMale: widget.isMale,
        ),
      ),
    );
  }

  // Büyütülmüş kartın içeriği
  Widget _buildExpandedContent(BuildContext context, OverlayEntry overlayEntry) {
    return GestureDetector(
      onTap: () {}, // Boş onTap ile arka plana tıklamayı engelle
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Stack(
          children: [
            // ... existing expanded content ...

            // Oyna butonu
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: _buildPlayButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.item.type.color.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.item.type.color.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Resim
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: widget.isCompleted ? 0 : 5.0,
                  sigmaY: widget.isCompleted ? 0 : 5.0,
                ),
                child: Image.asset(
                  widget.item.imageUrl,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Başlık
              if (widget.item.title.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Text(
                    widget.item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 