import 'dart:async';
import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_api_service.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  // Trạng thái thể loại đang chọn
  String _selectedCategory = 'Tất cả';
  String _selectedSlug = 'all';

  // Dữ liệu gợi ý: Phim mới cập nhật (khi slug == 'all')
  final ScrollController _scrollController = ScrollController();
  final List<Movie> _suggestedMovies = [];
  int _suggestionPage = 1;
  bool _isLoadingSuggestions = false;
  bool _hasMoreSuggestions = true;

  // Dữ liệu duyệt theo thể loại (khi slug != 'all')
  final List<Movie> _genreMovies = [];
  int _genrePage = 1;
  bool _isLoadingGenre = false;
  bool _hasMoreGenre = true;

  // Dữ liệu tìm kiếm từ khóa
  List<Movie> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestedMovies();
    _scrollController.addListener(_onScroll);
    // Tự động focus vào thanh tìm kiếm khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_searchController.text.trim().isEmpty) {
        if (_selectedSlug == 'all') {
          if (!_isLoadingSuggestions && _hasMoreSuggestions) {
            _loadSuggestedMovies();
          }
        } else {
          if (!_isLoadingGenre && _hasMoreGenre) {
            _loadGenreMovies();
          }
        }
      }
    }
  }

  Future<void> _loadSuggestedMovies() async {
    if (_isLoadingSuggestions || !_hasMoreSuggestions) return;

    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final movies = await MovieApiService.getLatestMovies(page: _suggestionPage);
      if (mounted) {
        setState(() {
          if (movies.isEmpty) {
            _hasMoreSuggestions = false;
          } else {
            _suggestedMovies.addAll(movies);
            _suggestionPage++;
            if (movies.length < 10) _hasMoreSuggestions = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải phim gợi ý: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _loadGenreMovies() async {
    if (_isLoadingGenre || !_hasMoreGenre || _selectedSlug == 'all') return;

    setState(() {
      _isLoadingGenre = true;
    });

    try {
      final movies = await MovieApiService.getMoviesByGenre(
        _selectedSlug,
        page: _genrePage,
        limit: 12,
      );
      if (mounted) {
        setState(() {
          if (movies.isEmpty) {
            _hasMoreGenre = false;
          } else {
            _genreMovies.addAll(movies);
            _genrePage++;
            if (movies.length < 10) _hasMoreGenre = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi tải phim theo thể loại: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGenre = false;
        });
      }
    }
  }

  void _onCategorySelected(String name, String slug) {
    if (_selectedCategory == name) return;

    setState(() {
      _selectedCategory = name;
      _selectedSlug = slug;
    });

    // Khi ô tìm kiếm rỗng và chuyển sang thể loại khác 'Tất cả'
    if (_searchController.text.trim().isEmpty) {
      if (slug != 'all') {
        setState(() {
          _genreMovies.clear();
          _genrePage = 1;
          _hasMoreGenre = true;
        });
        _loadGenreMovies();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    _debounce = Timer(const Duration(milliseconds: 800), () async {
      await _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    try {
      final movies = await MovieApiService.searchMovies(query.trim());

      if (mounted) {
        setState(() {
          _searchResults = movies;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _hasSearched = true;
        });
      }
    }
  }

  /// Lọc danh sách phim tìm kiếm dựa trên thể loại đang được chọn
  List<Movie> get _filteredSearchResults {
    if (_selectedSlug == 'all') {
      return _searchResults;
    }
    return _searchResults.where((movie) {
      return movie.categories.any((c) {
        final catLower = c.toLowerCase().trim();
        final selectedLower = _selectedCategory.toLowerCase().trim();
        return catLower == selectedLower ||
            catLower.contains(selectedLower) ||
            selectedLower.contains(catLower);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/icons/logo.png', height: 35),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Khung tìm kiếm (Reusable AppSearchBar)
          AppSearchBar(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          ),

          // Thanh bộ lọc thể loại (Reusable CategoryFilterBar)
          CategoryFilterBar(
            selectedCategory: _selectedCategory,
            onCategorySelected: _onCategorySelected,
            margin: const EdgeInsets.only(top: 2, bottom: 6),
          ),

          // Nội dung danh sách phim
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.red),
      );
    }

    // 1. Trạng thái khi chưa nhập từ khóa tìm kiếm: Hiển thị theo thể loại hoặc Phim mới cập nhật
    if (_searchController.text.trim().isEmpty) {
      final isAll = _selectedSlug == 'all';
      final movies = isAll ? _suggestedMovies : _genreMovies;
      final isLoadingCurrent = isAll ? _isLoadingSuggestions : _isLoadingGenre;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(
                  isAll ? Icons.whatshot : Icons.movie_filter_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isAll ? 'Phim mới cập nhật' : 'Phim $_selectedCategory',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: movies.isEmpty && isLoadingCurrent
                ? const Center(child: CircularProgressIndicator(color: Colors.red))
                : movies.isEmpty && !isLoadingCurrent
                    ? Center(
                        child: Text(
                          'Chưa có phim nào thuộc thể loại này',
                          style: TextStyle(color: Colors.grey[500], fontSize: 15),
                        ),
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: movies.length + (isLoadingCurrent ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == movies.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          return MovieCard(
                            movie: movies[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MovieDetailScreen(movie: movies[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      );
    }

    // 2. Trạng thái khi đã tìm kiếm nhưng không có kết quả từ khóa
    if (_hasSearched && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[800]),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy phim nào phù hợp',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // 3. Trạng thái kết quả tìm kiếm đã lọc theo thể loại
    final filtered = _filteredSearchResults;

    // Nếu có kết quả tìm kiếm nhưng thể loại hiện tại lọc ra 0 kết quả
    if (_hasSearched && filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.filter_list_off_rounded, size: 70, color: Colors.grey[800]),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy phim "$_selectedCategory" trong kết quả',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _onCategorySelected('Tất cả', 'all');
                },
                icon: const Icon(Icons.refresh, size: 16, color: Colors.redAccent),
                label: const Text(
                  'Xem tất cả kết quả',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                _selectedSlug == 'all'
                    ? 'Kết quả tìm kiếm (${filtered.length})'
                    : 'Kết quả: $_selectedCategory (${filtered.length})',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: filtered[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: filtered[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
