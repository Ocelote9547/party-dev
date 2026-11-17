import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/models/plan.dart';
import 'package:party/plans/photo_service.dart';
import 'package:party/plans/plan_mock.dart';

void main() {
  group('Fotos de planes (sitio fijo)', () {
    test('fromPlan prefiere imageUrl cuando existe', () {
      const plan = Plan(
        id: 'plan_mercado',
        title: 'Tapeo en Mercado de San Miguel',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/foto.jpg',
      );
      final m = PlanMock.fromPlan(plan);
      expect(m.imageUrl, 'https://upload.wikimedia.org/wikipedia/foto.jpg');
    });

    test('fromPlan usa picsum cuando imageUrl es null', () {
      const plan = Plan(id: 'plan_mercado', title: 'Tapeo en San Miguel');
      final m = PlanMock.fromPlan(plan);
      expect(m.imageUrl, startsWith('https://picsum.photos/seed/'));
    });

    test('fromPlan usa picsum cuando imageUrl es vacío', () {
      const plan = Plan(id: 'plan_x', title: 'X', imageUrl: '');
      final m = PlanMock.fromPlan(plan);
      expect(m.imageUrl, startsWith('https://picsum.photos/seed/'));
    });

    test('photo service no lanza con query absurda', () async {
      final service = PhotoService();
      final url = await service.fetchPhotoUrl(
        query: 'zzz-sitio-inexistente-xyz-12345',
        timeout: const Duration(seconds: 8),
      );
      // null (sin foto) o url http válida; nunca excepción.
      expect(url == null || url.startsWith('http'), isTrue);
    });
  });
}
