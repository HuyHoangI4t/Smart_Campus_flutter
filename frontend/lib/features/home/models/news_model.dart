class NewsModel {
  final int id;
  final String title;
  final String summary;
  final String? content;
  final String? imageUrl;
  final String? publishedAt;
  final String category;
  final String? author;

  const NewsModel({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    this.imageUrl,
    this.publishedAt,
    this.category = 'Tin tức',
    this.author,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Thông báo',
      summary: json['summary'] ?? json['description'] ?? '',
      content: json['content'] ?? json['summary'],
      imageUrl: json['image_url'] ?? json['imageUrl'],
      publishedAt: json['published_at'] ?? json['created_at'],
      category: json['category'] ?? 'Thông báo',
      author: json['author'] ?? json['sender'] ?? 'Ban Biên tập TTN',
    );
  }
}

