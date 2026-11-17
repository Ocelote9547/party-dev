// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../data/game_data.dart';
import '../services/feedback_service.dart';
import '../services/sound_service.dart';
import '../theme/party_theme.dart';
import '../widgets/game_instructions.dart';

import 'game_utils.dart';
import '../widgets/animated_party_background.dart';
import '../services/economy_service.dart';

enum _Phase { instructions, setup, wordPreview, drawing, gameOver }

class _Stroke {
  final Color color;
  final List<Offset> points;
  final double strokeWidth;
  _Stroke({required this.color, required this.points, required this.strokeWidth});
}

class _LiveStroke {
  _Stroke? stroke;
}

class DibujaYadivinaGame extends StatefulWidget {
  final List<String> players;
  const DibujaYadivinaGame({super.key, required this.players});

  @override
  State<DibujaYadivinaGame> createState() => _DibujaYadivinaGameState();
}

class _DibujaYadivinaGameState extends State<DibujaYadivinaGame> {
  static const int _secondsPerTurn = 60;

  _Phase _phase = _Phase.instructions;

  int _rounds = 1;
  int _currentRound = 1;
  int _currentPlayerIndex = 0;
  late List<String> _order;
  final List<_DrawingEntry> _gallery = [];
  final Map<String, int> _scores = {};
  bool _economyAwarded = false;

  Future<void> _handleGameCompleted() async {
    if (_economyAwarded) return;
    _economyAwarded = true;
    await EconomyService.instance.onGameCompleted();
  }

  String _word = '';
  int _secondsLeft = _secondsPerTurn;
  Timer? _timer;
  bool _turnActive = false;

  final GlobalKey _canvasKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  Color _currentColor = const Color(0xFF000000);
  bool _eraserLarge = false;
  ui.Picture? _completedPicture;
  final _LiveStroke _live = _LiveStroke();

  double _strokeWidthFor(Color c) =>
      (c == Colors.white && _eraserLarge) ? 16 : 6;

  String get _actor {
    if (_order.isEmpty) return 'Jugador';
    return _order[_currentPlayerIndex];
  }

  @override
  void initState() {
    super.initState();
    try { SoundService.instance.playAmbientLoop(category: 'PALABRAS'); } catch (_) {}
    _order = List.of(widget.players)..shuffle();
    for (final p in widget.players) {
      _scores[p] = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repaintNotifier.dispose();
    _completedPicture?.dispose();
    try { SoundService.instance.stopAmbient(); } catch (_) {}
    super.dispose();
  }

  @override
  void deactivate() {
    _timer?.cancel();
    super.deactivate();
  }

  void _startTurn() {
    _timer?.cancel();
    _strokes.clear();
    _live.stroke = null;
    _completedPicture?.dispose();
    _completedPicture = null;
    _word = _pickWord();
    _secondsLeft = _secondsPerTurn;
    setState(() => _phase = _Phase.wordPreview);
  }

  String _pickWord() {
    final words = List<String>.from(GameData.dibujaWords)..shuffle();
    return words.isEmpty ? 'Gato' : words.first;
  }

  void _enterDrawing() {
    setState(() => _phase = _Phase.drawing);
    _startTimer();
  }

  void _checkTick(int secondsLeft) {
    if (kDebugMode) debugPrint('[Dibuja] _checkTick $secondsLeft');
    if ([60, 30, 15].contains(secondsLeft) || (secondsLeft <= 10 && secondsLeft >= 0)) {
      SoundService.instance.playTick();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _turnActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_turnActive || _phase != _Phase.drawing) return;
      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        FeedbackService.countdownTick(0);
        _checkTick(0);
        _finishTurnNoHit();
        return;
      }
      setState(() => _secondsLeft--);
      FeedbackService.countdownTick(_secondsLeft);
      _checkTick(_secondsLeft);
    });
  }

  Future<void> _onSomeoneGuessed() async {
    _timer?.cancel();
    SoundService.instance.playSuccess();
    SoundService.instance.vibrateSuccess();
    final winner = await _showWhoGuessedDialog();
    if (!mounted) return;
    if (winner == null) {
      await _finishTurnNoHit();
      return;
    }
    await _saveDrawing();
    if (!mounted) return;
    setState(() {
      _scores[winner] = (_scores[winner] ?? 0) + 1;
    });
    _advanceTurn();
  }

  Future<void> _finishTurnNoHit() async {
    if (!_turnActive) return;
    _turnActive = false;
    _timer?.cancel();
    // Preguntar si alguien acertó al acabarse el tiempo
    final hit = await _showTimeoutGuessedDialog();
    if (!mounted) return;
    if (hit == true) {
      await _onSomeoneGuessed();
      return;
    }
    await _saveDrawing();
    if (!mounted) return;
    _advanceTurn();
  }

  Future<bool?> _showTimeoutGuessedDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: PartyColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('¿Alguien la ha adivinado?', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text)),
        content: Text('Se acabó el tiempo para «$_word»', textAlign: TextAlign.center, style: TextStyle(color: PartyColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('No', style: TextStyle(color: PartyColors.textSecondary, fontWeight: FontWeight.w800))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.success), child: const Text('Sí')),
        ],
      ),
    );
  }

  Future<void> _saveDrawing() async {
    try {
      // Asegurar que el frame haya pintado antes de capturar (108MP / web).
      await Future.delayed(const Duration(milliseconds: 20));
      final ro = _canvasKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) {
        if (kDebugMode) debugPrint('[Dibuja] _saveDrawing: boundary is not RenderRepaintBoundary ($ro)');
        return;
      }
      final boundary = ro;
      // Alta resolución: usa devicePixelRatio pero nunca por debajo de 3.0 para evitar pixelado.
      final deviceRatio = mounted ? MediaQuery.of(context).devicePixelRatio : 3.0;
      final effectiveRatio = deviceRatio >= 3.0 ? deviceRatio : 3.0;
      final image = await boundary.toImage(pixelRatio: effectiveRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) {
        if (kDebugMode) debugPrint('[Dibuja] _saveDrawing: byteData null');
        return;
      }
      if (!mounted) return;
      setState(() {
        _gallery.add(_DrawingEntry(
          player: _actor,
          word: _word,
          bytes: byteData.buffer.asUint8List(),
          capturedAt: DateTime.now(),
        ));
      });
      if (kDebugMode) debugPrint('[Dibuja] _saveDrawing ok gallery=${_gallery.length} ratio=$effectiveRatio');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Dibuja] _saveDrawing error: $e\n$st');
    }
  }

  void _advanceTurn() {
    _turnActive = false;
    _timer?.cancel();
    _currentPlayerIndex++;
    if (_currentPlayerIndex >= widget.players.length) {
      _currentPlayerIndex = 0;
      _currentRound++;
      if (_currentRound > _rounds) {
        setState(() => _phase = _Phase.gameOver);
        return;
      }
      _order = List.of(widget.players)..shuffle();
    }
    _startTurn();
  }

  Future<String?> _showWhoGuessedDialog() {
    final options = widget.players.where((p) => p != _actor).toList();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: PartyColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              Text(
                '¿Quién acertó?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 6),
              Text(
                '«$_word»',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textSecondary),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  for (final p in options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: PartyColors.border),
                        ),
                        tileColor: PartyColors.background,
                        title: Text(p, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: PartyColors.text)),
                        onTap: () => Navigator.pop(ctx, p),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: PartyColors.textSecondary,
                            side: BorderSide(color: PartyColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text('NADIE ACERTÓ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _undoStroke() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _rebakePicture();
  }

  void _clearCanvas() {
    _strokes.clear();
    _rebakePicture();
  }

  void _rebakePicture() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final stroke in _strokes) {
      _paintStroke(canvas, stroke);
    }
    final newPicture = recorder.endRecording();
    final oldPicture = _completedPicture;
    setState(() => _completedPicture = newPicture);
    oldPicture?.dispose();
  }

  Future<void> _downloadDrawing(_DrawingEntry entry) async {
    try {
      // Android 13+ : getExternalStorageDirectory es visible para el usuario;
      // en iOS/web cae a getApplicationDocumentsDirectory.
      Directory? dir;
      try {
        dir = await getExternalStorageDirectory();
      } catch (e) {
        if (kDebugMode) debugPrint('[Dibuja] getExternalStorageDirectory fallo: $e');
      }
      dir ??= await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/dibujo_${_timestamp(entry.capturedAt)}.png');
      await file.writeAsBytes(entry.bytes, flush: true);
      final exists = await file.exists();
      if (kDebugMode) debugPrint('[Dibuja] _downloadDrawing path=${file.path} exists=$exists bytes=${entry.bytes.length}');
      if (!exists) throw StateError('file not created: ${file.path}');
      // Intentar escanear en galería en Android (no rompe si no existe el canal)
      try {
        const MethodChannel('com.party/media_scanner').invokeMethod('scanFile', {'path': file.path});
      } catch (e) {
        if (kDebugMode) debugPrint('[Dibuja] media scan no disponible: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado en: ${file.path}')),
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[Dibuja] _downloadDrawing error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar la imagen.')),
      );
    }
  }

  String _timestamp(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)}'
        '_${two(t.hour)}-${two(t.minute)}-${two(t.second)}';
  }

    @override
  Widget build(BuildContext context) {
    if (widget.players.length < 3) return const NeedPlayersScreen(minPlayers: 3);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: PartyColors.surface,
            title: Text('¿Seguro que quieres salir?', style: TextStyle(color: PartyColors.text, fontWeight: FontWeight.w800)),
            content: Text('Perderás el progreso', style: TextStyle(color: PartyColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: PartyColors.danger), child: const Text('Salir')),
            ],
          ),
        );
        if (shouldPop == true) {
          _timer?.cancel();
          restoreOrientation();
          if (mounted) Navigator.pop(context);
        }
      },
      child: Builder(
        builder: (context) {

    final Widget screen;
    switch (_phase) {
      case _Phase.instructions:
        screen = _buildInstructions();
        break;
      case _Phase.setup:
        screen = _buildSetup();
        break;
      case _Phase.wordPreview:
        screen = _buildWordPreview();
        break;
      case _Phase.drawing:
        screen = _buildDrawing();
        break;
      case _Phase.gameOver:
        screen = _buildGameOver();
        break;
    }
    return Stack(
      children: [screen, const GameBackButton()],
    );
  
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return GameInstructions(
      emoji: '🎨',
      title: 'DIBUJA Y ADIVINA',
      subtitle: 'Dibuja sin hablar y deja que el grupo adivine.',
      steps: [
        'Se elige a un dibujante por turno (orden al azar).',
        'Solo el dibujante ve la palabra secreta.',
        'La dibuja con el dedo en 60 segundos SIN hablar ni escribir.',
        'Los demás gritan respuestas entre risas.',
        'Quien acierte suma +1 punto (lo confirma el dibujante).',
        'Si se acaba el tiempo sin acierto, nadie suma.',
        'Al final se guarda una galería con todos los dibujos.',
      ],
      onStart: () => setState(() => _phase = _Phase.setup),
    );
  }

  Widget _buildSetup() {
    if (_order.isEmpty) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        body: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Se necesitan jugadores — añade jugadores en JUGADORES', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: PartyColors.textSecondary)))),
      );
    }
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                '¿Cuántas RONDAS?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: PartyColors.text),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Cada jugador dibuja una vez por ronda.',
                style: TextStyle(fontSize: 14, color: PartyColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  for (int r = 1; r <= 3; r++) ...[
                    Expanded(child: _buildRoundOption(r)),
                    if (r < 3) const SizedBox(width: 12),
                  ],
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _startTurn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('EMPEZAR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundOption(int rounds) {
    final selected = _rounds == rounds;
    return Opacity(
      opacity: selected ? 1 : 0.55,
      child: ElevatedButton(
        onPressed: () => setState(() => _rounds = rounds),
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? PartyColors.primary.withValues(alpha: 0.18) : PartyColors.surface,
          foregroundColor: selected ? PartyColors.primary : PartyColors.text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: selected ? PartyColors.primary : PartyColors.border, width: selected ? 1.5 : 1),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: Column(
          children: [
            Text('$rounds', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(rounds == 1 ? 'RONDA' : 'RONDAS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildWordPreview() {
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🤫', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Turno de $_actor · Ronda $_currentRound/$_rounds',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                'Pasa el móvil a $_actor. Solo para sus ojos:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: PartyColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: PartyColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: PartyColors.primary, width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      'Tu palabra es:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: PartyColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_word 👀',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: PartyColors.text),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No se la digas a nadie ni escribas letras.',
                      style: TextStyle(fontSize: 13, color: PartyColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: _enterDrawing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('¡A DIBUJAR!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawing() {
    final lowTime = _secondsLeft <= 10;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: AnimatedPartyBackground(
          totalDuration: const Duration(seconds: _secondsPerTurn),
          child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$_actor · Ronda $_currentRound/$_rounds',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: PartyColors.textMuted, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (lowTime ? PartyColors.danger : PartyColors.primary).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '⏱ $_secondsLeft s',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: lowTime ? PartyColors.danger : PartyColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: PartyColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: RepaintBoundary(
                    key: _canvasKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        final stroke = _Stroke(
                            color: _currentColor,
                            points: [details.localPosition],
                            strokeWidth: _strokeWidthFor(_currentColor));
                        _live.stroke = stroke;
                        _strokes.add(stroke);
                        _repaintNotifier.value++;
                      },
                      onPanUpdate: (details) {
                        _live.stroke?.points.add(details.localPosition);
                        _repaintNotifier.value++;
                      },
                      onPanEnd: (_) {
                        _live.stroke = null;
                        _rebakePicture();
                      },
                      onPanCancel: () {
                        _live.stroke = null;
                        _rebakePicture();
                      },
                      child: CustomPaint(
                        painter: _CanvasPainter(
                          completed: _completedPicture,
                          live: _live,
                          repaint: _repaintNotifier,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildColorBar(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _undoStroke,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.textSecondary,
                        side: BorderSide(color: PartyColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('DESHACER', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearCanvas,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PartyColors.textSecondary,
                        side: BorderSide(color: PartyColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('LIMPIAR', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _onSomeoneGuessed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.success,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text('¡ALGUIEN ACERTÓ!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildColorBar() {
    final colors = [
      const Color(0xFF000000),
      const Color(0xFFE74C3C),
      const Color(0xFF3498DB),
      const Color(0xFF2ECC71),
      const Color(0xFFFACC15),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFF34495E),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFFFFF),
    ];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              for (int i = 0; i < colors.length; i++) ...[
                GestureDetector(
                  onTap: () => setState(() => _currentColor = colors[i]),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _currentColor == colors[i] ? PartyColors.primary : PartyColors.border,
                        width: _currentColor == colors[i] ? 3 : 1,
                      ),
                    ),
                    child: colors[i] == Colors.white
                        ? Center(
                            child: Icon(Icons.cleaning_services, size: 18, color: PartyColors.textMuted),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_currentColor == Colors.white) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _eraserLarge = false),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: !_eraserLarge ? PartyColors.primary : PartyColors.border,
                      width: !_eraserLarge ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: PartyColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _eraserLarge = true),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _eraserLarge ? PartyColors.primary : PartyColors.border,
                      width: _eraserLarge ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: PartyColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: PartyColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _eraserLarge ? 'BORRADOR GRANDE' : 'BORRADOR PEQUEÑO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: PartyColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGameOver() {
    final sorted = widget.players.toList()..sort((a, b) => (_scores[b] ?? 0).compareTo(_scores[a] ?? 0));
    final champion = sorted.isNotEmpty ? sorted.first : null;
    return Scaffold(
      backgroundColor: PartyColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
                champion == null ? 'DIBUJA Y ADIVINA' : '¡$champion gana!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: PartyColors.text),
              ),
              const SizedBox(height: 18),
              for (final p in sorted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: PartyColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p == champion ? PartyColors.primary : PartyColors.border, width: p == champion ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, color: PartyColors.text),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: PartyColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_scores[p] ?? 0} pts',
                            style: const TextStyle(color: PartyColors.primary, fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                '🎨 GALERÍA DE DIBUJOS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1, color: PartyColors.text),
              ),
              const SizedBox(height: 14),
              if (_gallery.isEmpty)
                Text(
                  'No hay dibujos aún.',
                  style: TextStyle(fontSize: 13, color: PartyColors.textMuted),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final entry in _gallery)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 140,
                            height: 170,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: PartyColors.border),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.memory(
                              entry.bytes,
                              width: 140,
                              height: 170,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              cacheWidth: 280,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 140,
                            child: Text(
                              '${entry.player} — ${entry.word}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () => _downloadDrawing(entry),
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('PNG', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PartyColors.primary,
                              side: BorderSide(color: PartyColors.border),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: const Size(140, 34),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () async {
                    await _handleGameCompleted();

                    await saveGameScores(_scores);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PartyColors.primary,
                    foregroundColor: PartyColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('VOLVER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawingEntry {
  final String player;
  final String word;
  final Uint8List bytes;
  final DateTime capturedAt;

  _DrawingEntry({
    required this.player,
    required this.word,
    required this.bytes,
    required this.capturedAt,
  });
}

class _CanvasPainter extends CustomPainter {
  final ui.Picture? completed;
  final _LiveStroke live;

  _CanvasPainter({
    required this.completed,
    required this.live,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo blanco puro siempre — el borrador (Colors.white) funciona porque borra sobre blanco.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );
    final pic = completed;
    if (pic != null) {
      canvas.drawPicture(pic);
    }
    final liveStroke = live.stroke;
    if (liveStroke != null) {
      _paintStroke(canvas, liveStroke);
    }
  }

  @override
  bool shouldRepaint(_CanvasPainter oldDelegate) {
    return oldDelegate.completed != completed || oldDelegate.live != live;
  }
}

void _paintStroke(Canvas canvas, _Stroke stroke) {
  // Borrador = Colors.white con strokeWidth 6/16 sobre fondo blanco puro (arriba).
  // Alternativa BlendMode.clear requeriría saveLayer; con fondo blanco, Colors.white es correcto y más eficiente.
  final paint = Paint()
    ..color = stroke.color
    ..strokeWidth = stroke.strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  if (stroke.points.length == 1) {
    canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
    return;
  }
  final path = Path()
    ..moveTo(stroke.points.first.dx, stroke.points.first.dy);
  for (int i = 1; i < stroke.points.length; i++) {
    path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
  }
  canvas.drawPath(path, paint);
}