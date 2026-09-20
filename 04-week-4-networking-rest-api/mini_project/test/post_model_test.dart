import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_project/data/models/post.dart';
import 'package:mini_project/data/network_errors.dart';

void main() {
  group('Post.fromJson', () {
    test('should parse valid JSON safely and map to Post', () {
      final json = {
        'userId': 1,
        'id': 10,
        'title': 'sunt aut facere repellat provident occaecati excepturi optio reprehenderit',
        'body': 'quia et suscipit\nsuscipit recusandae consequuntur expedita et cum\nreprehenderit molestiae ut ut quas totam\nnostrum rerum est autem sunt rem eveniet architecto',
      };

      final post = Post.fromJson(json);

      expect(post.userId, 1);
      expect(post.id, 10);
      expect(post.title, isNotEmpty);
      expect(post.body, isNotEmpty);
    });

    test('should return safe defaults when JSON is null or missing', () {
      final post = Post.fromJson({});

      expect(post.userId, 0);
      expect(post.id, 0);
      expect(post.title, '');
      expect(post.body, '');
    });
  });

  group('friendlyErrorMessage', () {
    test('should map timeout DioException to user-friendly text', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/posts'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        friendlyErrorMessage(error),
        'Koneksi lambat atau timeout. Coba lagi.',
      );
    });
  });
}
