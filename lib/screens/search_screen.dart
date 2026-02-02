import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/movie_controller.dart';
import '../models/movie.dart';
import '../services/movie_api_service.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<Movie> _suggestedMovies = [];
  List<Movie> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  
  // Lazy loading suggestions
  final ScrollController _suggestionScrollController = ScrollController();
  int _suggestionPage = 1;
  bool _isLoadingSuggestions = false;
  bool _hasMoreSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestedMovies();
    _suggestionScrollController.addListener(_onSuggestionScroll);
    // Auto focus on search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onSuggestionScroll() {
    if (_suggestionScrollController.position.pixels >= 
        _suggestionScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingSuggestions &&
        _hasMoreSuggestions) {
      _loadSuggestedMovies();
    }
  }

  Future<void> _loadSuggestedMovies() async {
    if (_isLoadingSuggestions) return;
    
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
            // Assuming default limit is 10, if less than 10 probably no more
            if (movies.length < 10) _hasMoreSuggestions = false; 
          }
        });
      }
    } catch (e) {
      print("Error loading suggestions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _suggestionScrollController.dispose();
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
      // Use static method directly
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
          // Search Box Container
          Container(
            margin: EdgeInsets.fromLTRB(16, 10, 16, 10),
            height: 45,
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white10),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _onSearchChanged,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Nhập tên phim...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : Icon(Icons.search, color: Colors.grey, size: 20),
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          
          Expanded(child: _buildBodyContent()),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.red));
    }

    // Trạng thái khi chưa nhập gì: Hiển thị gợi ý
    if (_searchController.text.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Icon(Icons.whatshot, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Phim mới cập nhật',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _suggestedMovies.isEmpty && _isLoadingSuggestions
                ? Center(child: CircularProgressIndicator(color: Colors.red))
                : GridView.builder(
                    controller: _suggestionScrollController,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _suggestedMovies.length + (_isLoadingSuggestions ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _suggestedMovies.length) {
                        return Center(
                           child: Padding(
                             padding: const EdgeInsets.all(8.0),
                             child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                           ),
                        );
                      }
                      return MovieCard(
                        movie: _suggestedMovies[index],
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MovieDetailScreen(movie: _suggestedMovies[index]),
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

    if (_hasSearched && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 80, color: Colors.grey[800]),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy phim nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Kết quả tìm kiếm (${_searchResults.length})',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return MovieCard(
                movie: _searchResults[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailScreen(movie: _searchResults[index]),
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
