import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/party_theme.dart';

/// Fondo B/N con patron de puntos/diagonales que es barrido de izquierda
/// a derecha por una barra que tiñe a color volcan (wipe).
/// - Fondo base B/N con patron (puntos cada 24px + diagonales).
/// - Overlay con [ClipRect] + [FractionallySizedBox(widthFactor: progress)] que muestra
///   el gradient volcan ([PartyColors.scaffoldGradient]) + patron teñido.
/// - [AnimationController] 10s que anima progress 0->1 y repite (compat).
/// - Si se pasa [totalDuration], la barra va 0→1 en ese tiempo con forward() una sola vez.
///   Si es null, repite indefinidamente con [cycleDuration] (por defecto 12s).
/// - Robusto en portrait y landscape: usa [LayoutBuilder] + [OrientationBuilder],
///   `Stack(fit: StackFit.expand)` y `FractionallySizedBox` cuyo widthFactor es
///   relativo al ancho físico (constraints.maxWidth), no al alto.
class AnimatedPartyBackground extends StatefulWidget {
  final Widget child;
  final Duration cycleDuration;
  final Duration? totalDuration;

  const AnimatedPartyBackground({
    super.key,
    required this.child,
    this.cycleDuration = const Duration(seconds: 12),
    this.totalDuration,
  });

  @override
  State<AnimatedPartyBackground> createState() =>
      _AnimatedPartyBackgroundState();
}

class _AnimatedPartyBackgroundState extends State<AnimatedPartyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Cache painters per theme to avoid rebuilding objects each frame.
  _DotGridPatternPainter? _basePainterCache;
  _DotGridPatternPainter? _tintedPainterCache;
  bool? _cachedIsDark;

  @override
  void initState() {
    super.initState();
    final duration = widget.totalDuration ?? widget.cycleDuration;
    _controller = AnimationController(vsync: this, duration: duration)..repeat();
  }

  @override
  void didUpdateWidget(covariant AnimatedPartyBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleDuration != widget.cycleDuration ||
        oldWidget.totalDuration != widget.totalDuration) {
      final newDuration = widget.totalDuration ?? widget.cycleDuration;
      _controller.duration = newDuration;
      // Reiniciar animacion para que el progreso sea coherente al cambiar de fase
      // (p. ej. Debate pasa de 60s -> null -> 60s en rondas sucesivas).
      _controller
        ..reset()
        ..repeat();
    }
    // Si totalDuration esta activo y el controller termino (caso forward anterior),
    // asegurar que siga animando.
    if (widget.totalDuration != null && !_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _basePainterCache?.disposePicture();
    _tintedPainterCache?.disposePicture();
    _controller.dispose();
    super.dispose();
  }

  _DotGridPatternPainter _getPainter(bool isDark, bool tinted) {
    if (_cachedIsDark != isDark) {
      _basePainterCache?.disposePicture();
      _tintedPainterCache?.disposePicture();
      _basePainterCache = null;
      _tintedPainterCache = null;
      _cachedIsDark = isDark;
    }
    if (tinted) {
      return _tintedPainterCache ??= _DotGridPatternPainter(isDark: isDark, tinted: true);
    }
    return _basePainterCache ??= _DotGridPatternPainter(isDark: isDark, tinted: false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final basePainter = _getPainter(isDark, false);
    final tintedPainter = _getPainter(isDark, true);
    // Crear el gradiente una sola vez por build, no en cada tick del AnimatedBuilder.
    final tintGradient = LinearGradient(
      begin: const Alignment(-1, -1),
      end: const Alignment(1, 1),
      colors: PartyColors.scaffoldGradient,
    );

    // LayoutBuilder + OrientationBuilder garantizan que widthFactor sea relativo
    // al ancho físico en ambas orientaciones (portrait / landscapeLeft).
    return LayoutBuilder(
      builder: (context, constraints) {
        return OrientationBuilder(
          builder: (context, orientation) {
            return Container(
              color: baseColor,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Capa base estática con RepaintBoundary para cachear raster.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: Container(color: baseColor),
                    ),
                  ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: basePainter,
                        isComplex: true,
                        willChange: false,
                      ),
                    ),
                  ),
                  // Overlay animado: solo este subtree se reconstruye cada tick.
                  // FractionallySizedBox asegura que progress sea relativo a maxWidth.
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final progress =
                              _controller.value.clamp(0.0, 1.0).toDouble();
                          return ClipRect(
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(gradient: tintGradient),
                                  ),
                                  Positioned.fill(
                                    child: RepaintBoundary(
                                      child: CustomPaint(
                                        painter: tintedPainter,
                                        isComplex: true,
                                        willChange: false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Contenido aislado en RepaintBoundary para no repintar fondo.
                  RepaintBoundary(child: widget.child),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Pinta patron en blanco y negro (base) o teñido volcan (overlay).
/// Hornea el patron en un [ui.Picture] la primera vez (y al cambiar de
/// tamaño) para que cada tick de la animación sea un solo `drawPicture`
/// en vez de cientos de drawCircle/drawLine.
class _DotGridPatternPainter extends CustomPainter {
  final bool isDark;
  final bool tinted;

  _DotGridPatternPainter({required this.isDark, required this.tinted});

  ui.Picture? _baked;
  Size? _bakedFor;

  void disposePicture() {
    _baked?.dispose();
    _baked = null;
    _bakedFor = null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_baked == null || _bakedFor != size) {
      _baked?.dispose();
      _bakedFor = size;
      final recorder = ui.PictureRecorder();
      _drawPattern(Canvas(recorder), size);
      _baked = recorder.endRecording();
    }
    final baked = _baked;
    if (baked != null) {
      canvas.drawPicture(baked);
    }
  }

  void _drawPattern(Canvas canvas, Size size) {
    final Color dotColor;
    final Color lineColor;

    if (!tinted) {
      // Base B/N
      dotColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
      lineColor = isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.black.withValues(alpha: 0.03);
    } else {
      // Overlay teñido volcan: puntos con tinte primary/accent
      dotColor = isDark
          ? PartyColors.primary.withValues(alpha: 0.18)
          : PartyColors.primary.withValues(alpha: 0.12);
      lineColor = isDark
          ? PartyColors.accentGreen.withValues(alpha: 0.10)
          : PartyColors.primaryLight.withValues(alpha: 0.08);
    }

    final dotPaint = Paint()..color = dotColor;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const gap = 24.0;
    const radius = 1.4;

    // Puntos
    for (double y = gap / 2; y < size.height + gap; y += gap) {
      for (double x = gap / 2; x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    // Lineas diagonales sutiles cada 48px
    const diagGap = 48.0;
    for (double offset = -size.height; offset < size.width; offset += diagGap) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.tinted != tinted;
}
