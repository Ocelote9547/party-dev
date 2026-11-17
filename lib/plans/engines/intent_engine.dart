import '../intent.dart';

/// Pesos interpretados de la intención. Cada motor posterior
/// (Discovery/Scoring) los consume sin conocer las preguntas.
class IntentWeights {
  double novelty = 0;
  double relax = 0;
  double social = 0;
  double adventure = 0;
  double culture = 0;
  double food = 0;
  double sport = 0;
  double nature = 0;
  double discovery = 0;
  double learn = 0;
  double calm = 0;
  double special = 0;
  double entertainment = 0;
  double experience = 0;
  double lowFriction = 0;

  Map<String, double> asMap() => {
        'novelty': novelty,
        'relax': relax,
        'social': social,
        'adventure': adventure,
        'culture': culture,
        'food': food,
        'sport': sport,
        'nature': nature,
        'discovery': discovery,
        'learn': learn,
        'calm': calm,
        'special': special,
        'entertainment': entertainment,
        'experience': experience,
        'lowFriction': lowFriction,
      };

  /// Nombres de pesos ordenados de mayor a menor.
  List<String> top(int n) {
    final entries = asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(n).map((e) => e.key).toList();
  }
}

/// IntentEngine (Fase 3): transforma respuestas en intención.
/// "quiero algo diferente" sube novelty/experience/discovery;
/// "quiero desconectar" sube relax/nature/lowFriction, etc.
class IntentEngine {
  static IntentWeights map(UserIntent intent) {
    final w = IntentWeights();

    for (final a in intent.appetites) {
      switch (a) {
        case Appetite.aventura:
          w.adventure += 2;
          w.sport += 1;
          break;
        case Appetite.relax:
          w.relax += 2;
          w.nature += 1;
          w.lowFriction += 1;
          break;
        case Appetite.cultura:
          w.culture += 2;
          w.learn += 1;
          break;
        case Appetite.gastronomia:
          w.food += 2;
          w.social += 1;
          break;
        case Appetite.fiesta:
          w.entertainment += 2;
          w.social += 1;
          break;
        case Appetite.naturaleza:
          w.nature += 2;
          w.relax += 1;
          w.calm += 1;
          break;
        case Appetite.deporte:
          w.sport += 2;
          w.adventure += 1;
          break;
        case Appetite.diferente:
          w.novelty += 2;
          w.experience += 1;
          w.discovery += 2;
          break;
        case Appetite.descubrir:
          w.discovery += 2;
          w.novelty += 1;
          break;
        case Appetite.aprender:
          w.learn += 2;
          w.culture += 1;
          break;
        case Appetite.socializar:
          w.social += 2;
          w.entertainment += 1;
          break;
        case Appetite.bonito:
          w.special += 1;
          w.calm += 1;
          break;
        case Appetite.sorpresa:
          w.novelty += 2;
          w.discovery += 1;
          w.special += 1;
          break;
      }
    }

    switch (intent.withWhom) {
      case WithWhom.solo:
        w.lowFriction += 1;
        w.calm += 1;
        break;
      case WithWhom.pareja:
        w.special += 1;
        w.calm += 1;
        break;
      case WithWhom.familia:
        w.calm += 1;
        w.lowFriction += 1;
        break;
      case WithWhom.amigos:
        w.social += 1;
        w.entertainment += 0.5;
        break;
    }

    for (final a in intent.avoid) {
      switch (a) {
        case Avoid.gente:
          w.nature += 1;
          w.calm += 1;
          break;
        case Avoid.caminar:
        case Avoid.desplazamiento:
        case Avoid.reservar:
          w.lowFriction += 1;
          break;
        case Avoid.gastar:
          w.calm += 1;
          break;
        case Avoid.cerrados:
          w.nature += 1;
          break;
        case Avoid.tranquilo:
          w.entertainment += 1;
          w.adventure += 1;
          break;
        case Avoid.intenso:
          w.relax += 1;
          w.calm += 1;
          break;
      }
    }

    if (intent.noveltyBoost) {
      w.novelty += 2;
      w.discovery += 1;
    }
    if (intent.surprise) {
      w.novelty += 2;
      w.discovery += 1;
      w.special += 1;
    }
    return w;
  }

  static const _labels = <String, String>{
    'novelty': 'Busca novedad',
    'relax': 'Prioriza relax',
    'social': 'Plan social',
    'adventure': 'Espíritu aventurero',
    'culture': 'Toque cultural',
    'food': 'Con buen comer',
    'sport': 'Necesita moverse',
    'nature': 'Aire libre',
    'discovery': 'Quiere descubrir',
    'learn': 'Quiere aprender',
    'calm': 'Con calma',
    'special': 'Algo especial',
    'entertainment': 'Pura diversión',
    'experience': 'Vivir experiencias',
    'lowFriction': 'Sin complicaciones',
  };

  /// Bullets humanos para mostrar la intención detectada (>= 2).
  static List<String> describe(UserIntent intent) {
    final w = map(intent).asMap();
    final out = <String>[];
    w.forEach((key, value) {
      if (value >= 2 && _labels.containsKey(key)) {
        out.add(_labels[key]!);
      }
    });
    return out;
  }
}
