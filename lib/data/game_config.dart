class GameConfig {
  final String title;
  final int minPlayers;
  final int maxPlayers;

  const GameConfig({
    required this.title,
    this.minPlayers = 2,
    this.maxPlayers = 10,
  });

  static const configs = <String, GameConfig>{
    'IMPOSTOR': GameConfig(title: 'IMPOSTOR', minPlayers: 4, maxPlayers: 10),
    'PUEBLO DUERME': GameConfig(title: 'PUEBLO DUERME', minPlayers: 4, maxPlayers: 10),
    'ADIVINA': GameConfig(title: 'ADIVINA', minPlayers: 3, maxPlayers: 10),
    'ES UN 10 PERO...': GameConfig(title: 'ES UN 10 PERO...', minPlayers: 3, maxPlayers: 10),
    'DEBATE': GameConfig(title: 'DEBATE', minPlayers: 4, maxPlayers: 10),
    'QUIÉN ES MÁS': GameConfig(title: 'QUIÉN ES MÁS', minPlayers: 4, maxPlayers: 10),
    'TABÚ': GameConfig(title: 'TABÚ', minPlayers: 4, maxPlayers: 10),
    'YO NUNCA': GameConfig(title: 'YO NUNCA', minPlayers: 3, maxPlayers: 10),
    'MÍMICA': GameConfig(title: 'MÍMICA', minPlayers: 4, maxPlayers: 10),
    '¿QUIÉN SOY?': GameConfig(title: '¿QUIÉN SOY?', minPlayers: 3, maxPlayers: 10),
    '¿QUIÉN ES EL ESPIA?': GameConfig(title: '¿QUIÉN ES EL ESPIA?', minPlayers: 4, maxPlayers: 10),
    'VERDAD O RETO': GameConfig(title: 'VERDAD O RETO', minPlayers: 2, maxPlayers: 10),
    'MATAR, CASAR, BESAR': GameConfig(title: 'MATAR, CASAR, BESAR', minPlayers: 3, maxPlayers: 10),
    'SECRETOS': GameConfig(title: 'SECRETOS', minPlayers: 4, maxPlayers: 10),
    'LA MÁSCARA INFILTRADA': GameConfig(title: 'LA MÁSCARA INFILTRADA', minPlayers: 4, maxPlayers: 10),
    'DIBUJA Y ADIVINA': GameConfig(title: 'DIBUJA Y ADIVINA', minPlayers: 3, maxPlayers: 10),
    'BOMBA': GameConfig(title: 'BOMBA', minPlayers: 3, maxPlayers: 10),
    'ALIENIGENA': GameConfig(title: 'ALIENÍGENA', minPlayers: 4, maxPlayers: 10),
    'ALIENÍGENA': GameConfig(title: 'ALIENÍGENA', minPlayers: 4, maxPlayers: 10),
    'YO NUNCA LOBO': GameConfig(title: 'YO NUNCA LOBO', minPlayers: 4, maxPlayers: 10),
    'YO TENGO UN AMIGO': GameConfig(title: 'YO TENGO UN AMIGO', minPlayers: 6, maxPlayers: 10),
    'YO NUNCA EQUIPOS': GameConfig(title: 'YO NUNCA EQUIPOS', minPlayers: 6, maxPlayers: 10),
    'APT COREANO': GameConfig(title: 'APT COREANO', minPlayers: 4, maxPlayers: 10),
    'LA ENSALADA': GameConfig(title: 'LA ENSALADA', minPlayers: 4, maxPlayers: 10),
    'ANGELES Y DEMONIOS': GameConfig(title: 'ANGELES Y DEMONIOS', minPlayers: 4),
    'DOS PALABRAS': GameConfig(title: 'DOS PALABRAS', minPlayers: 3, maxPlayers: 10),
    'HISTORIA COLECTIVA': GameConfig(title: 'HISTORIA COLECTIVA', minPlayers: 3, maxPlayers: 10),
  };

  static GameConfig? getConfig(String title) {
    // Búsqueda directa primero (títulos con acentos/¿? exactos).
    final direct = configs[title];
    if (direct != null) return direct;
    // Fallback normalizado: quita acentos, mayúsculas y separadores para
    // que 'ALIENIGENA' y 'ALIENÍGENA' (y variantes) resuelvan igual.
    final normalized = _normalize(title);
    for (final entry in configs.entries) {
      if (_normalize(entry.key) == normalized) return entry.value;
    }
    return null;
  }

  static String _normalize(String raw) {
    var s = raw.toUpperCase().trim();
    const accentMap = {
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'Ü': 'U',
      'Ñ': 'N',
    };
    for (final e in accentMap.entries) {
      s = s.replaceAll(e.key, e.value);
    }
    s = s.replaceAll(RegExp(r'[^A-Z0-9]+'), '');
    return s;
  }
}
