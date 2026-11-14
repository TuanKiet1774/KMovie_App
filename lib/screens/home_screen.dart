import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/movie_controller.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../widgets/category_filter_bar.dart';
import 'movie_detail_screen.dart';
import 'category_movie_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tất cả';
  final PageController _bannerPageController = PageController(viewportFraction: 0.85);
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bannerPageController.hasClients) {
        int nextPage = _bannerIndex + 1;
        _bannerPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String name, String slug, MovieController controller) {
    setState(() {
      _selectedCategory = name;
    });
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
                        if (controller.bannerMovies.isNotEmpty)
                          _buildBannerSlider(controller.bannerMovies),

                        const SizedBox(height: 10),

                        CategoryFilterBar(
                          selectedCategory: _selectedCategory,
                          onCategorySelected: (name, slug) => _onCategoryChanged(name, slug, controller),
                        ),
                        
                        if (controller.currentSearchKeyword.isNotEmpty)
                           _buildSearchResults(controller)
                        else if (_selectedCategory == 'Tất cả')
                           _buildHomeCategorySections(controller)
                        else
                           _buildCategoryGrid(controller),
                           
                        const SizedBox(height: 50),
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

  Widget _buildHomeCategorySections(MovieController controller) {
    return Column(
      children: [
        const SizedBox(height: 8),
        ...controller.homeCategories.map((slug) {
          final movies = controller.categoryMovies[slug] ?? [];
          final title = controller.categoryTitles[slug] ?? 'Phim';
          
          if (movies.isEmpty) return const SizedBox.shrink();
          
          return _buildCategorySection(title, slug, movies);
        }),
      ],
    );
  }

  Widget _buildBannerSlider(List<Movie> movies) {
    if (movies.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                            movie.thumbUrl.isNotEmpty ? movie.thumbUrl : movie.posterUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
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
