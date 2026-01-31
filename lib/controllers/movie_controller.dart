import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../services/movie_api_service.dart';

class MovieController extends GetxController {
  final MovieApiService movieApi = MovieApiService();
  List<Movie> _watchLaterMovies = [];
  List<Movie> get watchLaterMovies => _watchLaterMovies;

  List<Movie> _movies = [];
  List<Movie> get movies => _movies;

  // Chi tiết phim hiện tại
  MovieDetail? _currentMovieDetail;
  MovieDetail? get currentMovieDetail => _currentMovieDetail;

  // Trạng thái đang tải dữ liệu
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isWatchLaterLoading = false;
  bool get isWatchLaterLoading => _isWatchLaterLoading;

  // Thông báo lỗi
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Từ khóa tìm kiếm hiện tại
  String _currentSearchKeyword = '';
  String get currentSearchKeyword => _currentSearchKeyword;

  @override
  void onInit() {
    super.onInit();
    loadWatchLater(); // Tải danh sách xem sau ngay khi controller khởi tạo
  }

  // Phương thức tải danh sách phim mới nhất
  Future<void> loadLatestMovies() async {
    _setLoading(true);
    _clearError();

    try {
      final movies = await MovieApiService.getLatestMovies();
      _movies = movies;
      _currentSearchKeyword = '';
      update();
    } catch (e) {
      _setError('Không thể tải danh sách phim. Vui lòng thử lại sau.');
    } finally {
      _setLoading(false);
    }
  }

  // Phương thức tìm kiếm phim theo từ khóa
  Future<void> searchMovies(String keyword) async {
    if (keyword.trim().isEmpty) {
      await loadLatestMovies();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final movies = await MovieApiService.searchMovies(keyword.trim());
      _movies = movies;
      _currentSearchKeyword = keyword.trim();
      update();
    } catch (e) {
      _setError('Không thể tìm kiếm phim. Vui lòng thử lại sau.');
    } finally {
      _setLoading(false);
    }
  }

  // Phương thức tải chi tiết phim
  Future<void> loadMovieDetail(String slug) async {
    _setLoading(true);
    _clearError();

    try {
      final detail = await MovieApiService.getMovieDetail(slug);
      _currentMovieDetail = detail;
      update();
    } catch (e) {
      _setError('Không thể tải chi tiết phim. Vui lòng thử lại sau.');
    } finally {
      _setLoading(false);
    }
  }

  // Phương thức tải phim theo thể loại
  Future<void> loadMoviesByCategory(String categorySlug) async {
    _setLoading(true);
    _clearError();

    try {
      final movies = await MovieApiService.getMoviesByCategory(categorySlug);
      _movies = movies;
      _currentSearchKeyword = '';
      update();
    } catch (e) {
      _setError('Không thể tải phim theo thể loại. Vui lòng thử lại sau.');
    } finally {
      _setLoading(false);
    }
  }

  // Lấy hoặc tạo device ID duy nhất, lưu trong SharedPreferences
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4(); // tạo UUID mới
      await prefs.setString('device_id', deviceId);
    }
    return deviceId;
  }

  // Hàm tải danh sách Xem Sau từ Backend API, rồi gọi API lấy chi tiết từng phim
  Future<void> loadWatchLater() async {
    if (_isWatchLaterLoading) return;
    
    _isWatchLaterLoading = true;
    update();
    
    final deviceId = await getDeviceId();

    try {
      final List<String> slugs = await MovieApiService.getWatchLaterSlugs(deviceId);
      final List<Movie> loadedMovies = [];

      for (var slug in slugs) {
        try {
          final detail = await MovieApiService.getMovieDetail(slug);
          if (detail != null) {
            loadedMovies.add(Movie(
              name: detail.name,
              slug: detail.slug,
              posterUrl: detail.posterUrl,
              description: detail.description,
              year: detail.year,
              categories: detail.categories,
              quality: detail.quality,
              language: detail.language,
            ));
          }
        } catch (e) {
          print('Lỗi khi lấy chi tiết phim $slug: $e');
        }
      }

      _watchLaterMovies = loadedMovies;
    } catch (e) {
      print('Lỗi khi tải danh sách Xem Sau: $e');
      _setError('Không thể tải danh sách xem sau');
    } finally {
      _isWatchLaterLoading = false;
      update();
    }
  }

  Future<void> removeFromWatchLater(String slug) async {
    final deviceId = await getDeviceId();

    try {
      await MovieApiService.removeFromWatchLater(deviceId, slug);
      print('Đã xóa phim $slug khỏi danh sách Xem Sau.');
    } catch (e) {
      print('Lỗi khi xóa khỏi Xem Sau: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Thêm vào xem sau
  Future<bool> addToWatchLater(String slug) async {
    final deviceId = await getDeviceId();

    try {
      final success = await MovieApiService.addToWatchLater(deviceId, slug);
      if (success) {
        print('Đã lưu phim $slug vào danh sách Xem Sau.');
      }
      return success;
    } catch (e, stackTrace) {
      print('═══════════════════════════════════════');
      print('❌ LỖI KHI LƯU XEM SAU:');
      print('Lỗi: $e');
      print('Stack: $stackTrace');
      print('═══════════════════════════════════════');
      throw e; // Re-throw to handle in UI
    }
  }

  // Phương thức riêng tư để cập nhật trạng thái loading
  void _setLoading(bool loading) {
    _isLoading = loading;
    update();
  }

  // Phương thức riêng tư để cập nhật thông báo lỗi
  void _setError(String error) {
    _errorMessage = error;
    update();
  }

  // Phương thức riêng tư để xóa thông báo lỗi
  void _clearError() {
    _errorMessage = null;
  }

  // Phương thức làm mới danh sách phim
  Future<void> refreshMovies() async {
    if (_currentSearchKeyword.isNotEmpty) {
      await searchMovies(_currentSearchKeyword);
    } else {
      await loadLatestMovies();
    }
  }
}