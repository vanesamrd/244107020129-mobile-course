import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    return [
      'Tugas selesai: 0',
      'Kehadiran: 0%',
      'Nilai rata-rata: 0',
    ];
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);