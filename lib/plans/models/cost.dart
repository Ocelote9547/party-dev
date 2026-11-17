/// Desglose de costes de un plan. Nunca guardar solo `cost = 20`.
class CostBreakdown {
  final double activity;
  final double transportOutbound;
  final double transportReturn;
  final double food;
  final double equipment;
  final double extras;
  final int groupSize;

  const CostBreakdown({
    this.activity = 0,
    this.transportOutbound = 0,
    this.transportReturn = 0,
    this.food = 0,
    this.equipment = 0,
    this.extras = 0,
    this.groupSize = 1,
  });

  double get transportRoundTrip => transportOutbound + transportReturn;

  double get total =>
      activity +
      transportRoundTrip +
      food +
      equipment +
      extras;

  double get perPerson => groupSize <= 0 ? total : total / groupSize;
}
