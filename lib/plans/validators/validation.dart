import '../intent.dart';
// ignore: unused_import
import '../models/models.dart';

/// Contexto para validar (fase 5).
class ValidationContext {
  final UserIntent intent;
  final DateTime now;
  final int groupSize;
  const ValidationContext(
      {required this.intent, required this.now, this.groupSize = 2});
}

/// Resultado duro: válido o INVALID con motivo.
class ValidationResult {
  final bool valid;
  final String reason; // '' si válido, motivo si INVALID
  const ValidationResult.valid() : valid = true, reason = '';
  const ValidationResult.invalid(this.reason) : valid = false;
}
