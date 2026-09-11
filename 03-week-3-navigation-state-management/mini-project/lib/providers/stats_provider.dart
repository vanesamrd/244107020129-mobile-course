import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo_provider.dart';

class StatsNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() async {
    ref.watch(todoProvider);

    await Future.delayed(const Duration(seconds: 1));

    final todos = ref.read(todoProvider);

    final total = todos.length;
    final selesai = todos.where((todo) => todo.isDone).length;
    final belumSelesai = total - selesai;

    return [
      'Tugas selesai: $selesai',
      'Tugas belum selesai: $belumSelesai',
      'Total tugas: $total',
    ];
  }

  Future<void> retry() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1));

      final todos = ref.read(todoProvider);

      final total = todos.length;
      final selesai = todos.where((todo) => todo.isDone).length;
      final belumSelesai = total - selesai;

      return [
        'Tugas selesai: $selesai',
        'Tugas belum selesai: $belumSelesai',
        'Total tugas: $total',
      ];
    });
  }
}

final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);