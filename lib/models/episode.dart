class Episode {
  final String serverName;
  final List<EpisodeData> serverData;

  Episode({
    required this.serverName,
    required this.serverData,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      serverName: json['server_name'] ?? '',
      serverData: (json['server_data'] as List<dynamic>?)
          ?.map((data) => EpisodeData.fromJson(data))
          .toList() ?? [],
    );
  }
}

class EpisodeData {
  final String name;
  final String slug;
  final String filename;
  final String linkM3u8;

  EpisodeData({
    required this.name,
    required this.slug,
    required this.filename,
    required this.linkM3u8,
  });

  // Chuyển đổi từ JSON sang đối tượng Episode
  factory EpisodeData.fromJson(Map<String, dynamic> json) {
    return EpisodeData(
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      linkM3u8: json['link_m3u8']?.toString() ?? '',
    );
  }
}