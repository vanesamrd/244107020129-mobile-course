import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state dari provider.
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: statsAsync.when(
        // Tampilan saat data sedang dimuat.
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),

        // Tampilan saat terjadi error.
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gagal memuat: $error'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  ref.read(statsProvider.notifier).retry();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),

        // Tampilan saat data berhasil diperoleh.
        data: (stats) => ListView.builder(
  padding: const EdgeInsets.all(12),
  itemCount: stats.length,
  itemBuilder: (context, index) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.analytics_outlined),
        title: Text(stats[index]),
      ),
    );
  },
),
      ),
    );
  }
}