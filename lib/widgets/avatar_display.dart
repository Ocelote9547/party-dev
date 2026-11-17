import 'package:flutter/material.dart';

import '../models/avatar.dart';
import '../theme/party_theme.dart';
import 'avatar_painter.dart';

/// Widget reutilizable y pulido para mostrar un avatar con offsets y escalas.
/// Usa Stack con Positioned + Transform para cada capa.
class AvatarDisplay extends StatelessWidget {
  final AvatarData avatar;
  final double size;
  final bool showBorder;
  final bool showShadow;

  const AvatarDisplay({
    super.key,
    required this.avatar,
    this.size = 48,
    this.showBorder = true,
    this.showShadow = true,
  });

  double _px(double normalized) => AvatarData.offsetToPixels(normalized, size);

  Widget _buildAccessory({
    required String value,
    required double offsetX,
    required double offsetY,
    required double scale,
    required double baseY,
    required double fontSize,
    required double iconSize,
  }) {
    if (value.isEmpty) return const SizedBox.shrink();
    final bool isVec = AvatarOptions.isVector(value);
    final double dx = _px(offsetX);
    final double dy = _px(offsetY);

    Widget child;
    if (isVec) {
      final icon = AvatarOptions.iconFor(value);
      // Vectorial: ShaderMask con gradient primary→accent y size: 28*scale
      child = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1),
        ),
        child: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [PartyColors.primary, PartyColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Icon(
            icon,
            size: 28 * scale,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    } else {
      // Emoji con sombra pulida
      child = Text(
        value,
        style: TextStyle(
          fontSize: fontSize,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
    }

    return Transform.translate(
      offset: Offset(dx, dy + baseY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: isVec
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AvatarOptions.gradientFor(avatar.bgGradientId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        // Anillo exterior 3px white + sombra primary para resaltar sobre degradado
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 3,
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: PartyColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: Offset(0, size * 0.08),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brillo especular superior (blanco 30%)
            Positioned(
              top: size * 0.07,
              left: size * 0.16,
              child: Container(
                width: size * 0.42,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
            // Cara base: foto IA (Image.asset ClipOval cover) o vectorial.
            // Aplica faceOffset/faceScale del editor (recortado por el óvalo).
            Center(
              child: Transform.translate(
                offset: Offset(_px(avatar.faceOffsetX), _px(avatar.faceOffsetY)),
                child: Transform.scale(
                  scale: avatar.faceScale,
                  child: AvatarFaceView(
                    faceId: avatar.baseFace,
                    assetPath: avatar.assetPath,
                    size: size * 0.76,
                  ),
                ),
              ),
            ),
            // Sombrero
            _buildAccessory(
              value: avatar.hat,
              offsetX: avatar.hatOffsetX,
              offsetY: avatar.hatOffsetY,
              scale: avatar.hatScale,
              baseY: -size * 0.33,
              fontSize: size * 0.30,
              iconSize: 28 * avatar.hatScale,
            ),
            // Gafas
            _buildAccessory(
              value: avatar.glasses,
              offsetX: avatar.glassesOffsetX,
              offsetY: avatar.glassesOffsetY,
              scale: avatar.glassesScale,
              baseY: -size * 0.02,
              fontSize: size * 0.28,
              iconSize: 28 * avatar.glassesScale,
            ),
            // Máscara
            _buildAccessory(
              value: avatar.mask,
              offsetX: avatar.maskOffsetX,
              offsetY: avatar.maskOffsetY,
              scale: avatar.maskScale,
              baseY: size * 0.24,
              fontSize: size * 0.24,
              iconSize: 28 * avatar.maskScale,
            ),
            // Borde interior sutil
            if (showBorder)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1,
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

/// Variante interactiva para el editor: permite arrastrar con GestureDetector.
class DraggableAvatarPreview extends StatelessWidget {
  final AvatarData avatar;
  final double size;
  final ValueChanged<AvatarData> onChanged;

  const DraggableAvatarPreview({
    super.key,
    required this.avatar,
    required this.onChanged,
    this.size = 160,
  });

  double _clampOffset(double v) => v.clamp(-0.5, 0.5).toDouble();

  @override
  Widget build(BuildContext context) {
    Widget draggableLayer({
      required String value,
      required double offX,
      required double offY,
      required double scale,
      required double baseY,
      required void Function(double dx, double dy) onPan,
    }) {
      if (value.isEmpty) return const SizedBox.shrink();
      final bool isVec = AvatarOptions.isVector(value);
      final double dx = AvatarData.offsetToPixels(offX, size);
      final double dy = AvatarData.offsetToPixels(offY, size);

      Widget content;
      if (isVec) {
        final icon = AvatarOptions.iconFor(value);
        content = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.20), blurRadius: 8, offset: const Offset(0, 2)),
            ],
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [PartyColors.primary, PartyColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: Icon(icon, size: 28 * scale, color: Colors.white),
          ),
        );
      } else {
        content = Text(
          value,
          style: TextStyle(
            fontSize: size * 0.30,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.26), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
        );
      }

      return Transform.translate(
        offset: Offset(dx, dy + baseY),
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (d) {
              final nx = _clampOffset(offX + d.delta.dx / 60);
              final ny = _clampOffset(offY + d.delta.dy / 60);
              onPan(nx, ny);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.0)),
              ),
              child: content,
            ),
          ),
        ),
      );
    }

    final gradient = AvatarOptions.gradientFor(avatar.bgGradientId);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: PartyColors.primary.withValues(alpha: 0.3), blurRadius: 12),
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: Offset(0, size * 0.08)),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Brillo especular 30%
            Positioned(
              top: size * 0.09,
              left: size * 0.18,
              child: Container(
                width: size * 0.40,
                height: size * 0.20,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(size),
                ),
              ),
            ),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (d) {
                  final nx = _clampOffset(
                      avatar.faceOffsetX + d.delta.dx / 60);
                  final ny = _clampOffset(
                      avatar.faceOffsetY + d.delta.dy / 60);
                  onChanged(avatar.copyWith(
                      faceOffsetX: nx, faceOffsetY: ny));
                },
                child: Transform.translate(
                  offset: Offset(
                    AvatarData.offsetToPixels(avatar.faceOffsetX, size),
                    AvatarData.offsetToPixels(avatar.faceOffsetY, size),
                  ),
                  child: Transform.scale(
                    scale: avatar.faceScale,
                    child: AvatarFaceView(
                      faceId: avatar.baseFace,
                      assetPath: avatar.assetPath,
                      size: size * 0.76,
                    ),
                  ),
                ),
              ),
            ),
            draggableLayer(
              value: avatar.hat,
              offX: avatar.hatOffsetX,
              offY: avatar.hatOffsetY,
              scale: avatar.hatScale,
              baseY: -size * 0.34,
              onPan: (nx, ny) => onChanged(avatar.copyWith(hatOffsetX: nx, hatOffsetY: ny)),
            ),
            draggableLayer(
              value: avatar.glasses,
              offX: avatar.glassesOffsetX,
              offY: avatar.glassesOffsetY,
              scale: avatar.glassesScale,
              baseY: -size * 0.01,
              onPan: (nx, ny) => onChanged(avatar.copyWith(glassesOffsetX: nx, glassesOffsetY: ny)),
            ),
            draggableLayer(
              value: avatar.mask,
              offX: avatar.maskOffsetX,
              offY: avatar.maskOffsetY,
              scale: avatar.maskScale,
              baseY: size * 0.26,
              onPan: (nx, ny) => onChanged(avatar.copyWith(maskOffsetX: nx, maskOffsetY: ny)),
            ),
          ],
        ),
      ),
    );
  }
}
