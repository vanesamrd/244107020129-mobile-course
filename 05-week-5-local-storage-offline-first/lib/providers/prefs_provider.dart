import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/prefs.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>(
  (ref) => PrefsRepository(),
);

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(prefsRepositoryProvider).getDarkMode();
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    final next = !current;
    state = AsyncData(next);
    await ref.read(prefsRepositoryProvider).setDarkMode(next);
  }
}