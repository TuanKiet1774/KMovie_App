import 'episode.dart';

class MovieDetail {
  final String name;
  final String slug;
  final String posterUrl;
  final String description;
  final int year;
  final List<String> categories;
  final String quality;
  final String language;
  final String episodeCount;
  final List<Episode> episodes;
  final String director;
  final List<String> actors;
  final String country;
  final int time;

  MovieDetail({
    required this.name,
    required this.slug,
    required this.posterUrl,
    required this.description,
    required this.year,
    required this.categories,
    required this.quality,
    required this.language,
    required this.episodeCount,
    required this.episodes,
    required this.director,
    required this.actors,
    required this.country,
    required this.time,
  });

  factory MovieDetail.fromApiResponse(Map<String, dynamic> apiResponse) {
    final movieJson = apiResponse['movie'];
    final episodesJson = apiResponse['episodes'] ?? [];

    return MovieDetail.fromJson(movieJson, episodesJson);
  }

  factory MovieDetail.fromJson(Map<String, dynamic> movieJson, List<dynamic> episodesJson) {
    return MovieDetail(
      name: movieJson['name']?.toString() ?? '',
      slug: movieJson['slug']?.toString() ?? '',
      posterUrl: movieJson['poster_url']?.toString() ?? '',
      description: movieJson['content']?.toString() ?? '',
      year: movieJson['year'] is int ? movieJson['year'] : (int.tryParse(movieJson['year']?.toString() ?? '') ?? 0),
      categories: _parseCategories(movieJson['category']),
      quality: movieJson['quality']?.toString() ?? '',
      language: movieJson['lang']?.toString() ?? '',
      episodeCount: movieJson['episode_total']?.toString() ?? '',
      episodes: _parseEpisodes(episodesJson),
      director: _parseDirector(movieJson['director']),
      actors: _parseActors(movieJson['actor']),
      country: _parseCountry(movieJson['country']),
      time: int.tryParse(movieJson['time']?.toString() ?? '') ?? 0,
    );
  }

  static List<String> _parseCategories(dynamic categoriesData) {
    if (categoriesData == null) return [];
    if (categoriesData is List) {
      return categoriesData
          .where((x) => x != null && x is Map<String, dynamic>)
          .map((x) => x['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    }
    return [];
  }

  static List<Episode> _parseEpisodes(List<dynamic> episodesData) {
    try {
      return episodesData
          .where((e) => e != null && e is Map<String, dynamic>)
          .map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Lỗi: $e');
      return [];
    }
  }

  static String _parseDirector(dynamic directorData) {
    if (directorData == null) return '';
    if (directorData is List) {
      return directorData
          .where((d) => d != null)
          .map((d) => d.toString())
          .where((d) => d.isNotEmpty)
          .join(', ');
    }
    return directorData.toString();
  }

  static List<String> _parseActors(dynamic actorsData) {
    if (actorsData == null) return [];
    if (actorsData is List) {
      return actorsData
          .where((a) => a != null)
          .map((a) => a.toString())
          .where((a) => a.isNotEmpty)
          .toList();
    }
    return [];
  }

  static String _parseCountry(dynamic countryData) {
    if (countryData == null) return '';
    if (countryData is List) {
      return countryData
          .where((c) => c != null)
          .map((c) {
        if (c is Map<String, dynamic>) {
          return c['name']?.toString() ?? c.toString();
        }
        return c.toString();
      })
          .where((c) => c.isNotEmpty)
          .join(', ');
    }
    return countryData.toString();
  }
}
