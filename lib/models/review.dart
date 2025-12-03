// Modelo de review (reseña)
class Review {
  final String id;
  final String author;
  final String content;
  final String? url;

  Review({
    required this.id,
    required this.author,
    required this.content,
    this.url,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      author: json['author'] ?? '',
      content: json['content'] ?? '',
      url: json['url'],
    );
  }
}