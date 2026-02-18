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

  // Quản lý tập đã xem theo slug phim
  final Map<String, Set<String>> _watchedEpisodesByUser = {};
  Set<String> getWatchedEpisodes(String slug) => _watchedEpisodesByUser[slug] ?? {};

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

  // Danh sách phim cho Banner (Slide trên cùng)
  List<Movie> _bannerMovies = [];
  List<Movie> get bannerMovies => _bannerMovies;

  // Map chứa danh sách phim theo thể loại cho Home Screen
  Map<String, List<Movie>> _categoryMovies = {};
  Map<String, List<Movie>> get categoryMovies => _categoryMovies;

  // Các thể loại hiển thị trên trang chủ
  final List<String> homeCategories = ['tinh-cam', 'co-trang', 'hanh-dong'];
  final Map<String, String> categoryTitles = {
    'tinh-cam': 'Phim Tình Cảm',
    'co-trang': 'Phim Cổ Trang',
    'hanh-dong': 'Phim Hành Động',
  };

  @override
  void onInit() {
    super.onInit();
    loadWatchLater();
    loadHomeData(); 
  }

  // Tải dữ liệu tổng hợp cho trang chủ
  Future<void> loadHomeData() async {
    _setLoading(true);
    _clearError();

    try {
      _categoryMovies.clear();
      
      // Tải song song cả Banner và Danh sách thể loại để tối ưu tốc độ
      await Future.wait([
        // Task 1: Tải Banner
        MovieApiService.getLatestMovies().then((movies) {
          _bannerMovies = movies;
          // Mặc định _movies chính là banner movies khi ở chế độ "Tất cả"
          _movies = _bannerMovies; 
        }),

        // Task 2: Tải các categories
        Future.wait(homeCategories.map((slug) async {
          try {
             // Giới hạn 10 phim mỗi category để load nhanh hơn
             final movies = await MovieApiService.getMoviesByGenre(slug, page: 1, limit: 10);
             _categoryMovies[slug] = movies;
          } catch (e) {
             print('Lỗi tải category $slug: $e');
             _categoryMovies[slug] = [];
          }
        }))
      ]);

      // Quan trọng: Xóa từ khóa tìm kiếm để quay về giao diện mặc định
      _currentSearchKeyword = '';
      update();
    } catch (e) {
      _setError('Không thể tải dữ liệu trang chủ: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Phương thức tải phim theo thể loại (được chọn từ dropdown hoặc menu)
  Future<void> loadMoviesByCategory(String categorySlug) async {
    _setLoading(true);
    _clearError();

    try {
      if (categorySlug.isEmpty || categorySlug == 'all') {
        // Nếu chọn "Tất cả", load lại Home Data chuẩn
        if (_bannerMovies.isEmpty) {
           await loadHomeData();
        } else {
           _movies = _bannerMovies; 
           _currentSearchKeyword = '';
           update();
        }
      } else {
        // Nếu chọn thể loại cụ thể => Load danh sách phim của thể loại đó vào _movies (để hiển thị lưới/list chính)
        final movies = await MovieApiService.getMoviesByGenre(categorySlug, page: 1, limit: 20);
        _movies = movies;
        _currentSearchKeyword = '';
        update();
      }
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

    try {
      final deviceId = await getDeviceId();
      final slugs = await MovieApiService.getWatchLaterSlugs(deviceId);

      final movies = await Future.wait(
        slugs.map((slug) async {
          try {
            final detail = await MovieApiService.getMovieDetail(slug);
            if (detail == null) return null;

            return Movie(
              name: detail.name,
              slug: detail.slug,
              posterUrl: detail.posterUrl,
              description: detail.description,
              year: detail.year,
              categories: detail.categories,
              quality: detail.quality,
              language: detail.language,
            );
          } catch (e) {
            print('Lỗi khi lấy chi tiết phim $slug: $e');
            return null;
          }
        }),
      );

      _watchLaterMovies = movies.whereType<Movie>().toList();
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

  // Load danh sách tập đã xem từ SharedPreferences
  Future<void> loadWatchedEpisodes(String movieSlug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'watched_$movieSlug';
      final watched = prefs.getStringList(key) ?? [];
      _watchedEpisodesByUser[movieSlug] = watched.toSet();
      update();
    } catch (e) {
      print('Lỗi khi load tập đã xem cho $movieSlug: $e');
    }
  }

  // Đánh dấu tập đã xem và thông báo realtime
  Future<void> markEpisodeAsWatched(String movieSlug, String serverName, String episodeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'watched_$movieSlug';
      final episodeKey = '${serverName}_${episodeName}';
      
      if (!_watchedEpisodesByUser.containsKey(movieSlug)) {
        _watchedEpisodesByUser[movieSlug] = {};
      }
      
      if (!_watchedEpisodesByUser[movieSlug]!.contains(episodeKey)) {
        _watchedEpisodesByUser[movieSlug]!.add(episodeKey);
        await prefs.setStringList(key, _watchedEpisodesByUser[movieSlug]!.toList());
        print('✅ [Controller] Đã đánh dấu đã xem: $episodeKey');
        update(); // Thông báo cho UI update realtime
      }
    } catch (e) {
      print('Lỗi khi lưu tập đã xem: $e');
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
      await loadHomeData();
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

  // Phương thức làm mới danh sách phim
  Future<void> refreshMovies() async {
    if (_currentSearchKeyword.isNotEmpty) {
      await searchMovies(_currentSearchKeyword);
    } else {
      await loadHomeData();
    }
  }
}