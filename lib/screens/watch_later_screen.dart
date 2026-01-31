import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/app_dialogs.dart';
import '../controllers/movie_controller.dart';
import 'movie_detail_screen.dart';

class WatchLaterScreen extends StatefulWidget {
  @override
  _WatchLaterScreenState createState() => _WatchLaterScreenState();
}

class _WatchLaterScreenState extends State<WatchLaterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<MovieController>().loadWatchLater();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh Sách Xem Sau'),
        centerTitle: true,
      ),
      body: GetBuilder<MovieController>(
        builder: (controller) {
          if (controller.isWatchLaterLoading && controller.watchLaterMovies.isEmpty) {
            return Center(child: CircularProgressIndicator(color: Colors.red));
          }

          if (controller.watchLaterMovies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 80, color: Colors.grey[800]),
                  SizedBox(height: 16),
                  Text(
                    "Chưa có phim nào trong danh sách xem sau.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadWatchLater(),
            color: Colors.red,
            child: GridView.builder(
              padding: EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: controller.watchLaterMovies.length,
              itemBuilder: (context, index) {
                final movie = controller.watchLaterMovies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MovieDetailScreen(movie: movie),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1A1A1A),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(
                                    movie.posterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[900],
                                      child: Icon(Icons.movie, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                // Gradient overlay
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.8),
                                        ],
                                        stops: [0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Delete button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Material(
                                    color: Colors.black45,
                                    shape: CircleBorder(),
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: Colors.white, size: 18),
                                      onPressed: () => _showDeleteDialog(context, controller, movie),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "${movie.year} • ${movie.quality}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
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
