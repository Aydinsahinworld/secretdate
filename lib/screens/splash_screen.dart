import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _logoFadeController;
  late AnimationController _characterController;
  late AnimationController _characterFadeController;
  late AnimationController _titleController;
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;
  bool _showStartButton = false;
  bool _showLoading = false;
  bool _showSecondLogo = false;  // İkinci logo için kontrol değişkeni

  @override
  void initState() {
    super.initState();

    // Logo animasyonları için controller'lar
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Animasyon süresini uzattım
    );
    _logoFadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Fade süresini uzattım
    );

    // Karakter resmi için controller'lar
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _characterFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Başlık animasyonu için controller
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Loading bar animasyonu için controller
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // Animasyon sıralaması
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Debug print ekledim
    debugPrint('Cosmic Game logosu yükleniyor...');
    
    // İlk logonun yüklendiğinden emin olmak için kısa bir bekleme
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 1. Cosmic Game logosu
    debugPrint('Logo animasyonu başlıyor...');
    _logoController.forward();
    await Future.delayed(const Duration(seconds: 4)); // 3 saniyeden 4 saniyeye çıkardım
    debugPrint('Logo 4 saniye bekledi, şimdi kaybolacak...');
    await _logoFadeController.forward();
    await Future.delayed(const Duration(seconds: 1)); // 500ms'den 1 saniyeye çıkardım

    // 2. Secret Date logosu
    debugPrint('Secret Date logosu yüklenecek...');
    setState(() {
      _showSecondLogo = true;
    });
    _characterController.forward();
    await Future.delayed(const Duration(seconds: 3));
    await _characterFadeController.forward();

    // 3. SECRET DATE yazısı
    await _titleController.forward();
    
    // 4. Loading bar'ı göster
    setState(() {
      _showLoading = true;
    });
    
    // 5. Loading animasyonu
    await _loadingController.forward();
    
    // 6. Başla butonu
    setState(() {
      _showStartButton = true;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _logoFadeController.dispose();
    _characterController.dispose();
    _characterFadeController.dispose();
    _titleController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161415),
      body: Stack(
        children: [
          // Cosmic Game Logo Animasyonu
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_logoFadeController),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1.2).animate( // Scale değerini artırdım
                CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/splash/cosmicgame.png',
                  width: 300, // Logo boyutunu büyüttüm
                  height: 300,
                ),
              ),
            ),
          ),

          // Secret Date Logo Animasyonu (sadece _showSecondLogo true olduğunda göster)
          if (_showSecondLogo)
            FadeTransition(
              opacity: Tween<double>(begin: 1.0, end: 0.0).animate(_characterFadeController),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                  CurvedAnimation(parent: _characterController, curve: Curves.easeOut),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/splash/secretdate.jpg',
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

          // Başlık ve Loading Bar
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SECRET DATE Yazısı
                FadeTransition(
                  opacity: _titleController,
                  child: const Text(
                    'SECRET DATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Playball',
                      fontSize: 58,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.pink,
                          blurRadius: 15,
                          offset: Offset(2, 2),
                        ),
                        Shadow(
                          color: Colors.red,
                          blurRadius: 10,
                          offset: Offset(-2, -2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                
                // Loading Bar
                if (_showLoading && !_showStartButton)
                  Center(
                    child: AnimatedBuilder(
                      animation: _loadingAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.pink),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _loadingAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: const LinearGradient(
                                  colors: [Colors.pink, Colors.red],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                
                // Giriş Butonu
                if (_showStartButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        backgroundColor: Colors.pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                        shadowColor: Colors.pink.withOpacity(0.5),
                      ),
                      child: const Text(
                        'GİRİŞ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 