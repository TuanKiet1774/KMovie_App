import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/movie.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/app_search_bar.dart';
import '../widgets/category_filter_bar.dart';
import '../controllers/movie_controller.dart';
import 'movie_detail_screen.dart';

class WatchLaterScreen extends StatefulWidget {
  final bool isMainTab;

  const WatchLaterScreen({super.key, this.isMainTab = false});

  @override
  _WatchLaterScreenState createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  // Controller để quản lý việc đóng thẻ khác khi một thẻ được mở
  String? _currentlyOpenSlug;

  // Trạng thái tìm kiếm và lọc thể loại
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tất cả';
  String _selectedSlug = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MovieController>().loadWatchLater();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSlidableOpen(String slug) {
    setState(() {
      _currentlyOpenSlug = slug;
    });
  }

  List<Movie> _getFilteredMovies(List<Movie> allMovies) {
    return allMovies.where((movie) {
      final query = _searchQuery.trim().toLowerCase();
      final matchQuery = query.isEmpty ||
          movie.name.toLowerCase().contains(query) ||
          movie.slug.toLowerCase().contains(query);

      final matchCategory = _selectedSlug == 'all' ||
          movie.categories.any((c) {
            final catLower = c.toLowerCase().trim();
            final selectedLower = _selectedCategory.toLowerCase().trim();
            return catLower == selectedLower ||
                catLower.contains(selectedLower) ||
                selectedLower.contains(catLower);
          });

      return matchQuery && matchCategory;
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
      body: GetBuilder<MovieController>(
        builder: (controller) {
          final filteredMovies = _getFilteredMovies(controller.watchLaterMovies);

          return Column(
            children: [
              // 1. Ô tìm kiếm tái sử dụng
              AppSearchBar(
                controller: _searchController,
                hintText: 'Tìm trong danh sách xem sau...',
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                onClear: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),

              // 2. Thanh bộ lọc thể loại tái sử dụng
              CategoryFilterBar(
                selectedCategory: _selectedCategory,
                onCategorySelected: (name, slug) {
                  setState(() {
                    _selectedCategory = name;
                    _selectedSlug = slug;
                  });
                },
                margin: const EdgeInsets.only(top: 2, bottom: 8),
              ),

              // 3. Danh sách phim Xem sau kèm RefreshIndicator
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => controller.loadWatchLater(),
                  color: Colors.red,
                  child: _buildContent(context, controller, filteredMovies),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    MovieController controller,
    List<Movie> filteredMovies,
  ) {
    if (controller.isWatchLaterLoading && controller.watchLaterMovies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(child: CircularProgressIndicator(color: Colors.red)),
          ),
        ],
      );
    }

    // Danh sách gốc trống hoàn toàn (chưa lưu phim nào)
    if (controller.watchLaterMovies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 16),
                  const Text(
                    "Danh sách trống",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vuốt để tải lại",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Có phim nhưng sau khi tìm kiếm / lọc thể loại không có kết quả phù hợp
    if (filteredMovies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_list_off_rounded, size: 70, color: Colors.grey[800]),
                    const SizedBox(height: 16),
                    const Text(
                      "Không tìm thấy phim phù hợp",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty && _selectedSlug != 'all'
                          ? 'Không có phim "$_selectedCategory" khớp từ khóa "$_searchQuery"'
                          : _searchQuery.isNotEmpty
                              ? 'Không có phim nào khớp với từ khóa "$_searchQuery"'
                              : 'Chưa có phim nào thuộc thể loại "$_selectedCategory"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _selectedCategory = 'Tất cả';
                          _selectedSlug = 'all';
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Xem tất cả phim',
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
            ),
          ),
        ],
      );
    }

    final hasActiveFilter = _searchQuery.isNotEmpty || _selectedSlug != 'all';

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filteredMovies.length + (hasActiveFilter ? 1 : 0),
      itemBuilder: (context, index) {
        // Dòng header thông báo kết quả lọc
        if (hasActiveFilter && index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Text(
                  'Tìm thấy ${filteredMovies.length} phim',
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final movieIndex = hasActiveFilter ? index - 1 : index;
        final movie = filteredMovies[movieIndex];

        return SlidableView(
          key: Key('watch_later_${movie.slug}'),
          slug: movie.slug,
          currentlyOpenSlug: _currentlyOpenSlug,
          onOpen: _onSlidableOpen,
          onDelete: () => _showDeleteDialog(context, controller, movie),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Hero(
                        tag: 'poster_${movie.slug}',
                        child: SizedBox(
                          width: 100,
                          height: double.infinity,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              movie.posterUrl.isNotEmpty
                                  ? Image.network(
                                      movie.posterUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[900],
                                        child: const Icon(Icons.movie, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[900],
                                      child: const Icon(Icons.movie, color: Colors.grey),
                                    ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFF1E1E1E).withValues(alpha: 0.1),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Info Section
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                movie.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      movie.quality,
                                      style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${movie.year}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      movie.language,
                                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                movie.description,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, MovieController controller, dynamic movie) async {
    final confirmed = await AppDialogs.showDeleteWatchLaterConfirm(
      context,
      movieName: movie.name,
    );

    if (confirmed) {
      if (context.mounted) AppDialogs.showLoading(context, message: 'Đang xóa...');
      try {
        await controller.removeFromWatchLater(movie.slug);
        if (_currentlyOpenSlug == movie.slug) {
          _currentlyOpenSlug = null;
        }
        if (context.mounted) {
          AppDialogs.hideLoading(context);
          AppDialogs.showToast(context, 'Đã xóa khỏi danh sách');
        }
      } catch (e) {
        if (context.mounted) {
          AppDialogs.hideLoading(context);
          AppDialogs.showToast(context, 'Lỗi khi xóa', isError: true);
        }
      }
    }
  }
}

class SlidableView extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String slug;
  final String? currentlyOpenSlug;
  final Function(String) onOpen;

  const SlidableView({
    super.key,
    required this.child,
    required this.onDelete,
    required this.slug,
    required this.currentlyOpenSlug,
    required this.onOpen,
  });

  @override
  _SlidableViewState createState() => _SlidableViewState();
}

class _SlidableViewState extends State<SlidableView> {
  double _offset = 0;
  final double _actionWidth = 80;

  @override
  void didUpdateWidget(SlidableView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu có thẻ khác được mở, đóng thẻ hiện tại nếu nó đang mở
    if (widget.currentlyOpenSlug != widget.slug && _offset != 0) {
      setState(() {
        _offset = 0;
      });
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      _offset = _offset.clamp(-_actionWidth, _actionWidth);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      if (_offset < -_actionWidth / 2) {
        _offset = -_actionWidth;
        widget.onOpen(widget.slug);
      } else if (_offset > _actionWidth / 2) {
        _offset = _actionWidth;
        widget.onOpen(widget.slug);
      } else {
        _offset = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Nền đỏ phía dưới có bo góc 16 tương ứng thẻ phim
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: _offset >= 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                _buildDeleteActionContent(),
              ],
            ),
          ),
        ),

        // 2. Thẻ phim trượt
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_offset, 0, 0),
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            behavior: HitTestBehavior.deferToChild,
            child: widget.child,
          ),
        ),

        // 3. Lớp phủ tương tác phía trên cùng khi thẻ đã được mở (_offset != 0)
        if (_offset != 0)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  if (_offset > 0) ...[
                    // Nút xóa bên TRÁI (khi vuốt sang phải như trong ảnh chụp)
                    SizedBox(
                      width: _actionWidth,
                      height: double.infinity,
                      child: _buildDeleteButton(),
                    ),
                    // Vùng thẻ phim còn lại: chạm vào để đóng thẻ
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _offset = 0);
                        },
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                      ),
                    ),
                  ] else ...[
                    // Vùng thẻ phim còn lại: chạm vào để đóng thẻ
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _offset = 0);
                        },
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                      ),
                    ),
                    // Nút xóa bên PHẢI (khi vuốt sang trái)
                    SizedBox(
                      width: _actionWidth,
                      height: double.infinity,
                      child: _buildDeleteButton(),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Giao diện tĩnh của nút xóa (icon thùng rác + chữ "Xóa")
  Widget _buildDeleteActionContent() {
    return SizedBox(
      width: _actionWidth,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.delete, color: Colors.white, size: 28),
          SizedBox(height: 4),
          Text(
            'Xóa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Nút xóa tương tác nhận sự kiện chạm
  Widget _buildDeleteButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _offset = 0);
          widget.onDelete();
        },
        child: _buildDeleteActionContent(),
      ),
    );
  }
}
