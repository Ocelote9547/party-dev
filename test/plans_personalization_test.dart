import 'package:flutter_test/flutter_test.dart';
import 'package:party/plans/models/models.dart';
import 'package:party/plans/personalization.dart';

// Candidato mínimo con los tags indicados.
Candidate _cand(String id, List<String> tags) {
  return Candidate(
    id: id,
    type: CandidateType.place,
    title: id,
    tags: tags,
  );
}

void main() {
  group('PersonalizationEngine.learn', () {
    test('sube afinidad de liked (+0.1)', () {
      const p = UserPreferenceProfile();
      final next = PersonalizationEngine.learn(p, likedTags: ['cultura']);
      expect(next.tagAffinity['cultura'], closeTo(0.6, 1e-9));
    });

    test('baja afinidad de disliked (-0.1)', () {
      const p = UserPreferenceProfile();
      final next = PersonalizationEngine.learn(p, dislikedTags: ['fiesta']);
      expect(next.tagAffinity['fiesta'], closeTo(0.4, 1e-9));
    });

    test('clamp en 0..1 tras muchas repeticiones', () {
      var p = const UserPreferenceProfile();
      for (var i = 0; i < 20; i++) {
        p = PersonalizationEngine.learn(p, likedTags: ['top']);
      }
      expect(p.tagAffinity['top'], lessThanOrEqualTo(1.0));
      expect(p.tagAffinity['top'], equals(1.0));
      for (var i = 0; i < 20; i++) {
        p = PersonalizationEngine.learn(p, dislikedTags: ['top']);
      }
      expect(p.tagAffinity['top'], greaterThanOrEqualTo(0.0));
    });

    test('seenIds se acumulan sin duplicados', () {
      const p = UserPreferenceProfile(seenIds: ['a']);
      final next = PersonalizationEngine.learn(
        p,
        seenIds: ['a', 'b', 'b', 'c'],
      );
      expect(next.seenIds, ['a', 'b', 'c']);
    });
  });

  group('PersonalizationEngine.boostFor', () {
    test('rango [0.8, 1.2] y neutro en 1.0', () {
      const neutral = UserPreferenceProfile();
      // Sin tags conocidos -> media 0.5 -> 1.0.
      expect(
        PersonalizationEngine.boostFor(neutral, _cand('x', ['nuevo'])),
        closeTo(1.0, 1e-9),
      );
      // Sin tags -> 1.0.
      expect(
        PersonalizationEngine.boostFor(neutral, _cand('y', [])),
        equals(1.0),
      );
      // Afinidad máxima -> 1.2; mínima -> 0.8.
      const lover = UserPreferenceProfile(tagAffinity: {'cultura': 1.0});
      const hater = UserPreferenceProfile(tagAffinity: {'cultura': 0.0});
      expect(
        PersonalizationEngine.boostFor(lover, _cand('a', ['cultura'])),
        closeTo(1.2, 1e-9),
      );
      expect(
        PersonalizationEngine.boostFor(hater, _cand('b', ['cultura'])),
        closeTo(0.8, 1e-9),
      );
    });

    test('gustado supera a rechazado', () {
      var p = const UserPreferenceProfile();
      p = PersonalizationEngine.learn(p, likedTags: ['cultura']);
      p = PersonalizationEngine.learn(p, dislikedTags: ['fiesta']);
      final liked = PersonalizationEngine.boostFor(
        p,
        _cand('l', ['cultura']),
      );
      final disliked = PersonalizationEngine.boostFor(
        p,
        _cand('d', ['fiesta']),
      );
      expect(liked, greaterThan(disliked));
      expect(liked, inInclusiveRange(0.8, 1.2));
      expect(disliked, inInclusiveRange(0.8, 1.2));
    });
  });

  group('UserPreferenceProfile json', () {
    test('round-trip toJson/fromJson', () {
      const p = UserPreferenceProfile(
        tagAffinity: {'cultura': 0.7, 'fiesta': 0.3},
        seenIds: ['s1'],
        likedIds: ['l1'],
        dislikedIds: ['d1'],
        completedIds: ['c1'],
      );
      final back = UserPreferenceProfile.fromJson(p.toJson());
      expect(back.tagAffinity, p.tagAffinity);
      expect(back.seenIds, p.seenIds);
      expect(back.likedIds, p.likedIds);
      expect(back.dislikedIds, p.dislikedIds);
      expect(back.completedIds, p.completedIds);
    });
  });
}
