import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../providers/prefs_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(darkModeProvider);
    final forceOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Gunakan tampilan gelap'),
            trailing: Switch(
              value: darkMode.value ?? false,
              onChanged: darkMode.isLoading
                  ? null
                  : (_) => ref.read(darkModeProvider.notifier).toggle(),
            ),
          ),
          ListTile(
            title: const Text('Paksa Mode Offline'),
            subtitle: const Text(
              'Simulasi offline untuk menguji cache-first',
            ),
            trailing: Switch(
              value: forceOffline,
            onChanged: (v) => ref.read(forceOfflineProvider.notifier).set(v),
            ),
          ),
        ],
      ),
    );
  }
}