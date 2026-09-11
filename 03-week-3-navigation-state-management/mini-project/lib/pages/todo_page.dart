import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/todo_provider.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo List'),
      ),
      body: todos.isEmpty
          ? const Center(
              child: Text('Belum ada tugas'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];

                return Card(
                  child: ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (_) {
                        ref.read(todoProvider.notifier).toggleTodo(index);
                      },
                    ),
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        decoration:
                            todo.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        ref.read(todoProvider.notifier).deleteTodo(index);
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTodoDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Tugas'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Masukkan tugas',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref
                      .read(todoProvider.notifier)
                      .addTodo(controller.text.trim());
                }

                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}