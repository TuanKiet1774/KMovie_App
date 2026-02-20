import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kmovie/screens/watch_later_screen.dart';

import '../controllers/movie_controller.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/app_dialogs.dart';
import 'movie_detail_screen.dart';
import 'category_movie_list_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  final PageController _bannerPageController = PageController(viewportFraction: 0.85);
  Timer? _bannerTimer;
  int _bannerIndex = 0;
  
  // Search handling
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  // Danh sách thể loại cho Dropdown
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

  String _getCategorySlug(String category) {
    // ... maps ...
    final categoryMap = {
      'Tất cả': 'all',
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

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    // Sync search text if returning from other screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
         _searchController.text = Get.find<MovieController>().currentSearchKeyword;
      }
    });
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _bannerIndex + 1;
        _bannerPageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }
  
  void _onSearchChanged(String query, MovieController controller) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Nếu rỗng thì reset ngay lập tức, không cần delay
    if (query.trim().isEmpty) {
      if (controller.currentSearchKeyword.isNotEmpty) {
         controller.searchMovies('');
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 800), () {
      controller.searchMovies(query);
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String? newValue, MovieController controller) {
    if (newValue == null) return;
    setState(() {
      _selectedCategory = newValue;
    });
    final slug = _getCategorySlug(newValue);
    controller.loadMoviesByCategory(slug);
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
      body: GetBuilder<MovieController>(
        builder: (controller) {
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.loadHomeData(),
                  color: Colors.red,
                  child: SingleChildScrollView(
                    physics: ArchiveScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDropdownFilter(controller),
                        
                        if (controller.currentSearchKeyword.isNotEmpty)
                           _buildSearchResults(controller)
                        else if (_selectedCategory == 'Tất cả')
                           _buildHomeContent(controller)
                        else
                           _buildCategoryGrid(controller),
                           
                        SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  
  Widget _buildDropdownFilter(MovieController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Thể loại:',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  // Tùy chỉnh menu xổ xuống
                  dropdownColor: Color(0xFF333333),
                  borderRadius: BorderRadius.circular(12),
                  elevation: 8,
                  menuMaxHeight: 400,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  items: _categories.map((String value) {
                    final bool isSelected = value == _selectedCategory;
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white10, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.redAccent : Colors.white,
                              ),
                            ),
                            if (isSelected) ...[
                              Spacer(),
                              Icon(Icons.check, color: Colors.redAccent, size: 16),
                            ]
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => _onCategoryChanged(val, controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(MovieController controller) {
    // 0. Banner Slide
    // 1. Horizontal Sections (Romance, Historical, Action)
    
    return Column(
      children: [
        if (controller.bannerMovies.isNotEmpty)
          _buildBannerSlider(controller.bannerMovies),
        
        SizedBox(height: 20),
        
        // Loop through the fixed categories in controller
        ...controller.homeCategories.map((slug) {
          final movies = controller.categoryMovies[slug] ?? [];
          final title = controller.categoryTitles[slug] ?? 'Phim';
          
          if (movies.isEmpty) return SizedBox.shrink();
          
          return _buildCategorySection(title, slug, movies);
        }).toList(),
      ],
    );
  }

  Widget _buildBannerSlider(List<Movie> movies) {
    if (movies.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            "Phim Mới Cập Nhật",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.red, blurRadius: 10)],
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _bannerPageController,
            itemCount: 10000, // Infinite loop effect
            onPageChanged: (index) {
              setState(() {
                _bannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final movie = movies[index % movies.length];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                ),
                child: AnimatedBuilder(
                  animation: _bannerPageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_bannerPageController.position.haveDimensions) {
                      value = _bannerPageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                    }
                    return Center(
                      child: SizedBox(
                        height: Curves.easeOut.transform(value) * 220,
                        width: Curves.easeOut.transform(value) * 400,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black45,
                           blurRadius: 8,
                           offset: Offset(0, 4),
                         )
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(color: Colors.grey[800]),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                                stops: [0.6, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${movie.year}",
                                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(String title, String slug, List<Movie> movies) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {
                   Navigator.push(
                     context, 
                     MaterialPageRoute(builder: (_) => CategoryMovieListScreen(categorySlug: slug, title: title)),
                   );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Text('Xem thêm', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                      Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 12),
            itemCount: movies.length, 
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Container(
                width: 130,
                margin: EdgeInsets.symmetric(horizontal: 6),
                child: MovieCard(
                   movie: movie,
                   onTap: () => Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: movie)),
                   ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryGrid(MovieController controller) {
    if (controller.isLoading) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: CircularProgressIndicator(color: Colors.red),
      );
    }
    
    if (controller.movies.isEmpty) {
      return Container(
        height: 300,
         alignment: Alignment.center,
        child: Text("Không tìm thấy phim", style: TextStyle(color: Colors.white)),
      );
    }

    return GridView.builder(
        padding: EdgeInsets.all(16),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: controller.movies.length,
        itemBuilder: (context, index) {
          return MovieCard(
            movie: controller.movies[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: controller.movies[index])),
            ),
          );
        },
      );
  }

  Widget _buildSearchResults(MovieController controller) {
    return _buildCategoryGrid(controller);
  }
}

// Custom physics to handle potentially conflicting scrollables or just standard
class ArchiveScrollPhysics extends BouncingScrollPhysics {
  const ArchiveScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);
}
