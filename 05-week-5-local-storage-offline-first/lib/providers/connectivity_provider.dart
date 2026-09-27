import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notifier manual untuk toggle offline (pengganti StateProvider di Riverpod 3.x)
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.every((r) => r == ConnectivityResult.none);
  }
});

final isOfflineProvider = Provider<bool>((ref) {
  final force = ref.watch(forceOfflineProvider);
  final real = ref.watch(connectivityProvider).value ?? false;
  return force || real;
});