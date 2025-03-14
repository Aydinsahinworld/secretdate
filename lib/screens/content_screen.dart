import 'package:flutter/material.dart';
import '../models/content_item.dart';
import '../models/game_interface.dart'; // GameType enum'u için
import '../widgets/content_card.dart';
import '../data/sample_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/game_screen.dart';

class ContentScreen extends StatefulWidget {
  final ContentType type;
  final bool isMale;

  const ContentScreen({
    Key? key,
    required this.type,
    required this.isMale,
  }) : super(key: key);

  @override
  State<ContentScreen> createState() => ContentScreenState();
}

class ContentScreenState extends State<ContentScreen> {
  late Future<List<ContentItem>> _itemsFuture;
  int _currentPage = 0;
  final int _itemsPerPage = 9;
  late PageController _pageController;
  OverlayEntry? _activeOverlay;
  List<String> _completedLevels = [];
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadItems();
    _loadCompletedLevels();
    _pageController = PageController(initialPage: _currentPage);
    _calculateAndSaveCharisma();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _activeOverlay?.remove();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadItems() {
    switch (widget.type) {
      case ContentType.model:
        _itemsFuture = SampleData.getModelItems(widget.isMale);
        break;
      case ContentType.anime:
        _itemsFuture = SampleData.getAnimeItems(widget.isMale);
        break;
      case ContentType.karakter:
        _itemsFuture = SampleData.getKarakterItems(widget.isMale);
        break;
      case ContentType.dialog:
        _itemsFuture = Future.value([]); // Dialog oyunu için boş liste
        break;
    }
  }

  Future<void> _loadCompletedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final allCompletedLevels = prefs.getStringList('completedLevels') ?? [];
    final gender = widget.isMale ? 'male' : 'female';
    setState(() {
      _completedLevels = allCompletedLevels.where((levelId) => levelId.startsWith(gender)).toList();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCompletedLevels();
  }

  bool _isLevelLocked(int level) {
    if (level == 1) return false;
    final gender = widget.isMale ? 'male' : 'female';
    final previousLevelId = '${gender}_${widget.type.name}_${(level - 1).toString().padLeft(2, '0')}';
    return !_completedLevels.contains(previousLevelId);
  }

  bool _isLevelCompleted(int level) {
    final gender = widget.isMale ? 'male' : 'female';
    final levelId = '${gender}_${widget.type.name}_${level.toString().padLeft(2, '0')}';
    return _completedLevels.contains(levelId);
  }

  void _showLockedLevelDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.type.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_rounded,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bu bölüm kilitli!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bir önceki bölümü bitirmelisin',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Karizma ile açma özelliği eklenecek
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Karizma İle Aç',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Geri Dön',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage(int totalItems) {
    final int totalPages = (totalItems / _itemsPerPage).ceil();
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<int> _getLevelHearts(int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gender = widget.isMale ? 'male' : 'female';
      final type = widget.type.toString().split('.').last.toLowerCase();
      final levelId = '${gender}_${type}_${level.toString().padLeft(2, '0')}';
      final heartKey = '${levelId}_hearts';
      
      print('ContentScreen - Kalp Okuma:');
      print('Level ID: $levelId');
      print('Heart Key: $heartKey');
      print('Tüm kayıtlı anahtarlar: ${prefs.getKeys().toList()}');
      
      if (prefs.containsKey(heartKey)) {
        final hearts = prefs.getInt(heartKey);
        print('Okunan kalp sayısı: $hearts');
        return hearts ?? 5;
      } else {
        print('Kalp anahtarı bulunamadı: $heartKey');
        return 5;
      }
    } catch (e) {
      print('Kalp okuma hatası: $e');
      return 5;
    }
  }

  // Toplam kalpleri hesaplayan metod
  Future<int> _calculateTotalHearts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gender = widget.isMale ? 'male' : 'female';
      final type = widget.type.toString().split('.').last.toLowerCase();
      int totalHearts = 0;

      // Tüm kayıtlı anahtarları kontrol et
      final allKeys = prefs.getKeys();
      final heartKeys = allKeys.where((key) => 
        key.startsWith('${gender}_${type}') && key.endsWith('_hearts')
      );

      // Her anahtardan kalp sayısını oku ve topla
      for (final key in heartKeys) {
        final hearts = prefs.getInt(key) ?? 0;
        totalHearts += hearts;
      }

      return totalHearts;
    } catch (e) {
      print('Toplam kalp hesaplama hatası: $e');
      return 0;
    }
  }

  // Karizma puanını hesaplayan ve kaydeden metod
  Future<void> _calculateAndSaveCharisma() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gender = widget.isMale ? 'male' : 'female';
      final type = widget.type.toString().split('.').last.toLowerCase();
      int totalCharisma = 0;

      // Tüm kayıtlı kalp anahtarlarını kontrol et
      final allKeys = prefs.getKeys();
      final heartKeys = allKeys.where((key) => 
        key.startsWith('${gender}_${type}') && key.endsWith('_hearts')
      );

      // Her bölümdeki kalp sayısını al ve karizma puanını hesapla (her kalp 5 puan)
      for (final key in heartKeys) {
        final hearts = prefs.getInt(key) ?? 0;
        totalCharisma += hearts * 5;
      }

      // Karizma puanını kaydet
      final charismaKey = '${gender}_${type}_charisma';
      await prefs.setInt(charismaKey, totalCharisma);
      print('Karizma puanı kaydedildi: $totalCharisma (Key: $charismaKey)');
    } catch (e) {
      print('Karizma hesaplama hatası: $e');
    }
  }

  // Karizma puanını okuyan metod
  Future<int> _getCharismaPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gender = widget.isMale ? 'male' : 'female';
      final type = widget.type.toString().split('.').last.toLowerCase();
      final charismaKey = '${gender}_${type}_charisma';
      
      // Önce puanı hesapla ve kaydet
      await _calculateAndSaveCharisma();
      
      // Sonra kaydedilen puanı oku
      final charisma = prefs.getInt(charismaKey) ?? 0;
      print('Okunan karizma puanı: $charisma (Key: $charismaKey)');
      return charisma;
    } catch (e) {
      print('Karizma okuma hatası: $e');
      return 0;
    }
  }

  // Bir sayfa için gereken minimum kalp sayısını hesaplar
  int _getRequiredHeartsForPage(int pageNumber) {
    if (pageNumber <= 0) return 0; // İlk sayfa için kalp gerekmez
    // Önceki sayfaların toplam bölüm sayısı x ortalama kalp sayısı (3)
    return pageNumber * _itemsPerPage * 3;
  }

  // Oyuncunun toplam kalplerini kontrol eder ve yeterli mi değil mi bakar
  Future<bool> _hasEnoughHeartsForPage(int pageNumber) async {
    if (pageNumber == 0) return true; // İlk sayfa her zaman açık
    final totalHearts = await _calculateTotalHearts();
    final requiredHearts = _getRequiredHeartsForPage(pageNumber);
    return totalHearts >= requiredHearts;
  }

  // Eksik kalp sayısını hesaplar
  Future<int> _getMissingHeartsCount(int pageNumber) async {
    final totalHearts = await _calculateTotalHearts();
    final requiredHearts = _getRequiredHeartsForPage(pageNumber);
    return requiredHearts - totalHearts;
  }

  // Yeni uyarı dialogu
  void _showInsufficientHeartsDialog(int pageNumber, int missingHearts) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.type.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_border,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Yetersiz Kalp!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Bu bölümü oynamak için önceki bölümlerden\n$missingHearts kalp daha toplamanız gerekiyor.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Anladım',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPages(List<ContentItem> allItems) {
    final int totalPages = (allItems.length / _itemsPerPage).ceil();
    final pages = List.generate(totalPages, (pageIndex) {
      final startIndex = pageIndex * _itemsPerPage;
      final endIndex = (startIndex + _itemsPerPage) > allItems.length
          ? allItems.length
          : startIndex + _itemsPerPage;
      final pageItems = allItems.sublist(startIndex, endIndex);

      return Center(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: pageItems.length,
          itemBuilder: (context, index) {
            final item = pageItems[index];
            final isLocked = _isLevelLocked(item.level);
            final isCompleted = _isLevelCompleted(item.level);
            
            return FutureBuilder<int>(
              future: _getLevelHearts(item.level),
              builder: (context, snapshot) {
                final hearts = snapshot.data ?? 5;
                
                return GestureDetector(
                  onTap: isLocked ? () => _showLockedLevelDialog() : null,
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: isLocked ? 0.5 : 1.0,
                        child: ContentCard(
                          item: item,
                          onTap: isLocked 
                            ? () => _showLockedLevelDialog() 
                            : null,
                          isMale: widget.isMale,
                          isLocked: isLocked,
                          isCompleted: isCompleted,
                          remainingHearts: hearts,
                        ),
                      ),
                      if (isLocked)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    });

    return PageView(
      controller: _pageController,
      onPageChanged: (page) {
        setState(() => _currentPage = page);
      },
      children: pages,
    );
  }

  // Aktif overlay'i kaydetmek için metod
  void setActiveOverlay(OverlayEntry? overlay) {
    _activeOverlay = overlay;
  }

  // Oyunu başlatmak için public metod
  Future<bool> checkAndStartGame(ContentItem item) async {
    final currentPage = (item.level - 1) ~/ _itemsPerPage;
    
    if (await _hasEnoughHeartsForPage(currentPage)) {
      // Oyun türünü belirle
      final gameType = getGameTypeForLevel(item.level);
      
      // Oyunu başlat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameScreen(
              item: item,
              isMale: widget.isMale,
              gameType: gameType,
            ),
          ),
        );
      }
      return true;
    } else {
      final missingHearts = await _getMissingHeartsCount(currentPage);
      _showInsufficientHeartsDialog(currentPage, missingHearts);
      return false;
    }
  }

  // Bölüm numarasına göre oyun türünü belirleyen metod
  GameType getGameTypeForLevel(int level) {
    // Her sayfada 9 bölüm var
    // Her satırda 3 bölüm var
    // Satırdaki pozisyonu hesapla (0, 1 veya 2)
    int positionInRow = (level - 1) % 3;
    
    switch (positionInRow) {
      case 0: // 1., 4., 7. bölümler (her satırın ilk bölümü)
        return GameType.dialog;
      case 1: // 2., 5., 8. bölümler (her satırın ortasındaki bölüm)
        return GameType.imageReveal;
      case 2: // 3., 6., 9. bölümler (her satırın son bölümü)
        return GameType.matching;
      default:
        return GameType.dialog; // Varsayılan olarak diyalog oyunu
    }
  }

  // Aktif overlay'i kapatmak için metod
  Future<bool> closeActiveOverlay() async {
    if (_activeOverlay != null) {
      _activeOverlay?.remove();
      _activeOverlay = null;
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _loadCompletedLevels();
        }
      },
      child: WillPopScope(
        onWillPop: () async {
          if (_activeOverlay != null) {
            _activeOverlay?.remove();
            _activeOverlay = null;
            return false;
          }
          // Ana sayfaya dön
          Navigator.of(context).popUntil((route) => route.isFirst);
          return false;
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Text(
              widget.type.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: widget.type.color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () async {
                if (!await closeActiveOverlay()) {
                  return;
                }
                // Ana sayfaya dön
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: FutureBuilder<List<ContentItem>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Hata oluştu: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'İçerik bulunamadı',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final allItems = snapshot.data!;
                final totalPages = (allItems.length / _itemsPerPage).ceil();
                
                return Column(
                  children: [
                    const SizedBox(height: 100),
                    
                    // Kalp ve Karizma bilgileri
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Toplam Kalp
                          FutureBuilder<int>(
                            future: _calculateTotalHearts(),
                            builder: (context, snapshot) {
                              final totalHearts = snapshot.data ?? 0;
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Toplam Kalp:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    totalHearts.toString(),
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          
                          // Karizma
                          FutureBuilder<int>(
                            future: _getCharismaPoints(),
                            builder: (context, snapshot) {
                              final charisma = snapshot.data ?? 0;
                              return Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Karizma:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    charisma.toString(),
                                    style: TextStyle(
                                      color: Colors.amber.shade400,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: _buildPages(allItems),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'Sayfa ${_currentPage + 1}/$totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _currentPage > 0 ? _previousPage : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.type.color.withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_back_ios, size: 16),
                                    SizedBox(width: 4),
                                    Text('Geri'),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(width: 20),
                              
                              ElevatedButton(
                                onPressed: _currentPage < totalPages - 1 ? () => _nextPage(allItems.length) : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.type.color.withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Text('İleri'),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_ios, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
} 