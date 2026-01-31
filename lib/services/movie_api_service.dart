import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie.dart';
import '../models/movie_detail.dart';

class MovieApiService {
  // URL cơ sở của API
  static const String baseUrl = 'https://phimapi.com';
  static const String backendUrl = 'https://movie-be-dz6l.onrender.com';

  // --- Watch Later API ---

  // Thêm vào Watch Later
  static Future<bool> addToWatchLater(String deviceId, String movieSlug) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/watch-later'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': deviceId,
          'movieSlug': movieSlug,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 409) {
        print('Phim đã có trong danh sách Xem Sau.');
        return false;
      } else {
        throw Exception('Lỗi khi thêm vào Xem Sau: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi thêm vào Xem Sau: $e');
      rethrow;
    }
  }

  // Lấy danh sách Watch Later (chỉ lấy movieSlugs)
  static Future<List<String>> getWatchLaterSlugs(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/watch-later/$deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item['movieSlug'] as String).toList();
      } else {
        throw Exception('Lỗi khi tải danh sách Xem Sau: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải danh sách Xem Sau: $e');
      return [];
    }
  }

  // Xóa khỏi Watch Later
  static Future<void> removeFromWatchLater(String deviceId, String movieSlug) async {
    try {
      final response = await http.delete(
        Uri.parse('$backendUrl/watch-later'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': deviceId,
          'movieSlug': movieSlug,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 404) {
        throw Exception('Lỗi khi xóa khỏi Xem Sau: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi xóa khỏi Xem Sau: $e');
      rethrow;
    }
  }

  // Kiểm tra xem đã có trong Watch Later chưa
  static Future<bool> checkWatchLater(String deviceId, String movieSlug) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/watch-later/check/status?deviceId=$deviceId&movieSlug=$movieSlug'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Lỗi khi kiểm tra Xem Sau: $e');
      return false;
    }
  }

  // Lấy danh sách phim mới nhất từ API
  static Future<List<Movie>> getLatestMovies() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/danh-sach/phim-moi-cap-nhat'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> moviesList = data['items'] ?? [];
        return moviesList.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải danh sách phim: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải danh sách phim: $e');
      return [];
    }
  }

  // Tìm kiếm phim theo từ khóa
  static Future<List<Movie>> searchMovies(String keyword) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/api/tim-kiem?keyword=${Uri.encodeComponent(keyword)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> moviesList = data['data']['items'] ?? [];
        return moviesList.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tìm kiếm phim: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tìm kiếm phim: $e');
      return [];
    }
  }

  // Lấy chi tiết phim theo slug
  static Future<MovieDetail?> getMovieDetail(String slug) async {
    try {
      print('Đang tải slug: $slug');
      print('URL: $baseUrl/phim/$slug');

      final response = await http.get(
        Uri.parse('$baseUrl/phim/$slug'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Trạng thái: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('Đã nhận trạng thái!');
        print('Trạng thái: ${data['status']}');

        // Kiểm tra status trong response
        if (data['status'] != true) {
          final errorMsg = data['msg'] ?? 'Thất bại tải dữ liệu';
          print('Lỗi: $errorMsg');
          throw Exception(errorMsg);
        }

        // Kiểm tra movie data
        if (data['movie'] == null) {
          print('Không tìm thấy phim!');
          throw Exception('Không tìm thấy phim');
        }

        print('Phim: ${data['movie']['name']}');
        print('Tập: ${(data['episodes'] as List?)?.length ?? 0}');

        // Parse sử dụng factory method mới
        final movieDetail = MovieDetail.fromApiResponse(data);

        print('Hoàn tất tải dữ liệu!');
        return movieDetail;

      } else {
        print('Lỗi: ${response.statusCode}');
        print('Trả lời: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Lỗi: $e');
      print('Stack: ${StackTrace.current}');
      rethrow; // Re-throw để controller có thể handle
    }
  }

  // Lấy danh sách phim theo thể loại
  static Future<List<Movie>> getMoviesByCategory(String categorySlug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/v1/api/danh-sach/$categorySlug'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> moviesList = data['data']['items'] ?? [];
        return moviesList.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải phim theo thể loại: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải phim theo thể loại: $e');
      return [];
    }
  }

  // Lấy phim theo thể loại (method mới cho home screen)
  static Future<List<Movie>> getMoviesByGenre(String genreSlug) async {
    try {
      // Thử các endpoint khác nhau của API phimapi.com
      List<String> possibleUrls = [
        '$baseUrl/v1/api/the-loai/$genreSlug',
        '$baseUrl/danh-sach/$genreSlug',
        '$baseUrl/the-loai/$genreSlug',
      ];

      for (String url in possibleUrls) {
        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            // Thử các cấu trúc response khác nhau
            List<dynamic> moviesList = [];

            if (data['items'] != null) {
              moviesList = data['items'];
            } else if (data['data'] != null && data['data']['items'] != null) {
              moviesList = data['data']['items'];
            } else if (data is List) {
              moviesList = data;
            }

            if (moviesList.isNotEmpty) {
              return moviesList.map((json) => Movie.fromJson(json)).toList();
            }
          }
        } catch (e) {
          print('Thử URL tiếp theo: $url - Lỗi: $e');
          continue;
        }
      }

      // Nếu không có endpoint nào hoạt động, fallback về tìm kiếm
      return await _searchMoviesByGenre(genreSlug);

    } catch (e) {
      print('Lỗi khi tải phim theo thể loại: $e');
      return [];
    }
  }

  // Fallback: tìm kiếm phim theo thể loại thông qua tìm kiếm
  static Future<List<Movie>> _searchMoviesByGenre(String genreSlug) async {
    try {
      // Chuyển slug thành từ khóa tìm kiếm
      final searchKeywords = _slugToSearchKeyword(genreSlug);

      if (searchKeywords.isNotEmpty) {
        final searchResults = await searchMovies(searchKeywords);
        return searchResults.take(20).toList(); // Giới hạn 20 kết quả
      }

      return [];
    } catch (e) {
      print('Lỗi khi tìm kiếm phim theo thể loại: $e');
      return [];
    }
  }

  // Chuyển đổi slug thành từ khóa tìm kiếm
  static String _slugToSearchKeyword(String slug) {
    final slugToKeyword = {
      'hanh-dong': 'hành động',
      'phieu-luu': 'phiêu lưu',
      'hai-huoc': 'hài hước',
      'tinh-cam': 'tình cảm',
      'kinh-di': 'kinh dị',
      'khoa-hoc-vien-tuong': 'khoa học viễn tưởng',
      'tam-ly': 'tâm lý',
      'chien-tranh': 'chiến tranh',
      'hoat-hinh': 'hoạt hình',
    };

    return slugToKeyword[slug] ?? '';
  }

  // Lấy danh sách thể loại có sẵn từ API
  static Future<List<Map<String, dynamic>>> getGenresList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/the-loai'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
      }

      // Fallback: trả về danh sách thể loại cố định
      return [
        {'name': 'Hành Động', 'slug': 'hanh-dong'},
        {'name': 'Phiêu Lưu', 'slug': 'phieu-luu'},
        {'name': 'Hài Hước', 'slug': 'hai-huoc'},
        {'name': 'Tình Cảm', 'slug': 'tinh-cam'},
        {'name': 'Kinh Dị', 'slug': 'kinh-di'},
        {'name': 'Khoa Học Viễn Tưởng', 'slug': 'khoa-hoc-vien-tuong'},
        {'name': 'Tâm Lý', 'slug': 'tam-ly'},
        {'name': 'Chiến Tranh', 'slug': 'chien-tranh'},
        {'name': 'Hoạt Hình', 'slug': 'hoat-hinh'},
      ];
    } catch (e) {
      print('Lỗi khi tải danh sách thể loại: $e');
      return [];
    }
  }

  // Lấy phim theo quốc gia
  static Future<List<Movie>> getMoviesByCountry(String countrySlug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quoc-gia/$countrySlug'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> moviesList = data['items'] ?? [];
        return moviesList.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải phim theo quốc gia: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải phim theo quốc gia: $e');
      return [];
    }
  }

  // Lấy phim theo năm
  static Future<List<Movie>> getMoviesByYear(int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/nam/$year'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> moviesList = data['items'] ?? [];
        return moviesList.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi khi tải phim theo năm: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tải phim theo năm: $e');
      return [];
    }
  }
}