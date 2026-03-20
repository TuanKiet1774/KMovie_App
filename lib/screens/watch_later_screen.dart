import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/app_dialogs.dart';
import '../controllers/movie_controller.dart';
import 'movie_detail_screen.dart';

class WatchLaterScreen extends StatefulWidget {
  final bool isMainTab;

  const WatchLaterScreen({Key? key, this.isMainTab = false}) : super(key: key);

  @override
  _WatchLaterScreenState createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  // Controller để quản lý việc đóng thẻ khác khi một thẻ được mở
  String? _currentlyOpenSlug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MovieController>().loadWatchLater();
    });
  }

  void _onSlidableOpen(String slug) {
    setState(() {
      _currentlyOpenSlug = slug;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/icons/logo.png', height: 35),
        centerTitle: true,
      ),
      body: GetBuilder<MovieController>(
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: () => controller.loadWatchLater(),
            color: Colors.red,
            child: _buildContent(context, controller),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, MovieController controller) {
    if (controller.isWatchLaterLoading && controller.watchLaterMovies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(child: CircularProgressIndicator(color: Colors.red)),
          ),
        ],
      );
    }

    if (controller.watchLaterMovies.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 80, color: Colors.grey[800]),
                  SizedBox(height: 16),
                  Text(
                    "Danh sách trống",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  SizedBox(height: 8),
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

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      itemCount: controller.watchLaterMovies.length,
      itemBuilder: (context, index) {
        final movie = controller.watchLaterMovies[index];
        return SlidableView(
          key: Key('watch_later_${movie.slug}'),
          slug: movie.slug,
          currentlyOpenSlug: _currentlyOpenSlug,
          onOpen: _onSlidableOpen,
          onDelete: () => _showDeleteDialog(context, controller, movie),
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            height: 140,
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
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
                        child: Container(
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
                                        child: Icon(Icons.movie, color: Colors.grey),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[900],
                                      child: Icon(Icons.movie, color: Colors.grey),
                                    ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF1E1E1E).withOpacity(0.1),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      movie.quality,
                                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '${movie.year}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '•',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  SizedBox(width: 8),
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
                              SizedBox(height: 8),
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
    final confirmed = await AppDialogs.showConfirm(
      context: context,
      title: 'Xóa khỏi danh sách?',
      content: 'Bạn có muốn xóa "${movie.name}" khỏi danh sách xem sau không?',
      confirmText: 'Xóa',
      confirmColor: Colors.red,
    );

    if (confirmed) {
      if (context.mounted) AppDialogs.showLoading(context, message: 'Đang xóa...');
      try {
        await controller.removeFromWatchLater(movie.slug);
        await controller.loadWatchLater();
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
    Key? key,
    required this.child,
    required this.onDelete,
    required this.slug,
    required this.currentlyOpenSlug,
    required this.onOpen,
  }) : super(key: key);

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
      children: [
        Positioned.fill(
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: _offset > 0 ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                _buildDeleteAction(),
              ],
            ),
          ),
        ),
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(_offset, 0, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteAction() {
    return InkWell(
      onTap: () {
        setState(() => _offset = 0);
        widget.onDelete();
      },
      child: Container(
        width: _actionWidth,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(height: 4),
            Text('Xóa', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
