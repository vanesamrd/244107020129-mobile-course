import 'package:flutter/material.dart';

void main() {
  runApp(const Week12TestingApp());
}

class Week12TestingApp extends StatelessWidget {
  const Week12TestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Week 12 – Testing & QA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
        useMaterial3: true,
      ),
      home: const Week12InfoScreen(),
    );
  }
}

class Week12InfoScreen extends StatelessWidget {
  const Week12InfoScreen({super.key});

  static const items = [
    'Unit test dan widget test: 48 lulus',
    'Integration test: 1 lulus di emulator Android',
    'flutter analyze: No issues found',
    'Coverage: 78,5% (694/884 baris)',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: const Text('Week 12 – Testing & QA'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.fact_check_rounded, size: 72, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Pengujian dilaksanakan pada project Week 10',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Notes App – 10-week-10-ai-feature-integration',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          for (final item in items)
            Card(
              elevation: 0,
              color: cs.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(Icons.check_circle_rounded, color: cs.primary),
                title: Text(item),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Kode dan perintah pengujian berada di folder Week 10. '
            'Laporan lengkap serta artefak coverage tersimpan di folder ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }
}
