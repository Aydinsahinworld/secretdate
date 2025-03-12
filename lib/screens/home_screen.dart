import 'package:flutter/material.dart';
import '../data/sample_data.dart';
import '../models/content_item.dart';
import 'content_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _menuItems = [
    {
      'title': 'Ayarlar',
      'icon': Icons.settings,
    },
    {
      'title': 'Cinsiyet',
      'isGenderButton': true,
    },
    {
      'title': 'Pro',
      'icon': Icons.star_rounded,
    },
    {
      'title': 'Arşiv',
      'icon': Icons.photo_library_rounded,
    },
    {
      'title': 'Special',
      'icon': Icons.favorite_rounded,
    },
  ];

  // Basılı tutma durumlarını takip etmek için map
  final Map<int, bool> _isPressed = {};
  bool _isMaleSelected = false; // Varsayılan olarak kadın seçili
  bool _isFirstLaunch = true; // İlk açılışı takip etmek için

  @override
  void initState() {
    super.initState();
    _loadGenderPreference();
  }

  // Son seçilen cinsiyeti yükle
  Future<void> _loadGenderPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;
    
    if (isFirstLaunch) {
      // İlk açılışta kadın seçili olsun
      await prefs.setBool('is_first_launch', false);
      if (mounted) {
        setState(() {
          _isMaleSelected = false;
          _isFirstLaunch = false;
        });
      }
    } else {
      // Sonraki açılışlarda son seçilen cinsiyeti kullan
      final isMale = prefs.getBool('is_male_selected') ?? false;
      if (mounted) {
        setState(() {
          _isMaleSelected = isMale;
          _isFirstLaunch = false;
        });
      }
    }
  }

  // Cinsiyet seçimini kaydet
  Future<void> _saveGenderPreference(bool isMale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_male_selected', isMale);
  }

  // Aktif rengi döndüren getter
  Color get _activeColor => _isMaleSelected ? Colors.blue : Colors.pink;

  // Aktif resim yolunu döndüren metod
  String _getActiveImagePath(String type) {
    if (_isMaleSelected) {
      switch (type) {
        case 'MODEL':
          return 'assets/images/buttons/men_model.jpg';
        case 'ANİME':
          return 'assets/images/buttons/men_anime.jpg';
        case 'KARAKTER':
          return 'assets/images/buttons/men_karakter.jpg';
        default:
          return '';
      }
    } else {
      switch (type) {
        case 'MODEL':
          return 'assets/images/buttons/model.jpg';
        case 'ANİME':
          return 'assets/images/buttons/anime.jpg';
        case 'KARAKTER':
          return 'assets/images/buttons/karakter.jpg';
        default:
          return '';
      }
    }
  }

  void _toggleGender() {
    setState(() {
      _isMaleSelected = !_isMaleSelected;
    });
    _saveGenderPreference(_isMaleSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan resmi
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Neon Başlık
          Positioned(
            top: MediaQuery.of(context).size.height * 0.05,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'SECRET\u2004DATE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontFamily: 'Playball',
                  color: Colors.white,
                  shadows: [
                    // İç parlama efekti
                    Shadow(
                      color: _activeColor,
                      blurRadius: 0,
                      offset: const Offset(0, 0),
                    ),
                    // Dış parlama efekti 1
                    Shadow(
                      color: _activeColor,
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                    ),
                    // Dış parlama efekti 2
                    Shadow(
                      color: _activeColor,
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                    ),
                    // Dış parlama efekti 3
                    Shadow(
                      color: _activeColor,
                      blurRadius: 60,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Sol taraftaki kare butonlar
          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.2,
            child: Column(
              children: List.generate(
                _menuItems.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed[index] = true),
                    onTapUp: (_) {
                      setState(() => _isPressed[index] = false);
                      if (_menuItems[index]['isGenderButton'] == true) {
                        _toggleGender();
                      } else if (_menuItems[index]['title'] == 'Arşiv') {
                        _showArchiveModal();
                      }
                    },
                    onTapCancel: () => setState(() => _isPressed[index] = false),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 150),
                      scale: _isPressed[index] == true ? 0.95 : 1.0,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _activeColor.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            // İç parlama efekti
                            BoxShadow(
                              color: _activeColor.withOpacity(_isPressed[index] == true ? 0.4 : 0.3),
                              blurRadius: _isPressed[index] == true ? 8 : 6,
                              spreadRadius: _isPressed[index] == true ? 2 : 1,
                            ),
                            // Dış parlama efekti
                            BoxShadow(
                              color: _activeColor.withOpacity(_isPressed[index] == true ? 0.3 : 0.2),
                              blurRadius: _isPressed[index] == true ? 12 : 10,
                              spreadRadius: _isPressed[index] == true ? 3 : 2,
                            ),
                            // Çevreye yayılan ışık efekti
                            BoxShadow(
                              color: _activeColor.withOpacity(_isPressed[index] == true ? 0.15 : 0.1),
                              blurRadius: _isPressed[index] == true ? 18 : 15,
                              spreadRadius: _isPressed[index] == true ? 5 : 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_menuItems[index]['isGenderButton'] == true)
                              // Cinsiyet ikonları
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Erkek ikonu
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      Icons.male,
                                      color: Colors.white,
                                      size: _isMaleSelected ? 48 : 32,
                                      shadows: [
                                        Shadow(
                                          color: _activeColor.withOpacity(_isPressed[index] == true ? 0.6 : 0.5),
                                          blurRadius: _isPressed[index] == true ? 8 : 6,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Kadın ikonu
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    child: Icon(
                                      Icons.female,
                                      color: Colors.white,
                                      size: _isMaleSelected ? 32 : 48,
                                      shadows: [
                                        Shadow(
                                          color: _activeColor.withOpacity(_isPressed[index] == true ? 0.6 : 0.5),
                                          blurRadius: _isPressed[index] == true ? 8 : 6,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              Icon(
                                _menuItems[index]['icon'],
                                color: Colors.white,
                                size: 48,
                                shadows: [
                                  Shadow(
                                    color: Colors.pink.withOpacity(_isPressed[index] == true ? 0.6 : 0.5),
                                    blurRadius: _isPressed[index] == true ? 8 : 6,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).reversed.toList(),
            ),
          ),

          // Sağ taraftaki resimli butonlar
          Positioned(
            right: 30,
            top: MediaQuery.of(context).size.height * 0.2,
            child: Column(
              children: [
                // MODEL butonu
                _buildImageButton('MODEL', _getActiveImagePath('MODEL'), 0),
                
                // ANİME butonu
                _buildImageButton('ANİME', _getActiveImagePath('ANİME'), 1),
                
                // KARAKTER butonu
                _buildImageButton('KARAKTER', _getActiveImagePath('KARAKTER'), 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageButton(String title, String imagePath, int buttonIndex) {
    // Buton rengini belirle
    Color buttonColor;
    switch (title) {
      case 'MODEL':
        buttonColor = Colors.pink;
        break;
      case 'ANİME':
        buttonColor = Colors.purple;
        break;
      case 'KARAKTER':
        buttonColor = Colors.blue;
        break;
      default:
        buttonColor = Colors.red;
    }

    // Kadın ve erkek resim yollarını al
    String womenImagePath = 'assets/images/buttons/${title.toLowerCase()}.jpg';
    String menImagePath = 'assets/images/buttons/men_${title.toLowerCase()}.jpg';

    return Padding(
      padding: EdgeInsets.only(bottom: title != 'KARAKTER' ? 15 : 0),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed[buttonIndex + 100] = true),
        onTapUp: (_) {
          setState(() => _isPressed[buttonIndex + 100] = false);
          _navigateToContent(title);
        },
        onTapCancel: () => setState(() => _isPressed[buttonIndex + 100] = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isPressed[buttonIndex + 100] == true ? 0.97 : 1.0,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: buttonColor.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: buttonColor.withOpacity(_isPressed[buttonIndex + 100] == true ? 0.6 : 0.5),
                  blurRadius: _isPressed[buttonIndex + 100] == true ? 10 : 8,
                  spreadRadius: _isPressed[buttonIndex + 100] == true ? 3 : 2,
                ),
                BoxShadow(
                  color: buttonColor.withOpacity(_isPressed[buttonIndex + 100] == true ? 0.4 : 0.3),
                  blurRadius: _isPressed[buttonIndex + 100] == true ? 15 : 12,
                  spreadRadius: _isPressed[buttonIndex + 100] == true ? 5 : 4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Resim geçişi
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 500),
                    firstChild: _buildImageWithGradient(menImagePath),
                    secondChild: _buildImageWithGradient(womenImagePath),
                    crossFadeState: _isMaleSelected 
                      ? CrossFadeState.showFirst 
                      : CrossFadeState.showSecond,
                    firstCurve: Curves.easeInOut,
                    secondCurve: Curves.easeInOut,
                    sizeCurve: Curves.easeInOut,
                    layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
                      return Stack(
                        children: [
                          Positioned(
                            key: bottomChildKey,
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: bottomChild,
                          ),
                          Positioned(
                            key: topChildKey,
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: topChild,
                          ),
                        ],
                      );
                    },
                  ),

                  // Başlık
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Gradient ile resim oluşturan yardımcı metod
  Widget _buildImageWithGradient(String imagePath) {
    return Stack(
      children: [
        Image.asset(
          imagePath,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
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
      ],
    );
  }

  void _navigateToContent(String title) {
    late final ContentType type;

    switch (title) {
      case 'MODEL':
        type = ContentType.model;
        break;
      case 'ANİME':
        type = ContentType.anime;
        break;
      case 'KARAKTER':
        type = ContentType.karakter;
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentScreen(
          type: type,
          isMale: _isMaleSelected,
        ),
      ),
    );
  }

  // En alta eklenecek yeni metodlar
  void _showArchiveModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _getArchiveData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final completedLevels = snapshot.data!['levels'] as List<String>;
          final archiveImages = snapshot.data!['images'] as List<String>;
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: _activeColor.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _activeColor.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Başlık ve kapat butonu satırı
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _activeColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ARŞİV',
                        style: TextStyle(
                          color: _activeColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: _activeColor.withOpacity(0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _activeColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.close,
                            color: _activeColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Resim galerisi
                Padding(
                  padding: const EdgeInsets.only(top: 70),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: archiveImages.length,
                    itemBuilder: (context, index) {
                      final imagePath = archiveImages[index];
                      
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(context, imagePath),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _activeColor.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _activeColor.withOpacity(0.2),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.asset(
                              imagePath,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Resim yüklenemedi: $imagePath');
                                print('Hata: $error');
                                return Container(
                                  color: Colors.black,
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Arşiv verilerini getir
  Future<Map<String, dynamic>> _getArchiveData() async {
    final prefs = await SharedPreferences.getInstance();
    final allCompletedLevels = prefs.getStringList('completedLevels') ?? [];
    final allArchiveImages = prefs.getStringList('completed_images') ?? [];
    
    print('Tüm tamamlanan seviyeler: $allCompletedLevels');
    print('Tüm arşiv resimleri: $allArchiveImages');
    
    // Sadece seçili cinsiyete ait seviyeleri ve resimleri filtrele
    final gender = _isMaleSelected ? 'male' : 'female';
    final filteredLevels = allCompletedLevels.where((levelId) => levelId.startsWith(gender)).toList();
    
    // Resimleri cinsiyete göre filtrele
    final genderPath = _isMaleSelected ? '/men_' : '/';
    final filteredImages = allArchiveImages.where((imagePath) {
      // Erkek resimlerini kontrol et
      if (_isMaleSelected) {
        return imagePath.contains('/men_');
      }
      // Kadın resimlerini kontrol et (men_ içermeyenler)
      return !imagePath.contains('/men_');
    }).toList();
    
    print('Filtrelenmiş seviyeler: $filteredLevels');
    print('Filtrelenmiş resimler: $filteredImages');
    
    return {
      'levels': filteredLevels,
      'images': filteredImages,
    };
  }

  // Tam ekran resim görüntüleme
  void _showFullScreenImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Resim
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            // Kapat butonu
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 