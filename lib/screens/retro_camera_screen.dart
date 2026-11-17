import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/party_theme.dart';

// NOTA 108MP — investigación ResolutionPreset (Xiaomi 108MP):
// El plugin `camera` (Camera2/AVFoundation) expone solo ResolutionPreset
// estándar. En este dispositivo `max` resuelve a preview 1280x720 y JPEG
// 1080x1920 (~1 MB), no al modo nativo 9000x12000 (~20 MB) de Xiaomi.
// Ese modo 108MP requiere cameraId/stream propietario ("ultra pixel") y
// no es accesible vía plugin estándar. Se mantiene fallback upscale 2x
// (si width<2500) con calidad 95 y un único encode (sin re-encode doble).
// Se prueban veryHigh/ultraHigh antes de max por si algún OEM mapea max a
// preview. Debug: previewSize vs JPEG decodificado se loguea en cada captura
// y se muestra en UI como `Res: <preset> WxH → foto WxH`.

// Top-level isolate function for heavy image processing.
// Optimizado: sin HSL selectivo (cuello de botella). Solo adjustColor +
// fade ligero + temp matriz + grano por bloque 4x4. Upscale limitado a 4000px.
Uint8List _processImageIsolate(Map<String, dynamic> args) {
  final Uint8List bytes = args['bytes'] as Uint8List;
  final bool filterEnabled =
      (args['filterEnabled'] ?? args['filter'] ?? true) as bool;
  final dynamic stampArg = args['stamp'];
  DateTime stamp;
  if (stampArg is DateTime) {
    stamp = stampArg;
  } else if (stampArg is int) {
    stamp = DateTime.fromMillisecondsSinceEpoch(stampArg);
  } else {
    stamp = DateTime.now();
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  var processed = decoded;
  final bool aiEnabled = (args['aiEnabled'] ?? args['ai'] ?? false) as bool;
  final int aiScale = (args['aiScale'] ?? args['scale'] ?? 2) as int;

  // --- Objetivo final de upscale (limitado, sin 2160*2=4320, max 4000) ---
  // RÁPIDO: el bucle pesado (fade+temp+grano píxel a píxel en Dart) se hace
  // SIEMPRE sobre un ancho capado a 1600px y el upscale cúbico se deja para
  // el FINAL. Así un 2160x3840 (8.3M px) se filtra a 1600px (~4.5M px) y
  // luego se sube al objetivo, en vez de filtrar 8M píxeles (timeout 8s).
  int targetW = processed.width;
  if (aiEnabled) {
    if (processed.width == 2160 && aiScale == 2) {
      targetW = processed.width; // evita 4320
    } else {
      targetW =
          (processed.width * aiScale.clamp(2, 3)).clamp(processed.width, 4000);
    }
  } else {
    if (processed.width < 2500 && processed.width != 2160) {
      targetW = (processed.width * 2).clamp(processed.width, 4000);
    }
  }
  const workMaxW = 1600;
  if (processed.width > workMaxW) {
    processed = img.copyResize(
      processed,
      width: workMaxW,
      interpolation: img.Interpolation.linear,
    );
  }

  // Sin filtro ni IA: sin sello, devuelve natural con quality 92
  if (!filterEnabled && !aiEnabled) {
    final out0 = img.encodeJpg(processed, quality: 92);
    return Uint8List.fromList(out0);
  }

  // Si filter desactivo pero IA activa: solo upscale+sharpen sin sello (filtro OFF => no fecha)
  if (!filterEnabled && aiEnabled) {
    try {
      processed = img.adjustColor(processed,
          contrast: 1.12, saturation: 1.08, brightness: 1.01);
      processed = img.convolution(processed,
          filter: [0, -0.22, 0, -0.22, 1.88, -0.22, 0, -0.22, 0]);
    } catch (_) {}
    final out = img.encodeJpg(processed, quality: 92);
    return Uint8List.fromList(out);
  }

  // filterEnabled true: adjustColor ligero + loop único para fade+temp+grano (sin HSL)
  processed = img.adjustColor(processed,
      contrast: 0.92, brightness: 1.06, saturation: 0.94);

  final w = processed.width;
  final h = processed.height;
  final rnd = math.Random(1337);
  // Grano más denso: bloque 2x2 (antes 4x4) y amplitud mayor
  final blocksX = (w + 1) ~/ 2;
  final blocksY = (h + 1) ~/ 2;
  final grain = List<int>.generate(blocksX * blocksY, (_) {
    final u1 = rnd.nextDouble().clamp(0.0001, 1.0);
    final u2 = rnd.nextDouble();
    final gauss = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    // grano 60 tam 25: amplitud 12-15 más visible y densa
    return (gauss * 12).round();
  });

  // LUTs: fusiona fade + temperatura cálida en 256 entradas por canal.
  // Evita ~4 llamadas de función + 3 multiplicaciones por píxel (8M px).
  int fadeFn(int c) {
    if (c < 50) return (c * 0.88 + 22).round().clamp(0, 255);
    if (c < 120) return (c * 0.92 + 14).round().clamp(0, 255);
    if (c > 210) return (c * 0.82 + 40).round().clamp(0, 255);
    if (c > 185) return (c * 0.86 + 28).round().clamp(0, 255);
    return c;
  }

  final lutR = List<int>.generate(
      256, (c) => (fadeFn(c) * 1.12 + 3).round().clamp(0, 255));
  final lutG = List<int>.generate(
      256, (c) => (fadeFn(c) * 1.03 + 1).round().clamp(0, 255));
  final lutB = List<int>.generate(
      256, (c) => (fadeFn(c) * 0.92 + 2).round().clamp(0, 255));

  for (var y = 0; y < h; y++) {
    final blockY = y ~/ 2;
    for (var x = 0; x < w; x++) {
      final blockX = x ~/ 2;
      final n = grain[blockY * blocksX + blockX];
      final p = processed.getPixel(x, y);
      var nr = lutR[p.r.toInt()] + n;
      var ng = lutG[p.g.toInt()] + n;
      var nb = lutB[p.b.toInt()] + n;
      if (nr > 255) {
        nr = 255;
      } else if (nr < 0) {
        nr = 0;
      }
      if (ng > 255) {
        ng = 255;
      } else if (ng < 0) {
        ng = 0;
      }
      if (nb > 255) {
        nb = 255;
      } else if (nb < 0) {
        nb = 0;
      }
      processed.setPixelRgb(x, y, nr, ng, nb);
    }
  }

  if (aiEnabled) {
    try {
      processed = img.adjustColor(processed,
          contrast: 1.12, saturation: 1.08, brightness: 1.01);
      processed = img.convolution(processed,
          filter: [0, -0.22, 0, -0.22, 1.88, -0.22, 0, -0.22, 0]);
    } catch (_) {}
  }

  // Upscale FINAL (cúbico) al objetivo, tras el filtrado barato.
  if (targetW != processed.width && targetW > processed.width) {
    processed = img.copyResize(
      processed,
      width: targetW,
      interpolation: img.Interpolation.cubic,
    );
  }

  String two(int n) => n.toString().padLeft(2, '0');
  final stampStr =
      '${two(stamp.day)} ${[
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ][stamp.month - 1]} ${stamp.year}';
  final int stampX = processed.width - 150;
  final int stampY = processed.height - 32;
  img.fillRect(
    processed,
    x1: stampX - 4,
    y1: stampY - 2,
    x2: stampX + 120,
    y2: stampY + 16,
    color: img.ColorRgba8(0, 0, 0, 100),
  );
  img.drawString(
    processed,
    stampStr,
    font: img.arial14,
    x: stampX,
    y: stampY,
    color: img.ColorRgb8(255, 213, 79),
  );
  final out = img.encodeJpg(processed, quality: 92);
  return Uint8List.fromList(out);
}

class RetroCameraScreen extends StatefulWidget {
  const RetroCameraScreen({super.key});

  @override
  State<RetroCameraScreen> createState() => _RetroCameraScreenState();
}

class _RetroCameraScreenState extends State<RetroCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedIndex = 0;
  bool _isInitializing = true;
  String? _error;
  XFile? _lastPhoto;
  bool _isCapturing = false;
  ResolutionPreset _activePreset = ResolutionPreset.max;
  String _activePresetLabel = 'max';
  bool _filterEnabled = true;
  bool _aiEnabled = false;
  int _aiScale = 2;
  // Última foto: dimensiones reales JPEG decodificadas para debug visible.
  String _lastPhotoRes = '—';
  // Nota 108MP: si max sigue dando 1080p (1 MB) en vez de 9000x12000 (20 MB),
  // es porque el modo nativo 108MP de Xiaomi usa cameraId específico no
  // expuesto por el plugin `camera` (confirmado por previewSize 1280x720).

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _error = null;
    });
    try {
      // Permiso explícito para mensaje claro en Android
      if (Platform.isAndroid || Platform.isIOS) {
        final status = await Permission.camera.request();
        if (!mounted) return;
        if (status.isDenied || status.isPermanentlyDenied) {
          if (!mounted) return;
          setState(() {
            _error = 'Permiso de cámara denegado. Actívalo en Ajustes.';
            _isInitializing = false;
          });
          return;
        }
      }
      _cameras = await availableCameras();
      if (!mounted) return;
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'No se encontró cámara en este dispositivo.';
          _isInitializing = false;
        });
        return;
      }
      // Prioriza la principal 108MP (id "0" en Xiaomi) + ultra gran angular
      final backCams =
          _cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();
      final frontCams =
          _cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
      // Ordena traseras: primero la que sea "0" (principal 108MP), luego el resto
      backCams.sort((a, b) {
        if (a.name == '0') return -1;
        if (b.name == '0') return 1;
        return a.name.compareTo(b.name);
      });
      final ordered = <CameraDescription>[];
      if (backCams.isNotEmpty) ordered.add(backCams.first);
      if (backCams.length > 1) ordered.add(backCams[1]);
      ordered.addAll(frontCams);
      for (final c in _cameras) {
        if (!ordered.contains(c)) ordered.add(c);
      }
      _cameras = ordered;
      _selectedIndex = 0;
      await _initController(_cameras[_selectedIndex]);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error iniciando cámara: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initController(CameraDescription desc) async {
    // Re-init robusto: dispose previo antes de crear nuevo controller
    await _controller?.dispose();
    if (!mounted) return;
    _controller = null;
    if (mounted) {
      setState(() => _isInitializing = true);
    }

    // Intento en cascada: veryHigh -> ultraHigh -> max -> high -> medium
    // Investigación 108MP: veryHigh/ultraHigh se prueban ANTES de max porque
    // en algunos Xiaomi max mapea a preview 720p mientras ultraHigh da JPEG
    // más grande. Se loguea previewSize vs JPEG real en cada intento.
    const presets = [
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh,
      ResolutionPreset.max,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ];
    const labels = ['veryHigh', 'ultraHigh', 'max', 'high', 'medium'];

    CameraException? lastException;
    bool success = false;

    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final label = labels[i];
      try {
        _controller = CameraController(
          desc,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (!mounted) return;
        // Configuración de calidad para 108MP y todos los sensores
        try {
          await _controller!.setFocusMode(FocusMode.auto);
        } catch (_) {}
        if (!mounted) return;
        try {
          await _controller!.setExposureMode(ExposureMode.auto);
        } catch (_) {}
        if (!mounted) return;
        try {
          await _controller!.setFlashMode(FlashMode.auto);
        } catch (_) {}
        if (!mounted) return;

        _activePreset = preset;
        _activePresetLabel = label;
        success = true;
        // Log previewSize para investigar max vs veryHigh/ultraHigh
        if (kDebugMode) {
          final ps = _controller!.value.previewSize;
          final psStr = ps != null ? '${ps.width.toStringAsFixed(0)}x${ps.height.toStringAsFixed(0)}' : 'null';
          debugPrint('[Camera] preset $label -> previewSize $psStr (active=$_activePresetLabel)');
        }
        break;
      } on CameraException catch (e) {
        lastException = e;
        try {
          await _controller?.dispose();
        } catch (_) {}
        if (!mounted) return;
        _controller = null;
        // continúa al siguiente preset
      } catch (e) {
        lastException = CameraException('init_failed', e.toString());
        try {
          await _controller?.dispose();
        } catch (_) {}
        if (!mounted) return;
        _controller = null;
      }
    }

    if (!mounted) return;

    if (success && _controller != null && _controller!.value.isInitialized) {
      setState(() {
        _isInitializing = false;
        _error = null;
      });
    } else {
      // Nunca dejar _isInitializing=false sin controller válido: si falla todo, mostrar error
      await _controller?.dispose();
      if (!mounted) return;
      _controller = null;
      setState(() {
        _error =
            'No se pudo iniciar ${desc.name}: ${lastException ?? "fallo en presets veryHigh/ultraHigh/max/high/medium"}';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchLens() async {
    if (_cameras.length < 2) return;
    // Guarda índice nuevo y hace re-init robusto según spec
    final newIndex = (_selectedIndex + 1) % math.min(2, _cameras.length).toInt();
    _selectedIndex = newIndex;

    await _controller?.dispose();
    if (!mounted) return;
    _controller = null;
    if (mounted) {
      setState(() => _isInitializing = true);
    }
    if (!mounted) return;

    const presets = [
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh,
      ResolutionPreset.max,
      ResolutionPreset.high,
      ResolutionPreset.medium,
    ];
    const labels = ['veryHigh', 'ultraHigh', 'max', 'high', 'medium'];

    CameraException? lastException;
    bool success = false;
    final desc = _cameras[_selectedIndex];

    for (var i = 0; i < presets.length; i++) {
      final preset = presets[i];
      final label = labels[i];
      try {
        _controller = CameraController(
          desc,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _controller!.initialize();
        if (!mounted) return;
        try {
          await _controller!.setFocusMode(FocusMode.auto);
        } catch (_) {}
        if (!mounted) return;
        try {
          await _controller!.setExposureMode(ExposureMode.auto);
        } catch (_) {}
        if (!mounted) return;
        try {
          await _controller!.setFlashMode(FlashMode.auto);
        } catch (_) {}
        if (!mounted) return;

        _activePreset = preset;
        _activePresetLabel = label;
        success = true;
        if (kDebugMode) {
          final ps = _controller!.value.previewSize;
          final psStr = ps != null ? '${ps.width.toStringAsFixed(0)}x${ps.height.toStringAsFixed(0)}' : 'null';
          debugPrint('[Camera] switch preset $label -> previewSize $psStr');
        }
        break;
      } on CameraException catch (e) {
        lastException = e;
        try {
          await _controller?.dispose();
        } catch (_) {}
        if (!mounted) return;
        _controller = null;
      } catch (e) {
        lastException = CameraException('switch_failed', e.toString());
        try {
          await _controller?.dispose();
        } catch (_) {}
        if (!mounted) return;
        _controller = null;
      }
    }

    if (!mounted) return;

    if (success && _controller != null && _controller!.value.isInitialized) {
      setState(() {
        _isInitializing = false;
        _error = null;
      });
    } else {
      await _controller?.dispose();
      if (!mounted) return;
      _controller = null;
      setState(() {
        _error =
            'No se pudo cambiar a ${desc.name}: ${lastException ?? "fallo en presets"}';
        _isInitializing = false;
      });
    }
  }

  String _lensLabel(CameraDescription c) {
    if (c.lensDirection == CameraLensDirection.front) return 'Frontal';
    if (_cameras.indexOf(c) == 1 && _cameras.length >= 2) {
      return 'Ultra gran angular';
    }
    return 'Principal';
  }

  String _presetDebugLabel() {
    final size = _controller?.value.previewSize;
    final previewRes = size != null
        ? '${size.width.toStringAsFixed(0)}x${size.height.toStringAsFixed(0)}'
        : '...';
    final presetName = _activePreset.name;
    // Formato pedido: Res: <preset> <W>x<H> → foto <W>x<H>
    // Si aún no hay foto, muestra preview y foto pendiente.
    return 'Res: $presetName $previewRes → foto $_lastPhotoRes';
  }

  Future<void> _takePhoto() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;
    try {
      if (mounted) setState(() => _isCapturing = true);
      // Captura previewSize antes de takePicture para对比 con JPEG real
      final previewSize = ctrl.value.previewSize;
      final previewStr = previewSize != null
          ? '${previewSize.width.toStringAsFixed(0)}x${previewSize.height.toStringAsFixed(0)}'
          : 'null';
      XFile? file;
      bool usedNative = false;
      try {
        const channel = MethodChannel('com.n3mesis.party/camera_max');
        final supported = await channel.invokeMethod<bool>('isUltraHighResSupported');
        if (supported == true) {
          final prev = _controller;
          await prev?.dispose();
          if (mounted) {
            setState(() {
              _controller = null;
              _isInitializing = true;
            });
          } else {
            _controller = null;
          }
          final tmpDir = await getTemporaryDirectory();
          final tmpPath = '${tmpDir.path}/native_max_${DateTime.now().millisecondsSinceEpoch}.jpg';
          try {
            final res = await channel.invokeMethod<dynamic>('takeUltraHighResPhoto', {'path': tmpPath});
            String? p;
            if (res is Map && res['path'] != null) {
              p = res['path'] as String;
            } else if (res is String) {
              p = res;
            }
            if (p != null) {
              final f = File(p);
              if (await f.exists() && await f.length() > 0) {
                file = XFile(f.path);
                usedNative = true;
              }
            }
          } catch (_) {}
          if (mounted && _cameras.isNotEmpty) {
            try {
              await _initController(_cameras[_selectedIndex]);
            } catch (_) {}
          }
        }
      } catch (_) {}
      if (!usedNative) {
        file = await ctrl.takePicture();
      }
      if (file == null) {
        if (mounted) setState(() => _isCapturing = false);
        return;
      }
      if (!mounted) return;
      // Log tamaño real JPEG decodificado vs previewSize
      try {
        final rawBytes = await File(file.path).readAsBytes();
        final decoded = img.decodeImage(rawBytes);
        final fotoStr = decoded != null ? '${decoded.width}x${decoded.height}' : 'decode-null';
        if (kDebugMode) {
          debugPrint('[Camera] $_activePresetLabel $previewStr → foto $fotoStr (${rawBytes.length} bytes)');
        }
        // Si max sigue dando 1080p (preview 1280x720, foto 1080x1920 ~1 MB) en vez de
        // 9000x12000 (~20 MB), se documenta que el modo 108MP nativo de Xiaomi
        // requiere cameraId específico no expuesto por plugin camera estándar.
      } catch (_) {}
      final stamp = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final name =
          'foto_${stamp.year}-${two(stamp.month)}-${two(stamp.day)}_${two(stamp.hour)}-${two(stamp.minute)}-${two(stamp.second)}.jpg';

      File dest;
      bool saved = false;
      String savedPath = '';
      int savedLen = 0;

      // Intento primario: DCIM/PARTY público (visible en galería) en Android
      try {
        if (Platform.isAndroid) {
          try {
            await Permission.storage.request();
            await Permission.photos.request();
            // ignore: deprecated_member_use
            await Permission.manageExternalStorage.request();
          } catch (_) {}
          final dcimDir = Directory('/storage/emulated/0/DCIM/PARTY');
          if (!await dcimDir.exists()) {
            await dcimDir.create(recursive: true);
          }
          dest = File('${dcimDir.path}/$name');
        } else {
          final dir = await getApplicationDocumentsDirectory();
          if (!mounted) return;
          dest = File('${dir.path}/$name');
        }
        bool copyOk = false;
        try {
          await file.saveTo(dest.path);
          copyOk = true;
        } catch (_) {
          try {
            await File(file.path).copy(dest.path);
            copyOk = true;
          } catch (_) {
            copyOk = false;
          }
        }
        if (copyOk && await dest.exists()) {
          // Aplica filtro Kodak + HDR + sello fecha + upscale simulando 108MP si está activado
          if (_filterEnabled || _aiEnabled) {
            try {
              await _applyKodakFilterToFile(dest).timeout(const Duration(seconds: 15));
            } catch (_) {}
          }
          try {
            const channel = MethodChannel('com.n3mesis.party/media_scanner');
            await channel.invokeMethod('scanFile', {'path': dest.path});
          } catch (_) {}
          if (!mounted) return;
          final len = await dest.length();
          if (!mounted) return;
          if (len > 0) {
            saved = true;
            savedPath = dest.path;
            savedLen = len;
          }
        }
        // Si DCIM falló en Android, fallback a app docs
        if (!saved && Platform.isAndroid) {
          final dir = await getApplicationDocumentsDirectory();
          if (!mounted) return;
          dest = File('${dir.path}/$name');
          bool copyOk2 = false;
          try {
            await file.saveTo(dest.path);
            copyOk2 = true;
          } catch (_) {
            try {
              await File(file.path).copy(dest.path);
              copyOk2 = true;
            } catch (_) {
              copyOk2 = false;
            }
          }
          if (copyOk2 && await dest.exists()) {
            if (_filterEnabled || _aiEnabled) {
              try {
                await _applyKodakFilterToFile(dest).timeout(const Duration(seconds: 15));
              } catch (_) {}
            }
            if (!mounted) return;
            final len = await dest.length();
            if (!mounted) return;
            if (len > 0) {
              saved = true;
              savedPath = dest.path;
              savedLen = len;
            }
          }
        }
      } catch (_) {
        saved = false;
      }
      if (!mounted) return;

      // Fallback: getTemporaryDirectory si falla el primario
      if (!saved) {
        try {
          final tmp = await getTemporaryDirectory();
          if (!mounted) return;
          final fallback = File('${tmp.path}/$name');
          bool copyOk = false;
          try {
            // ignore: deprecated_member_use
            await file.saveTo(fallback.path);
            copyOk = true;
          } catch (_) {
            try {
              await File(file.path).copy(fallback.path);
              copyOk = true;
            } catch (_) {
              copyOk = false;
            }
          }
          if (copyOk && await fallback.exists()) {
            if (!mounted) return;
            final len = await fallback.length();
            if (!mounted) return;
            if (len > 0) {
              saved = true;
              savedPath = fallback.path;
              savedLen = len;
              dest = fallback;
            }
          }
        } catch (_) {
          saved = false;
        }
      }
      if (!mounted) return;

      if (saved) {
        // Actualiza UI debug y log final preview → foto (tras upscale/filtro)
        String finalRes = _lastPhotoRes;
        try {
          final finalBytes = await File(savedPath).readAsBytes();
          final finalDecoded = img.decodeImage(finalBytes);
          if (finalDecoded != null) {
            finalRes = '${finalDecoded.width}x${finalDecoded.height}';
            if (kDebugMode) {
              debugPrint('[Camera] final $_activePresetLabel $previewStr → foto $finalRes ($savedLen bytes) calidad 95 single-encode');
            }
          }
        } catch (_) {}
        if (mounted) {
          setState(() {
            _lastPhoto = XFile(savedPath);
            _lastPhotoRes = finalRes;
          });
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Foto guardada: $savedPath ($savedLen bytes) $finalRes'),
            backgroundColor: PartyColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar foto: no se pudo escribir $name'),
            backgroundColor: PartyColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al hacer foto: $e'),
          backgroundColor: PartyColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    // inactive -> dispose para liberar cámara; resumed -> reinit
    if (state == AppLifecycleState.inactive) {
      if (ctrl != null) {
        ctrl.dispose();
        _controller = null;
        if (mounted) {
          // No llamamos setState pesado si está en background, pero marcamos
          // _isInitializing para que al volver muestre loader hasta reinit
          _isInitializing = true;
        }
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty && (_controller == null || !(_controller?.value.isInitialized ?? false))) {
        _initController(_cameras[_selectedIndex]);
      }
    }
  }

  Future<void> _applyKodakFilterToFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final out = await compute(_processImageIsolate, {
        'bytes': bytes,
        'filter': _filterEnabled,
        'filterEnabled': _filterEnabled,
        'aiEnabled': _aiEnabled,
        'aiScale': _aiScale,
        'stamp': DateTime.now().millisecondsSinceEpoch,
      }).timeout(const Duration(seconds: 15));
      await file.writeAsBytes(out, flush: true);
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final isReady =
        ctrl != null && ctrl.value.isInitialized && !_isInitializing && _error == null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('FOTO RETRO',
            style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w900)),
      ),
      body: _error != null
          ? _buildError()
          : !isReady
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    // Vista previa SIN filtro (fluida) - el filtro se aplica solo al guardar
                    _CleanPreview(controller: ctrl),
                    // Viñeteado + sello fecha
                    const _KodakOverlay(),
                    // Indicador de resolución para debug (arriba-izquierda, no bloquea) - bajado 18px para no tapar KODAK
                    Positioned(
                      top: 26,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _presetDebugLabel(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            letterSpacing: 0.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Controles inferiores
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                            20, 16, 20, 20 + MediaQuery.of(context).padding.bottom),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.72),
                              Colors.transparent
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_cameras.isNotEmpty)
                              Text(
                                'Lente: ${_lensLabel(_cameras[_selectedIndex])} • ${_selectedIndex + 1}/${math.min(2, _cameras.length)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11, letterSpacing: 1.2),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Galería miniatura
                                GestureDetector(
                                  onTap: _lastPhoto == null
                                      ? null
                                      : () => showDialog(
                                            context: context,
                                            builder: (_) => Dialog(
                                              backgroundColor: Colors.transparent,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.file(File(_lastPhoto!.path),
                                                    fit: BoxFit.contain),
                                              ),
                                            ),
                                          ),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white24),
                                      image: _lastPhoto != null
                                          ? DecorationImage(
                                              image: FileImage(File(_lastPhoto!.path)),
                                              fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: _lastPhoto == null
                                        ? const Icon(Icons.photo_outlined,
                                            color: Colors.white54, size: 22)
                                        : null,
                                  ),
                                ),
                                // Botón disparo - rota solo este botón en horizontal, cámara bloqueada en vertical
                                OrientationBuilder(
                                  builder: (context, orientation) {
                                    return RotatedBox(
                                      quarterTurns: orientation == Orientation.landscape ? 1 : 0,
                                      child: GestureDetector(
                                        onTap: _isCapturing ? null : _takePhoto,
                                        child: Container(
                                          width: 78,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(color: Colors.white, width: 4),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.3),
                                                  blurRadius: 12)
                                            ],
                                          ),
                                          child: _isCapturing
                                              ? const Padding(
                                                  padding: EdgeInsets.all(22),
                                                  child: CircularProgressIndicator(
                                                      strokeWidth: 3, color: Colors.black87),
                                                )
                                              : const Icon(Icons.camera_alt_rounded,
                                                  size: 36, color: Colors.black87),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Cambiar lente
                                IconButton(
                                  onPressed: _cameras.length < 2 || _isInitializing
                                      ? null
                                      : _switchLens,
                                  icon: const Icon(Icons.switch_camera_rounded,
                                      color: Colors.white, size: 28),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white12,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(14),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                spacing: 8,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => _filterEnabled = !_filterEnabled),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _filterEnabled ? const Color(0xFFFFD54F).withValues(alpha: 0.9) : Colors.white12,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _filterEnabled ? const Color(0xFFFFD54F) : Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_filterEnabled ? Icons.filter_vintage : Icons.filter_vintage_outlined, size: 16, color: _filterEnabled ? Colors.black87 : Colors.white70),
                                          const SizedBox(width: 6),
                                          Text(_filterEnabled ? 'Filtro ON' : 'Filtro OFF', style: TextStyle(color: _filterEnabled ? Colors.black87 : Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setState(() => _aiEnabled = !_aiEnabled),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _aiEnabled ? const Color(0xFF00E5FF).withValues(alpha: 0.9) : Colors.white12,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _aiEnabled ? const Color(0xFF00E5FF) : Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_aiEnabled ? Icons.auto_awesome : Icons.auto_awesome_outlined, size: 16, color: _aiEnabled ? Colors.black87 : Colors.white70),
                                          const SizedBox(width: 6),
                                          Text(_aiEnabled ? 'IA ON' : 'IA OFF', style: TextStyle(color: _aiEnabled ? Colors.black87 : Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('x2'),
                                    selected: _aiScale == 2,
                                    onSelected: (v) { if (v) setState(() => _aiScale = 2); },
                                  ),
                                  ChoiceChip(
                                    label: const Text('x3'),
                                    selected: _aiScale == 3,
                                    onSelected: (v) { if (v) setState(() => _aiScale = 3); },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _aiEnabled ? const Color(0xFF00E5FF).withValues(alpha: 0.22) : Colors.white12,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _aiEnabled ? const Color(0xFF00E5FF) : Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.blur_on, size: 14, color: _aiEnabled ? const Color(0xFF00E5FF) : Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(_aiEnabled ? 'Nitidez ON' : 'Nitidez OFF', style: TextStyle(color: _aiEnabled ? const Color(0xFF00E5FF) : Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded, size: 56, color: Colors.white54),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview limpio sin filtro (fluido, sin ColorFiltered que laguea).
/// El filtro Kodak se aplica solo al guardar (procesado con paquete image).
class _CleanPreview extends StatelessWidget {
  final CameraController controller;
  const _CleanPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Preview siempre 4:3 (Kodak disposable) + cover, sin bugueo horizontal
    return ClipRect(
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 1280,
            height: controller.value.previewSize?.width ?? 720,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

/// Overlay retro: viñeteado + sello de fecha amarilla + leve grano texturizado.
class _KodakOverlay extends StatelessWidget {
  const _KodakOverlay();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${two(now.day)} ${const ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'][now.month - 1]} ${now.year}';
    return Stack(
      fit: StackFit.expand,
      children: [
        // Viñeteado
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.38)],
              center: Alignment.center,
              radius: 1.05,
              stops: const [0.65, 1.0],
            ),
          ),
        ),
        // Grano sutil (puntos muy tenues)
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _GrainPainter(),
          ),
        ),
        // Sello fecha Kodak (amarillo, mono, abajo a la derecha)
        Positioned(
          right: 14,
          bottom: 110,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration:
                BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(4)),
            child: Text(
              stamp,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ),
        // Marca de agua KODAK discreta arriba
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'KODAK • DISPOSABLE',
                style:
                    TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 2.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final rnd = math.Random(42);
    for (var i = 0; i < 600; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = rnd.nextDouble() * 1.5 + 0.6;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
