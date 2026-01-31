import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kmovie/screens/watch_later_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/movie.dart';
import '../services/movie_api_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_dialogs.dart';
import 'movie_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Movie> _movies = [];
  bool _isLoading = true;
  String _selectedCategory = ''; // Thể loại được chọn mặc định

  TextEditingController _searchController = TextEditingController();
  SpeechToText _speechToText = SpeechToText();
  bool _isListening = false; // trạng thái đang nghe giọng nói

  @override
  void initState() {
    super.initState();
    _loadLatestMovies();
  }

  Future<void> _loadLatestMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await MovieApiService.getLatestMovies();
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppDialogs.showError(context, 'Không thể tải danh sách phim. Vui lòng thử lại sau.');
    }
  }

  Future<void> _searchMovies(String keyword) async {
    if (keyword.trim().isEmpty) {
      _loadLatestMovies();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final movies = await MovieApiService.searchMovies(keyword.trim());
      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppDialogs.showError(context, 'Không thể tìm kiếm phim. Vui lòng thử lại sau.');
    }
  }

  // Danh sách thể loại phim
  final List<String> _categories = [
    'Tất cả',
    'Hành Động',
    'Cổ Trang',
    'Viễn Tưởng',
    'Tình Cảm',
    'Tâm Lý',
    'Thể Thao',
    'Phiêu Lưu',
    'Âm Nhạc',
    'Gia Đình',
    'Học Đường',
    'Hài Hước',
    'Hình Sự',
    'Võ Thuật',
    'Khoa Học',
  ];
  // Mapping thể loại sang slug API
  String _getCategorySlug(String category) {
    final categoryMap = {
      'Tất cả': '',
      'Hành Động': 'hanh-dong',
      'Cổ Trang': 'co-trang',
      'Viễn Tưởng': 'vien-tuong',
      'Tình Cảm': 'tinh-cam',
      'Tâm Lý': 'tam-ly',
      'Thể Thao': 'the-thao',
      'Phiêu Lưu': 'phieu-luu',
      'Âm Nhạc': 'am-nhac',
      'Gia Đình': 'gia-dinh',
      'Học Đường': 'hoc-duong',
      'Hài Hước': 'hai-huoc',
      'Hình Sự': 'hinh-su',
      'Võ Thuật': 'vo-thuat',
      'Khoa Học': 'khoa-hoc',
    };
    return categoryMap[category] ?? '';
  }

  // Lọc phim theo thể loại
  Future<void> _filterMoviesByCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });

    try {
      List<Movie> movies;
      final categorySlug = _getCategorySlug(category);
      if (categorySlug.isNotEmpty) {
        movies = await MovieApiService.getMoviesByGenre(categorySlug);
      } else {
        // Fallback: tải phim mới nhất
        movies = await MovieApiService.getLatestMovies();
      }

      setState(() {
        _movies = movies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppDialogs.showError(context, 'Không thể lọc phim theo thể loại.');
    }
  }

  // Toggle bắt đầu/dừng nghe giọng nói
  void toggleVoiceSearch() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      bool available = await _speechToText.initialize(
        onStatus: (status) {
          print("Trạng thái: $status");
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          print("Lỗi: $error");
          setState(() {
            _isListening = false;
          });
          AppDialogs.showError(context, "Lỗi khi nhận dạng giọng nói: ${error.errorMsg}");
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
        });

        _speechToText.listen(
          onResult: (result) {
            final spokenText = result.recognizedWords;

            setState(() {
              _searchController.text = spokenText;
              _searchController.selection = TextSelection.fromPosition(
                TextPosition(offset: _searchController.text.length),
              );
            });

            _searchMovies(spokenText);
          },
        );
      } else {
        AppDialogs.showError(context, "Thiết bị không hỗ trợ nhận dạng giọng nói.");
      }
    }
  }


  void _onMovieTapped(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MovieDetailScreen(movie: movie),
      ),
    );
  }


  // Widget để hiển thị menu thể loại
  Widget _buildCategoryMenu() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.take(22).length, // Chỉ hiển thị toàn bộ thể loại
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Container(
            margin: EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _filterMoviesByCategory(category),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.grey[600]!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final shouldExit = await AppDialogs.showExitConfirm(context);
        if (shouldExit) {
          SystemNavigator.pop(); // Thoát ứng dụng hoàn toàn
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset('assets/icons/logo.png', height: 30),
          centerTitle: true,
          leading: Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.menu, color: Colors.white, size: 22.0),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WatchLaterScreen()),
                );
              },
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white, size: 22.0),
              onPressed: _loadLatestMovies,
            ),
          ],
        ),
        body: Column(
          children: [
            SearchBarWidget(
              controller: _searchController,
              onSearch: _searchMovies,
              onVoiceSearch: toggleVoiceSearch,
              isListening: _isListening,
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Đang nghe...',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            _buildCategoryMenu(),
            Expanded(child: _buildMovieList()),
          ],
        ),
      ),
    );
  }


  Widget _buildMovieList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Đang tải phim...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy phim nào',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: _loadLatestMovies,
              child: Text(
                'Thử lại',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _movies.length,
      itemBuilder: (context, index) {
        return MovieCard(
          movie: _movies[index],
          onTap: () => _onMovieTapped(_movies[index]),
        );
      },
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _searchController.dispose();
    super.dispose();
  }
}