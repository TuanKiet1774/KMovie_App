class Movie {
  final String name;
  final String slug;
  final String posterUrl;
  final String description;
  final int year;
  final List<String> categories;
  final String quality;
  final String language;

  Movie({
    required this.name,
    required this.slug,
    required this.posterUrl,
    required this.description,
    required this.year,
    required this.categories,
    required this.quality,
    required this.language,
  });

  // Chuyển đổi từ JSON sang đối tượng Movie
  factory Movie.fromJson(Map<String, dynamic> json) {
    //Lấy đường dẫn poster
    String resolvePosterUrl(String? path) {
      if (path == null || path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return 'https://phimimg.com/$path';
    }
    //Lấy năm phát hành
    int parseYear() {
      if (json['year'] is int) return json['year'];
      if (json['year'] is String) {
        return int.tryParse(json['year']) ?? 0;
      }
      final created = json['created']?['time'];
      if (created != null && created is String && created.length >= 4) {
        return int.tryParse(created.substring(0, 4)) ?? 0;
      }
      return 0;
    }

    return Movie(
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      posterUrl: resolvePosterUrl(json['poster_url'] ?? json['thumb_url']),
      description: json['content'] ?? '',
      year: parseYear(),
      categories: (json['category'] as List<dynamic>?)
          ?.map((x) => x['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList() ??
          [],
      quality: json['quality'] ?? '',
      language: json['lang'] ?? 'Vietsub',
    );
  }

}