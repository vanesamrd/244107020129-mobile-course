import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_navigation/providers/stats_provider.dart';

void main() {
  test('stats provider menghasilkan 3 data', () async {
    final container = ProviderContainer();

    addTearDown(container.dispose);

    final stats = await container.read(statsProvider.future);

    expect(stats.length, 3);
  });
}