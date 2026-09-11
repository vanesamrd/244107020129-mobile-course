import 'package:flutter_riverpod/flutter_riverpod.dart';

class Todo {
  final String title;
  final bool isDone;

  Todo({
    required this.title,
    this.isDone = false,
  });
}

class TodoNotifier extends Notifier<List<Todo>> {
  @override
  List<Todo> build() {
    return [];
  }

  void addTodo(String title) {
    state = [
      ...state,
      Todo(title: title),
    ];
  }

  void toggleTodo(int index) {
    final todos = [...state];

    todos[index] = Todo(
      title: todos[index].title,
      isDone: !todos[index].isDone,
    );

    state = todos;
  }

  void deleteTodo(int index) {
    final todos = [...state];
    todos.removeAt(index);

    state = todos;
  }
}

final todoProvider =
    NotifierProvider<TodoNotifier, List<Todo>>(TodoNotifier.new);