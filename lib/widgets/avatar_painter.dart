import 'package:flutter/material.dart';

import '../models/avatar.dart';

/// Vista vectorial para una cara base.
/// Usa [CustomPaint] con fondo geométrico + [Icon] centrado,
/// nunca `Text` emoji.
/// Si hay [assetPath] o [faceId] es un slot custom (`custom_XX`),
/// renderiza `Image.asset` (ClipOval, fit cover) con fallback
/// al vectorial vía `errorBuilder` (nunca crashea si falta el PNG).
class AvatarFaceView extends StatelessWidget {
  final String faceId;
  final double size;
  final bool showHighlight;

  /// Ruta explícita de foto IA (ej. `assets/avatars/custom_01.png`).
  /// Si es null, se deriva de [faceId] si es slot custom.
  final String? assetPath;

  const AvatarFaceView({
    super.key,
    required this.faceId,
    required this.size,
    this.showHighlight = true,
    this.assetPath,
  });

  /// Ruta efectiva a intentar cargar. Null = solo vectorial.
  String? get _effectiveAssetPath {
    if (assetPath != null && assetPath!.isNotEmpty) return assetPath;
    return AvatarOptions.assetPathForFaceId(faceId);
  }

  @override
  Widget build(BuildContext context) {
    final effective = _effectiveAssetPath;
    if (effective != null) {
      // Foto IA: ClipOval + cover; si el archivo no existe -> vectorial.
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.asset(
            effective,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _VectorialFace(faceId: faceId, size: size),
          ),
        ),
      );
    }
    return _VectorialFace(faceId: faceId, size: size);
  }
}

/// Cara vectorial (fondo geométrico + icono centrado).
class _VectorialFace extends StatelessWidget {
  final String faceId;
  final double size;

  const _VectorialFace({required this.faceId, required this.size});

  @override
  Widget build(BuildContext context) {
    final face = AvatarOptions.faceFor(faceId);
    // Tamaño del icono relativo al contenedor.
    final iconSize = size * 0.56;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _FaceShapePainter(shape: face.shape, color: face.color),
        child: Center(
          child: Icon(
            face.icon,
            size: iconSize,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceShapePainter extends CustomPainter {
  final AvatarFaceShape shape;
  final Color color;

  const _FaceShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Relleno con gradiente vertical (color -> 30% negro) para look premium.
    final darkened = Color.lerp(color, Colors.black, 0.30) ?? color;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color, darkened],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    final path = _buildPath(size, shape);

    // Sombra sutil debajo
    canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawPath(path, paint);

    // Highlight superior blanco 22% para dar volumen
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final highlightPath = Path();
    // elipse superior
    highlightPath.addOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.34),
        width: w * 0.46,
        height: h * 0.22,
      ),
    );
    // recortar highlight al path base para que no sobresalga
    final clipped = Path.combine(PathOperation.intersect, path, highlightPath);
    canvas.drawPath(clipped, highlightPaint);

    // Borde interior sutil blanco 35%
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.015
      ..isAntiAlias = true;
    canvas.drawPath(path, borderPaint);
  }

  Path _buildPath(Size size, AvatarFaceShape shape) {
    final w = size.width;
    final h = size.height;
    switch (shape) {
      case AvatarFaceShape.round:
        return Path()
          ..addOval(Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.84, h * 0.80));
      case AvatarFaceShape.square:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.84, h * 0.76),
              Radius.circular(w * 0.22),
            ),
          );
      case AvatarFaceShape.cat:
        // Oval base + orejas triangulares
        final base = Path()
          ..addOval(Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.80, h * 0.70));
        final leftEar = Path()
          ..moveTo(w * 0.22, h * 0.20)
          ..lineTo(w * 0.10, h * 0.04)
          ..lineTo(w * 0.34, h * 0.10)
          ..close();
        final rightEar = Path()
          ..moveTo(w * 0.78, h * 0.20)
          ..lineTo(w * 0.90, h * 0.04)
          ..lineTo(w * 0.66, h * 0.10)
          ..close();
        return Path.combine(PathOperation.union, base,
            Path.combine(PathOperation.union, leftEar, rightEar));
      case AvatarFaceShape.robot:
        // Rect con esquinas suaves + antena
        final body = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(w * 0.10, h * 0.16, w * 0.80, h * 0.72),
              Radius.circular(w * 0.12),
            ),
          );
        final antennaStem = Path()
          ..addRect(Rect.fromLTWH(w * 0.48, h * 0.04, w * 0.04, h * 0.14));
        final antennaHead = Path()
          ..addOval(Rect.fromCenter(
              center: Offset(w * 0.5, h * 0.04), width: w * 0.14, height: w * 0.14));
        return Path.combine(
            PathOperation.union,
            body,
            Path.combine(PathOperation.union, antennaStem, antennaHead));
    }
  }

  @override
  bool shouldRepaint(covariant _FaceShapePainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}
