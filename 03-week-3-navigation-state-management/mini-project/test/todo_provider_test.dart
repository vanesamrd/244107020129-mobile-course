import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mini_project/providers/todo_provider.dart';

void main() {
  test('Todo bisa ditambahkan dan diselesaikan', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(todoProvider), isEmpty);

    container.read(todoProvider.notifier).addTodo('Belajar Flutter');

    expect(container.read(todoProvider).length, 1);
    expect(
      container.read(todoProvider)[0].title,
      'Belajar Flutter',
    );
    expect(
      container.read(todoProvider)[0].isDone,
      false,
    );

    container.read(todoProvider.notifier).toggleTodo(0);

    expect(
      container.read(todoProvider)[0].isDone,
      true,
    );
  });
}