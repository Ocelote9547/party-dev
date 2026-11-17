/// Intención del usuario (Fase 3): lo que describe en el creador,
/// normalizado para que los motores razonen sin filtros rígidos.
enum WithWhom { solo, pareja, familia, amigos }

enum Appetite {
  aventura,
  relax,
  cultura,
  gastronomia,
  fiesta,
  naturaleza,
  deporte,
  diferente,
  descubrir,
  aprender,
  socializar,
  bonito,
  sorpresa,
}

enum TimeSlot { h30_60, h1_2, h2_4, tardeNoche, todoDia }

extension TimeSlotX on TimeSlot {
  int get minMinutes {
    switch (this) {
      case TimeSlot.h30_60:
        return 30;
      case TimeSlot.h1_2:
        return 60;
      case TimeSlot.h2_4:
        return 120;
      case TimeSlot.tardeNoche:
        return 180;
      case TimeSlot.todoDia:
        return 360;
    }
  }

  int get maxMinutes {
    switch (this) {
      case TimeSlot.h30_60:
        return 60;
      case TimeSlot.h1_2:
        return 120;
      case TimeSlot.h2_4:
        return 240;
      case TimeSlot.tardeNoche:
        return 360;
      case TimeSlot.todoDia:
        return 720;
    }
  }
}

enum BudgetRange { gratis, hasta15, r15_40, r40_80, mas80 }

extension BudgetRangeX on BudgetRange {
  double get minPerPerson {
    switch (this) {
      case BudgetRange.gratis:
        return 0;
      case BudgetRange.hasta15:
        return 0;
      case BudgetRange.r15_40:
        return 15;
      case BudgetRange.r40_80:
        return 40;
      case BudgetRange.mas80:
        return 80;
    }
  }

  double get maxPerPerson {
    switch (this) {
      case BudgetRange.gratis:
        return 0;
      case BudgetRange.hasta15:
        return 15;
      case BudgetRange.r15_40:
        return 40;
      case BudgetRange.r40_80:
        return 80;
      case BudgetRange.mas80:
        return double.infinity;
    }
  }
}

enum MoveMode { pie, bici, patinete, coche, transporte, indiferente }

enum Avoid {
  gente,
  caminar,
  gastar,
  reservar,
  cerrados,
  tranquilo,
  intenso,
  desplazamiento,
}

class UserIntent {
  final WithWhom withWhom;
  final Set<Appetite> appetites; // 1..3
  final TimeSlot timeSlot;
  final double budgetMinPerPerson;
  final double budgetMaxPerPerson; // infinity = sin tope
  final double? radiusKm; // null = me puedo desplazar
  final String locationLabel;
  final double? lat;
  final double? lng;
  final MoveMode moveMode;
  final Set<Avoid> avoid;
  final bool noveltyBoost; // "algo que nunca haya hecho"
  final bool surprise;
  /// Franja horaria preferida: mañana / tarde / noche / indiferente.
  final TimeOfDayPreference timeOfDay;
  /// Fecha prevista del plan (para consultar el tiempo).
  final DateTime? planDate;

  const UserIntent({
    required this.withWhom,
    required this.appetites,
    required this.timeSlot,
    required this.budgetMinPerPerson,
    required this.budgetMaxPerPerson,
    this.radiusKm,
    this.locationLabel = '',
    this.lat,
    this.lng,
    required this.moveMode,
    this.avoid = const {},
    this.noveltyBoost = false,
    this.surprise = false,
    this.timeOfDay = TimeOfDayPreference.indiferente,
    this.planDate,
  });
}

/// Franja horaria del plan.
enum TimeOfDayPreference {
  indiferente,
  manana,   // 08:00-14:00
  tarde,    // 14:00-20:00
  noche,    // 20:00-00:00
}

extension TimeOfDayPreferenceX on TimeOfDayPreference {
  String get label {
    switch (this) {
      case TimeOfDayPreference.indiferente:
        return 'Indiferente';
      case TimeOfDayPreference.manana:
        return 'Mañana';
      case TimeOfDayPreference.tarde:
        return 'Tarde';
      case TimeOfDayPreference.noche:
        return 'Noche';
    }
  }

  int get startHour {
    switch (this) {
      case TimeOfDayPreference.indiferente:
        return 0;
      case TimeOfDayPreference.manana:
        return 8;
      case TimeOfDayPreference.tarde:
        return 14;
      case TimeOfDayPreference.noche:
        return 20;
    }
  }

  int get endHour {
    switch (this) {
      case TimeOfDayPreference.indiferente:
        return 23;
      case TimeOfDayPreference.manana:
        return 14;
      case TimeOfDayPreference.tarde:
        return 20;
      case TimeOfDayPreference.noche:
        return 23;
    }
  }
}
