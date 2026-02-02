import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/app_dialogs.dart';
import '../controllers/movie_controller.dart';
import '../widgets/movie_card.dart';
import 'movie_detail_screen.dart';

class WatchLaterScreen extends StatefulWidget {
  final bool isMainTab;

  const WatchLaterScreen({Key? key, this.isMainTab = false}) : super(key: key);

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/icons/logo.png', height: 35),
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
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: controller.watchLaterMovies.length,
              itemBuilder: (context, index) {
                final movie = controller.watchLaterMovies[index];
                return Stack(
                  children: [
                    MovieCard(
                      movie: movie,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreen(movie: movie),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close, color: Colors.white, size: 18),
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.zero,
                          onPressed: () => _showDeleteDialog(context, controller, movie),
                        ),
                      ),
                    ),
                  ],
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
