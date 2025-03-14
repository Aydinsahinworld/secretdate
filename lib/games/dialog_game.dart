import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_interface.dart';
import '../models/dialog_game_data.dart';
import '../models/content_item.dart';
import '../models/player_gender.dart';
import '../screens/content_screen.dart';
import '../screens/game_screen.dart';

class DialogGame extends StatefulWidget implements GameInterface {
  final List<DialogQuestion> questions;
  final ContentType type;
  final Function(double) onBlurLevelChanged;
  final Function(bool) onGameComplete;
  final bool isMale;

  const DialogGame({
    Key? key,
    required this.questions,
    required this.type,
    required this.onBlurLevelChanged,
    required this.onGameComplete,
    required this.isMale,
  }) : super(key: key);

  @override
  State<DialogGame> createState() => _DialogGameState();

  @override
  Future<void> initialize() async {
    // Boş bırak, state'de initialize edilecek
  }

  @override
  void update() {
    final state = _dialogGameKey.currentState;
    if (state != null) {
      state._updateProgress();
    }
  }

  @override
  void disposeGame() {
    // Boş bırak, state'de dispose edilecek
  }

  @override
  Widget buildGame(BuildContext context) {
    return this;
  }

  @override
  double getProgress() {
    final state = _dialogGameKey.currentState;
    if (state != null) {
      return state._currentQuestionIndex / state.widget.questions.length;
    }
    return 0.0;
  }

  @override
  bool isGameComplete() {
    final state = _dialogGameKey.currentState;
    if (state != null) {
      return state._isGameOver || state._isGameWon;
    }
    return false;
  }

  @override
  int getRemainingHearts() {
    final state = _dialogGameKey.currentState;
    if (state != null) {
      return state._remainingHearts;
    }
    return 0;
  }

  static final GlobalKey<_DialogGameState> _dialogGameKey = GlobalKey<_DialogGameState>();
}

class _DialogGameState extends State<DialogGame> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int _remainingHearts = 5;
  bool _isGameOver = false;
  bool _isGameWon = false;
  bool _isInitialized = false;
  List<AnimationController> _heartControllers = [];
  List<bool> _heartVisibility = List.filled(5, true);

  @override
  void initState() {
    super.initState();
    _initialize();
    // Her kalp için bir animasyon controller oluştur
    _heartControllers = List.generate(
      5,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _initialize() async {
    if (!mounted) return;
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    for (var controller in _heartControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _animateHeartBreak(int heartIndex) async {
    setState(() {
      _heartVisibility[heartIndex] = false;
    });
    await _heartControllers[heartIndex].forward();
  }

  void _updateProgress() {
    if (!mounted) return;
    // Bulanıklık sadece oyun devam ederken ve doğru cevap verildiğinde değişecek
    if (!_isGameOver && !_isGameWon) {
      final progress = _currentQuestionIndex / widget.questions.length;
      widget.onBlurLevelChanged(10.0 * (1 - progress));
    }
  }

  void _handleAnswer(String selectedAnswer) async {
    if (!mounted) return;

    final currentQuestion = widget.questions[_currentQuestionIndex];
    final isCorrect = selectedAnswer == currentQuestion.correctAnswer;
    final isLastQuestion = _currentQuestionIndex == widget.questions.length - 1;

    if (isLastQuestion && _remainingHearts > 0) {
      // Son soruda ve can varsa, cevap yanlış olsa bile oyunu başarılı say
      setState(() {
        _isGameWon = true;
        widget.onBlurLevelChanged(0.0);
        widget.onGameComplete(true);
      });

      // Kalpleri hemen kaydet
      try {
        final prefs = await SharedPreferences.getInstance();
        final gender = widget.isMale ? 'male' : 'female';
        final type = widget.type.toString().split('.').last.toLowerCase();
        
        // ContentItem'dan level bilgisini al
        final gameScreen = context.findAncestorWidgetOfExactType<GameScreen>();
        if (gameScreen != null) {
          final level = gameScreen.item.level;
          final levelId = '${gender}_${type}_${level.toString().padLeft(2, '0')}';
          final heartKey = '${levelId}_hearts';
          
          print('Kalp Kaydetme (handleAnswer):');
          print('Level ID: $levelId');
          print('Heart Key: $heartKey');
          print('Kaydedilecek kalp sayısı: $_remainingHearts');
          
          await prefs.setInt(heartKey, _remainingHearts);
          
          // Kayıt başarılı mı kontrol et
          final savedHearts = prefs.getInt(heartKey);
          print('Kontrol - Kaydedilen kalp sayısı: $savedHearts');
          print('Tüm kayıtlı anahtarlar: ${prefs.getKeys().toList()}');
          
          if (savedHearts != _remainingHearts) {
            print('HATA: Kalp sayısı doğru kaydedilemedi!');
            print('Beklenen: $_remainingHearts, Kaydedilen: $savedHearts');
          }
        }
      } catch (e) {
        print('Kalp kaydetme hatası: $e');
      }
      return;
    }

    if (!isCorrect) {
      _animateHeartBreak(_remainingHearts - 1);
      setState(() {
        _remainingHearts--;
        if (_remainingHearts <= 0) {
          _isGameOver = true;
          widget.onGameComplete(false);
        } else if (!isLastQuestion) {
          // Son soru değilse ve can varsa sonraki soruya geç
          _currentQuestionIndex++;
        }
      });
    } else {
      setState(() {
        if (isLastQuestion) {
          _isGameWon = true;
          widget.onBlurLevelChanged(0.0);
          widget.onGameComplete(true);
        } else {
          _currentQuestionIndex++;
          _updateProgress(); // Sadece doğru cevapta bulanıklık güncellenir
        }
      });
    }
  }

  void _resetGame() {
    setState(() {
      _currentQuestionIndex = 0;
      _remainingHearts = 5;
      _isGameOver = false;
      _isGameWon = false;
      
      // Kalpleri sıfırla
      _heartVisibility = List.filled(5, true);
      for (var controller in _heartControllers) {
        controller.reset();
      }
      
      // Bulanıklık değerini güncelleme
      _updateProgress();
    });
  }

  Widget _buildHeart(int index) {
    return AnimatedOpacity(
      opacity: _heartVisibility[index] ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: RotationTransition(
        turns: Tween(begin: 0.0, end: 0.1)
          .animate(CurvedAnimation(
            parent: _heartControllers[index],
            curve: Curves.easeInOut,
          )),
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 0.0)
            .animate(CurvedAnimation(
              parent: _heartControllers[index],
              curve: Curves.easeInOut,
            )),
          child: Stack(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 48,
              ),
              if (!_heartVisibility[index])
                CustomPaint(
                  size: const Size(48, 48),
                  painter: CrackPainter(
                    progress: _heartControllers[index].value,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isGameOver || _isGameWon) {
      return _buildGameOverScreen();
    }

    final currentQuestion = widget.questions[_currentQuestionIndex];
    
    return Column(
      children: [
        // Kalpler
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildHeart(index),
                );
              }),
            ),
          ),
        ),

        const Spacer(),

        // Soru kartı
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 20),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İpucu
              if (currentQuestion.hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      currentQuestion.hint!,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

              // Soru
              Text(
                currentQuestion.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Seçenekler
              ...currentQuestion.choices.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(entry.key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type.color.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverScreen() {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContentScreen(
              type: widget.type,
              isMale: widget.isMale,
            ),
          ),
        );
        return false;
      },
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.type.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isGameWon ? 'Tebrikler!' : 'Oyun Bitti!',
                style: TextStyle(
                  color: _isGameWon ? Colors.green : Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isGameWon
                    ? 'Gönlümü kazandın.\nBeni Arşiv\'de bulabilirsin'
                    : 'Üzgünüm, tüm haklarınızı kullandınız.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isGameWon) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_remainingHearts, (index) => 
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kalan Kalpler: $_remainingHearts',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 30),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _resetGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.type.color.withOpacity(0.3),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'TEKRAR OYNA',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ContentScreen(
                                type: widget.type,
                                isMale: widget.isMale,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'GERİ DÖN',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CrackPainter extends CustomPainter {
  final double progress;

  CrackPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Çatlak efekti çiz
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    path.lineTo(size.width * 0.4, size.height * 0.9);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = Path();
    extractPath.addPath(
      pathMetrics.extractPath(0, pathMetrics.length * progress),
      Offset.zero,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(CrackPainter oldDelegate) => progress != oldDelegate.progress;
} 