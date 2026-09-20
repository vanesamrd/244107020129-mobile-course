/// Model untuk data komentar dari endpoint:
/// GET /comments?postId={id}
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Mengubah JSON dari API menjadi object Comment.
  ///
  /// Casting dibuat defensif agar aplikasi tidak crash
  /// ketika field tidak ada, bernilai null, atau tipe datanya
  /// tidak sesuai dengan yang diharapkan.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      // num digunakan agar int maupun tipe angka lain
      // dapat dikonversi menjadi int.
      postId: (json['postId'] as num?)?.toInt() ?? 0,

      // Jika id tidak tersedia, gunakan nilai default 0.
      id: (json['id'] as num?)?.toInt() ?? 0,

      // Jika name tidak tersedia atau null, gunakan String kosong.
      name: json['name'] as String? ?? '',

      // Jika email tidak tersedia atau null, gunakan String kosong.
      email: json['email'] as String? ?? '',

      // Jika body tidak tersedia atau null, gunakan String kosong.
      body: json['body'] as String? ?? '',
    );
  }

  /// Mengubah object Comment kembali menjadi JSON.
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'id': id,
      'name': name,
      'email': email,
      'body': body,
    };
  }
}