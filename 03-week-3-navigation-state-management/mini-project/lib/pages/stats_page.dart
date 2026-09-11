import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: stats.when(
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Gagal memuat statistik'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.read(statsProvider.notifier).retry();
                  },
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
        data: (data) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(data[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}