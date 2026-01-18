class ReportModel {
  final int id;
  final String title;
  final String description;
  final String category;
  final String status;
  final String date;
  final int imageCount;

  ReportModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.date,
    required this.imageCount,
  });

  // 🔥 DARI API LARAVEL
  factory ReportModel.fromApi(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] != null
          ? json['category']['name']
          : '-',
      status: json['status'] ?? 'Diproses',
      date: json['created_at'] ?? '',
      imageCount: json['media'] != null
          ? (json['media'] as List).length
          : 0,
    );
  }

  static fromJson(json) {}
}
