import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_api_service.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class CategoryMovieListScreen extends StatefulWidget {
  final String categorySlug;
  final String title;

  const CategoryMovieListScreen({
    Key? key,
    required this.categorySlug,
    required this.title,
  }) : super(key: key);

  @override
  _CategoryMovieListScreenState createState() => _CategoryMovieListScreenState();
}

class _CategoryMovieListScreenState extends State<CategoryMovieListScreen> {
  final List<Movie> _movies = [];
  List<Movie> _filteredMovies = []; // List for local search
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore && 
        _searchKeyword.isEmpty) { // Disable infinite scroll while searching locally to avoid confusion
      _loadMovies();
    }
  }

  // Filter movies locally
  void _onSearchChanged(String value) {
    setState(() {
      _searchKeyword = value.toLowerCase().trim();
      if (_searchKeyword.isEmpty) {
        _filteredMovies = List.from(_movies);
      } else {
        _filteredMovies = _movies.where((movie) {
          return movie.name.toLowerCase().contains(_searchKeyword) || 
                 movie.slug.toLowerCase().contains(_searchKeyword);
        }).toList();
      }
    });
  }

  Future<void> _loadMovies() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newMovies = await MovieApiService.getMoviesByGenre(
        widget.categorySlug,
        page: _currentPage,
        limit: _limit,
      );

      if (newMovies.isEmpty) {
        setState(() {
          _hasMore = false;
        });
      } else {
        setState(() {
          _movies.addAll(newMovies);
          // Update filtered list as well if not searching
          if (_searchKeyword.isEmpty) {
            _filteredMovies = List.from(_movies);
          } else {
             // Re-apply filter on new data (though usually infinite scroll is off)
             _onSearchChanged(_searchKeyword);
          }
          _currentPage++;
          if (newMovies.length < _limit) _hasMore = false;
        });
      }
    } catch (e) {
      print("Lỗi tải phim: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu. Vui lòng thử lại.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _searchKeyword.isEmpty ? _movies : _filteredMovies;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      backgroundColor: Colors.black, // Dark theme
      body: Column(
        children: [
          // Search Box
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tìm trong danh sách này...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          Expanded(
            child: _movies.isEmpty && _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.red))
                : displayList.isEmpty
                  ? Center(child: Text('Không tìm thấy phim phù hợp', style: TextStyle(color: Colors.grey)))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: displayList.length + ((_hasMore && _searchKeyword.isEmpty) ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == displayList.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(color: Colors.red),
                            ),
                          );
                        }
                        return MovieCard(
                          movie: displayList[index],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailScreen(movie: displayList[index]),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
