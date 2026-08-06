// Phase E2: SetDenTheme must reject any theme id outside the known free
// pool, and persist a valid choice.

import 'package:flutter_test/flutter_test.dart';

import 'package:bipod_bondhu/core/error/failures.dart';
import 'package:bipod_bondhu/core/error/result.dart';
import 'package:bipod_bondhu/domain/entities/den_state.dart';
import 'package:bipod_bondhu/domain/usecases/set_den_theme.dart';

import '../../fakes/fake_den_repository.dart';

void main() {
  late FakeDenRepository denRepository;
  late SetDenTheme setDenTheme;

  setUp(() {
    denRepository = FakeDenRepository();
    setDenTheme = SetDenTheme(denRepository);
  });

  test('rejects an unknown theme id, with no state change', () async {
    final before = denRepository.state;

    final result = await setDenTheme('paywalled_castle');

    expect(result, isA<Failure<DenState>>());
    expect((result as Failure<DenState>).failure, isA<ValidationFailure>());
    expect(denRepository.state, before);
  });

  test('accepts a valid free theme and persists it', () async {
    final result = await setDenTheme('sky');

    expect(result, isA<Success<DenState>>());
    expect(denRepository.state.themeId, 'sky');
    expect(denRepository.saveCallCount, 1);
  });
}
