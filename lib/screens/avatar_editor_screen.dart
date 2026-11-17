import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/avatar.dart';
import '../services/avatar_service.dart';
import '../services/economy_service.dart';
import '../theme/party_theme.dart';
import '../widgets/avatar_display.dart';
import '../widgets/avatar_painter.dart';

class AvatarEditorScreen extends StatefulWidget {
  final String playerName;
  const AvatarEditorScreen({super.key, required this.playerName});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  AvatarData? _avatar;
  Set<String> _unlockedPacks = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final av = await AvatarService.instance.getOrCreateAvatar(widget.playerName);
    final packs = await EconomyService.instance.getUnlockedPacks();
    if (!mounted) return;
    setState(() {
      _avatar = av;
      _unlockedPacks = packs;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_avatar == null) return;
    await AvatarService.instance.saveAvatar(widget.playerName, _avatar!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Avatar de ${widget.playerName} guardado'), backgroundColor: PartyColors.success),
    );
    Navigator.pop(context, true);
  }

  void _updateAvatar(AvatarData newData) {
    setState(() => _avatar = newData);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _avatar == null) {
      return Scaffold(
        backgroundColor: PartyColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: Text('AVATAR: ${widget.playerName}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final avatar = _avatar!;
    return Scaffold(
      backgroundColor: PartyColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('AVATAR: ${widget.playerName}', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: PartyColors.primary, foregroundColor: PartyColors.onPrimary),
              child: const Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview interactivo 160px con patrón sutil
            Center(
              child: Column(
                children: [
                  _PreviewWithPattern(
                    avatar: avatar,
                    onChanged: _updateAvatar,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Arrastra la cara, sombrero, gafas y máscara para moverlos • Usa los sliders para escalar',
                    style: TextStyle(fontSize: 11, color: PartyColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _AccessoryControls(
              avatar: avatar,
              onChanged: _updateAvatar,
            ),
            const SizedBox(height: 22),
            _SectionLabel(label: 'CARA BASE'),
            const SizedBox(height: 8),
            _EmojiSelector(
              options: AvatarOptions.baseFaces,
              selected: avatar.baseFace,
              unlockedPacks: _unlockedPacks,
              type: 'face',
              previewGradientId: avatar.bgGradientId,
              // Elegir vectorial quita la foto IA para que se vea el cambio.
              onSelected: (v) =>
                  _updateAvatar(avatar.copyWith(baseFace: v, clearAssetPath: true)),
            ),
            const SizedBox(height: 18),
            _SectionLabel(label: 'MIS FOTOS IA'),
            const SizedBox(height: 8),
            _AiPhotosSection(
              avatar: avatar,
              unlockedPacks: _unlockedPacks,
              onSelected: (path) {
                // Si el archivo es un slot custom_XX, fija también baseFace.
                final file = path.split('/').last;
                final id = file.contains('.')
                    ? file.substring(0, file.lastIndexOf('.'))
                    : file;
                if (AvatarOptions.isCustomFaceId(id)) {
                  _updateAvatar(avatar.copyWith(baseFace: id, assetPath: path));
                } else {
                  _updateAvatar(avatar.copyWith(assetPath: path));
                }
              },
              onClear: () =>
                  _updateAvatar(avatar.copyWith(clearAssetPath: true)),
            ),
            const SizedBox(height: 18),
            _SectionLabel(label: 'SOMBRERO'),
            const SizedBox(height: 8),
            _EmojiSelector(
              options: AvatarOptions.hats,
              selected: avatar.hat,
              unlockedPacks: _unlockedPacks,
              type: 'hat',
              onSelected: (v) => _updateAvatar(avatar.copyWith(hat: v)),
            ),
            const SizedBox(height: 18),
            _SectionLabel(label: 'GAFAS'),
            const SizedBox(height: 8),
            _EmojiSelector(
              options: AvatarOptions.glasses,
              selected: avatar.glasses,
              unlockedPacks: _unlockedPacks,
              type: 'glasses',
              onSelected: (v) => _updateAvatar(avatar.copyWith(glasses: v)),
            ),
            const SizedBox(height: 18),
            _SectionLabel(label: 'MÁSCARA'),
            const SizedBox(height: 8),
            _EmojiSelector(
              options: AvatarOptions.masks,
              selected: avatar.mask,
              unlockedPacks: _unlockedPacks,
              type: 'mask',
              onSelected: (v) => _updateAvatar(avatar.copyWith(mask: v)),
            ),
            const SizedBox(height: 18),
            _SectionLabel(label: 'FONDO DEGRADADO'),
            const SizedBox(height: 8),
            _GradientSelector(
              selectedId: avatar.bgGradientId,
              onSelected: (id) {
                final gradient = AvatarOptions.gradientFor(id);
                _updateAvatar(avatar.copyWith(bgGradientId: id, bgColorValue: gradient.colors.first.toARGB32()));
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PartyColors.primary,
                  foregroundColor: PartyColors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('GUARDAR AVATAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview con fondo de patrón sutil + DraggableAvatarPreview 160px
class _PreviewWithPattern extends StatelessWidget {
  final AvatarData avatar;
  final ValueChanged<AvatarData> onChanged;
  const _PreviewWithPattern({required this.avatar, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PartyColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Patrón sutil de puntos
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: CustomPaint(
                painter: _DotPatternPainter(color: PartyColors.border.withValues(alpha: 0.35)),
              ),
            ),
          ),
          // Gradiente sutil de fondo detrás del avatar
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: RadialGradient(
                  colors: [PartyColors.primary.withValues(alpha: 0.08), Colors.transparent],
                  center: Alignment.center,
                  radius: 0.9,
                ),
              ),
            ),
          ),
          DraggableAvatarPreview(
            avatar: avatar,
            size: 160,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const gap = 18.0;
    const radius = 1.2;
    for (double x = gap / 2; x < size.width; x += gap) {
      for (double y = gap / 2; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccessoryControls extends StatelessWidget {
  final AvatarData avatar;
  final ValueChanged<AvatarData> onChanged;
  const _AccessoryControls({required this.avatar, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: PartyColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PartyColors.border),
      ),
      child: Column(
        children: [
          _ScaleRow(
            label: 'Cara',
            icon: Icons.face_outlined,
            scale: avatar.faceScale,
            hasAccessory: true,
            onScale: (v) => onChanged(avatar.copyWith(faceScale: v)),
            onCenter: () => onChanged(avatar.centered('face')),
          ),
          Divider(color: PartyColors.border.withValues(alpha: 0.6), height: 20),
          _ScaleRow(
            label: 'Sombrero',
            icon: Icons.checkroom_outlined,
            scale: avatar.hatScale,
            hasAccessory: avatar.hat.isNotEmpty,
            onScale: (v) => onChanged(avatar.copyWith(hatScale: v)),
            onCenter: () => onChanged(avatar.centered('hat')),
          ),
          Divider(color: PartyColors.border.withValues(alpha: 0.6), height: 20),
          _ScaleRow(
            label: 'Gafas',
            icon: Icons.visibility_outlined,
            scale: avatar.glassesScale,
            hasAccessory: avatar.glasses.isNotEmpty,
            onScale: (v) => onChanged(avatar.copyWith(glassesScale: v)),
            onCenter: () => onChanged(avatar.centered('glasses')),
          ),
          Divider(color: PartyColors.border.withValues(alpha: 0.6), height: 20),
          _ScaleRow(
            label: 'Máscara',
            icon: Icons.masks_outlined,
            scale: avatar.maskScale,
            hasAccessory: avatar.mask.isNotEmpty,
            onScale: (v) => onChanged(avatar.copyWith(maskScale: v)),
            onCenter: () => onChanged(avatar.centered('mask')),
          ),
          const SizedBox(height: 6),
          Text(
            'Offset limitado a ±30px (rango -0.5..0.5) • Escala 0.5..1.5',
            style: TextStyle(fontSize: 10, color: PartyColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double scale;
  final bool hasAccessory;
  final ValueChanged<double> onScale;
  final VoidCallback onCenter;
  const _ScaleRow({
    required this.label,
    required this.icon,
    required this.scale,
    required this.hasAccessory,
    required this.onScale,
    required this.onCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: hasAccessory ? PartyColors.primary : PartyColors.textMuted),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: PartyColors.text)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: hasAccessory ? PartyColors.primary : PartyColors.textMuted.withValues(alpha: 0.3),
              inactiveTrackColor: PartyColors.border,
              thumbColor: hasAccessory ? PartyColors.primary : PartyColors.textMuted,
            ),
            child: Slider(
              value: scale,
              min: 0.5,
              max: 1.5,
              divisions: 10,
              label: scale.toStringAsFixed(1),
              onChanged: hasAccessory ? onScale : null,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(scale.toStringAsFixed(1), style: TextStyle(fontSize: 11, color: PartyColors.textMuted), textAlign: TextAlign.center),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: hasAccessory ? onCenter : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            side: BorderSide(color: PartyColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Centrar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: PartyColors.textSecondary)),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: PartyColors.textSecondary));
  }
}

class _EmojiSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Set<String> unlockedPacks;
  final String type; // face, hat, glasses, mask
  final ValueChanged<String> onSelected;
  final String? previewGradientId;
  const _EmojiSelector({required this.options, required this.selected, required this.unlockedPacks, required this.type, required this.onSelected, this.previewGradientId});

  bool _isLocked(int index) {
    switch (type) {
      case 'hat':
        return AvatarOptions.isHatLocked(index, unlockedPacks);
      case 'glasses':
        return AvatarOptions.isGlassesLocked(index, unlockedPacks);
      case 'mask':
        return AvatarOptions.isMaskLocked(index, unlockedPacks);
      case 'face':
        return AvatarOptions.isFaceLocked(index, unlockedPacks);
      default:
        return false;
    }
  }

  Widget _buildOptionContent(String value, bool locked) {
    if (value.isEmpty) {
      return Text('—', style: TextStyle(fontSize: 16, color: locked ? PartyColors.textMuted.withValues(alpha: 0.5) : PartyColors.textMuted));
    }
    if (AvatarOptions.isVector(value)) {
      final icon = AvatarOptions.iconFor(value);
      return Icon(icon, size: 22, color: locked ? PartyColors.textMuted.withValues(alpha: 0.5) : PartyColors.text);
    }
    return Text(
      value,
      style: TextStyle(
        fontSize: 22,
        color: locked ? PartyColors.textMuted.withValues(alpha: 0.5) : null,
        shadows: locked
            ? null
            : [
                Shadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3, offset: const Offset(0, 1)),
              ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Para CARA BASE: preview circular con fondo degradado usando AvatarDisplay mini
    if (type == 'face') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(options.length, (i) {
          final emoji = options[i];
          final locked = _isLocked(i);
          final isSelected = emoji == selected;
          final gradientId = previewGradientId ?? 'sunset';
          final miniAvatar = AvatarData(baseFace: emoji, bgGradientId: gradientId);
          return GestureDetector(
            onTap: () {
              if (locked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: const Text('Bloqueado — cómpralo en la tienda'), backgroundColor: PartyColors.surface),
                );
                return;
              }
              onSelected(emoji);
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? PartyColors.primary : Colors.white.withValues(alpha: 0.9),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3)),
                      if (isSelected) BoxShadow(color: PartyColors.primary.withValues(alpha: 0.30), blurRadius: 10),
                    ],
                  ),
                  child: Opacity(
                    opacity: locked ? 0.45 : 1,
                    child: AvatarDisplay(avatar: miniAvatar, size: 56, showBorder: false, showShadow: false),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: PartyColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
                if (locked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      child: Center(child: Icon(Icons.lock, size: 16, color: PartyColors.textMuted)),
                    ),
                  ),
              ],
            ),
          );
        }),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(options.length, (i) {
        final emoji = options[i];
        final locked = _isLocked(i);
        final isSelected = emoji == selected;
        return ChoiceChip(
          label: _buildOptionContent(emoji, locked),
          selected: isSelected,
          onSelected: (sel) {
            if (locked) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Bloqueado — cómpralo en la tienda'), backgroundColor: PartyColors.surface),
              );
              return;
            }
            onSelected(emoji);
          },
          showCheckmark: false,
          selectedColor: PartyColors.primary.withValues(alpha: 0.18),
          backgroundColor: PartyColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isSelected ? PartyColors.primary : PartyColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          avatar: locked
              ? Icon(Icons.lock, size: 12, color: PartyColors.textMuted)
              : null,
        );
      }),
    );
  }
}

/// Sección "Mis fotos IA": lista los PNG encontrados en `assets/avatars/`
/// vía AssetManifest para elegirlos como cara base.
/// Vacía -> muestra "Añade tus PNG a assets/avatars/".
class _AiPhotosSection extends StatefulWidget {
  final AvatarData avatar;
  final Set<String> unlockedPacks;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;
  const _AiPhotosSection({
    required this.avatar,
    required this.unlockedPacks,
    required this.onSelected,
    required this.onClear,
  });

  @override
  State<_AiPhotosSection> createState() => _AiPhotosSectionState();
}

class _AiPhotosSectionState extends State<_AiPhotosSection> {
  List<String> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final all = manifest.listAssets();
      final photos = all
          .where(
            (a) =>
                a.startsWith('assets/avatars/') &&
                (a.endsWith('.png') ||
                    a.endsWith('.jpg') ||
                    a.endsWith('.jpeg') ||
                    a.endsWith('.webp')),
          )
          .toList()
        ..sort();
      if (!mounted) return;
      setState(() {
        _photos = photos;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photos = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_photos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: PartyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PartyColors.border),
        ),
        child: Text(
          'Añade tus PNG a assets/avatars/',
          style: TextStyle(fontSize: 12, color: PartyColors.textMuted),
        ),
      );
    }
    final selectedPath = widget.avatar.resolvedFaceAssetPath;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _photos.map((path) {
            final isSelected = selectedPath == path;
            final isGolden = AvatarOptions.isGoldenFaceId(path);
            final goldenLocked =
                isGolden && AvatarOptions.isGoldenFaceLocked(widget.unlockedPacks);
            return GestureDetector(
              onTap: () {
                if (goldenLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Pack Dorado bloqueado — cómpralo en la Tienda 🏆'),
                    ),
                  );
                  return;
                }
                widget.onSelected(path);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? PartyColors.primary
                            : isGolden
                                ? const Color(0xFFFFD700)
                                : Colors.white.withValues(alpha: 0.9),
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                        if (isSelected)
                          BoxShadow(
                            color: PartyColors.primary.withValues(alpha: 0.30),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        path,
                        width: 56,
                        height: 56,
                        cacheWidth: 112,
                        cacheHeight: 112,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            AvatarFaceView(
                          faceId: widget.avatar.baseFace,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: PartyColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check,
                            size: 10, color: Colors.white),
                      ),
                    ),
                  if (goldenLocked)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.lock,
                            size: 10, color: Colors.black87),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
        if (widget.avatar.hasCustomImage) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onClear,
            icon: const Icon(Icons.close, size: 14),
            label: const Text('Quitar foto (usar vectorial)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 32),
              side: BorderSide(color: PartyColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GradientSelector extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  const _GradientSelector({required this.selectedId, required this.onSelected});

  String _labelFor(String id) {
    switch (id) {
      case 'sunset':
        return 'Sunset';
      case 'ocean':
        return 'Ocean';
      case 'forest':
        return 'Forest';
      case 'volcano':
        return 'Volcano';
      case 'cyber':
        return 'Cyber';
      case 'candy':
        return 'Candy';
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AvatarOptions.bgGradientIds.map((id) {
        final gradient = AvatarOptions.gradientFor(id);
        final isSelected = id == selectedId;
        return GestureDetector(
          onTap: () => onSelected(id),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? PartyColors.text : Colors.white.withValues(alpha: 0.85),
                    width: isSelected ? 2.5 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3)),
                    if (isSelected) BoxShadow(color: gradient.colors.first.withValues(alpha: 0.35), blurRadius: 10),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 20, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)])
                    : null,
              ),
              const SizedBox(height: 4),
              Text(
                _labelFor(id),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? PartyColors.primary : PartyColors.textMuted,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
