import 'package:flutter_test/flutter_test.dart';

import 'package:week4_networking_rest_api/data/models/comment.dart';

void main() {
  /// Test pertama sesuai requirement AI Challenge.
  ///
  /// Test ini memastikan Comment.fromJson tidak crash
  /// ketika beberapa field tidak tersedia.
  test('Comment.fromJson aman terhadap field yang hilang', () {
    final comment = Comment.fromJson({
      'id': 7,
    });

    expect(comment.id, 7);
    expect(comment.postId, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });

  /// Edge case tambahan.
  ///
  /// Selain field hilang, kita menguji seluruh field bernilai null.
  /// Aplikasi seharusnya tetap menghasilkan object Comment
  /// tanpa menyebabkan exception.
  test('Comment.fromJson aman terhadap field bernilai null', () {
    final comment = Comment.fromJson({
      'postId': null,
      'id': null,
      'name': null,
      'email': null,
      'body': null,
    });

    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}