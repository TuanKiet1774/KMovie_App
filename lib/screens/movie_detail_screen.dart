import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:kmovie/screens/video_player_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/movie_controller.dart';
import '../models/movie.dart';
import '../models/movie_detail.dart';
import '../services/movie_api_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/movie_info_chip.dart';
import '../widgets/app_dialogs.dart';

class MovieDetailScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  MovieDetail? _movieDetail;
  bool _isLoading = true;
  bool _isSavingToWatchLater = false;
  bool _isInWatchLater = false;
  bool _isDescriptionExpanded = false;
  String? selectedEpisodeUrl;

  // Tải thông tin từ Controller
  final MovieController _movieController = Get.find<MovieController>();

  // Server được chọn (index)
  int _selectedServerIndex = 0;

  // Lịch sử xem (tập và thời gian)
  Map<String, dynamic>? _lastHistory;

  @override
  void initState() {
    super.initState();
    _isInWatchLater = _movieController.isMovieInWatchLater(widget.movie.slug);
    _loadMovieDetail();
    _movieController.loadWatchedEpisodes(widget.movie.slug);
    _checkWatchLaterStatus();
    _loadWatchHistory();
  }

  Future<void> _loadMovieDetail() async {
    try {
      final detail = await MovieApiService.getMovieDetail(widget.movie.slug);
      setState(() {
        _movieDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppDialogs.showError(context, 'Không thể tải chi tiết phim. Vui lòng thử lại sau.');
    }
  }


  // Load thông tin xem dở từ SharedPreferences
  Future<void> _loadWatchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'history_${widget.movie.slug}';
      final historyStr = prefs.getString(key);
      if (historyStr != null) {
        setState(() {
          _lastHistory = json.decode(historyStr);
        });
      }
    } catch (e) {
      print('Lỗi khi load lịch sử xem: $e');
    }
  }

  void _openPlayer(int episodeIndex, int serverIndex, {Duration position = Duration.zero}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          movieDetail: _movieDetail!,
          initialEpisodeIndex: episodeIndex,
          serverIndex: serverIndex,
          initialPosition: position,
        ),
      ),
    ).then((_) {
      _loadWatchHistory();
      // Không cần loadWatchedEpisodes thủ công nữa vì đã có GetBuilder
    }); // Load lại lịch sử khi quay lại
  }

  Future<void> _checkWatchLaterStatus() async {
    try {
      final movieController = Get.find<MovieController>();
      final deviceId = await movieController.getDeviceId();
      final exists = await MovieApiService.checkWatchLater(deviceId, widget.movie.slug);
      
      if (mounted) {
        setState(() {
          _isInWatchLater = exists;
        });
      }
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái xem sau: $e');
    }
  }

  Future<void> _toggleWatchLater() async {
    setState(() {
      _isSavingToWatchLater = true;
    });

    try {
      final movieController = Get.find<MovieController>();
      
      if (_isInWatchLater) {
        final confirmed = await AppDialogs.showDeleteWatchLaterConfirm(
          context,
          movieName: widget.movie.name,
        );

        if (!confirmed) {
          if (mounted) {
            setState(() {
              _isSavingToWatchLater = false;
            });
          }
          return;
        }

        if (mounted) AppDialogs.showLoading(context, message: 'Đang xóa...');
        await movieController.removeFromWatchLater(widget.movie.slug);
        setState(() {
          _isInWatchLater = false;
        });
        if (mounted) {
          AppDialogs.hideLoading(context);
          AppDialogs.showToast(context, 'Đã xóa khỏi danh sách');
        }
      } else {
        if (mounted) AppDialogs.showLoading(context, message: 'Đang lưu...');
        final success = await movieController.addToWatchLater(widget.movie.slug);
        if (success) {
          await movieController.loadWatchLater();
          setState(() {
            _isInWatchLater = true;
          });
          if (mounted) {
            AppDialogs.hideLoading(context);
            AppDialogs.showToast(context, 'Đã thêm vào danh sách');
          }
        } else {
          if (mounted) AppDialogs.hideLoading(context);
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.hideLoading(context);
        AppDialogs.showToast(context, 'Có lỗi xảy ra', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingToWatchLater = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Đang tải chi tiết phim...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildMovieContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.4),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: _isSavingToWatchLater
              ? Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: Icon(
                      _isInWatchLater ? Icons.delete_rounded : Icons.bookmark_border_rounded,
                      color: _isInWatchLater ? Colors.redAccent : Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: _isInWatchLater ? 'Xóa khỏi danh sách xem sau' : 'Thêm vào danh sách xem sau',
                    onPressed: _toggleWatchLater,
                  ),
                ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.movie.posterUrl.isNotEmpty
                ? Image.network(
                    widget.movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(
                          Icons.movie,
                          size: 64,
                          color: Colors.grey,
                        ),
                      );
                    },
                  )
                : Container(
                    color: const Color(0xFF2A2A2A),
                    child: const Icon(
                      Icons.movie,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                    const Color(0xFF0F0F0F),
                  ],
                  stops: const [0.0, 0.25, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMovieTitle(),
          const SizedBox(height: 12),
          _buildBasicInfo(),
          const SizedBox(height: 16),
          _buildCategoriesSection(),
          const SizedBox(height: 20),
          _buildDescriptionSection(),
          const SizedBox(height: 20),
          if (_movieDetail != null) ...[
            _buildDetailedInfo(),
            const SizedBox(height: 20),
            _buildServerSelector(),
            const SizedBox(height: 20),
            _buildEpisodesSection(),
          ],
          // Thêm khoảng trống ở cuối
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMovieTitle() {
    return Text(
      widget.movie.name,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.3,
        height: 1.3,
      ),
    );
  }

  Widget _buildBasicInfo() {
    final year = _movieDetail?.year != null && _movieDetail!.year != 0 
        ? _movieDetail!.year 
        : widget.movie.year;
    final quality = (_movieDetail?.quality.isNotEmpty ?? false) 
        ? _movieDetail!.quality 
        : widget.movie.quality;
    final language = (_movieDetail?.language.isNotEmpty ?? false) 
        ? _movieDetail!.language 
        : widget.movie.language;

    return Row(
      children: [
        MovieInfoChip(text: '$year'),
        const SizedBox(width: 10),
        MovieInfoChip(text: quality),
        const SizedBox(width: 10),
        MovieInfoChip(text: language),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final categories = (_movieDetail != null && _movieDetail!.categories.isNotEmpty) 
        ? _movieDetail!.categories 
        : widget.movie.categories;
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thể loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map((category) => CategoryChip(category: category))
              .toList(),
        ),
      ],
    );
  }

  /// Xóa tất cả thẻ HTML (vd: <p>, <br>, <strong>...) khỏi chuỗi văn bản
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // bỏ thẻ HTML
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .trim();
  }

  Widget _buildDescriptionSection() {
    final rawDescription = (_movieDetail != null && _movieDetail!.description.isNotEmpty)
        ? _movieDetail!.description
        : widget.movie.description;

    final description = _stripHtml(rawDescription);

    if (description.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Chưa có mô tả cho phim này.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    final textStyle = TextStyle(
      fontSize: 15,
      height: 1.5,
      color: Colors.grey[300],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final span = TextSpan(text: description, style: textStyle);
            final tp = TextPainter(
              text: span,
              maxLines: 5,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.justify,
            );
            tp.layout(maxWidth: constraints.maxWidth);
            final bool isExceeding = tp.didExceedMaxLines;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: textStyle,
                  textAlign: TextAlign.justify,
                  maxLines: _isDescriptionExpanded ? null : 5,
                  overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
                if (isExceeding) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    final hasDirector = _movieDetail != null && _movieDetail!.director.isNotEmpty;
    final hasActors = _movieDetail != null && _movieDetail!.actors.isNotEmpty;
    final hasCountry = _movieDetail != null && _movieDetail!.country.isNotEmpty;

    if (!hasDirector && !hasActors && !hasCountry) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin chi tiết',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        if (hasDirector) ...[
          _buildInfoRow('Đạo diễn', _movieDetail!.director),
          const SizedBox(height: 6),
        ],
        if (hasActors) ...[
          _buildInfoRow('Diễn viên', _movieDetail!.actors.join(', ')),
          const SizedBox(height: 6),
        ],
        if (hasCountry) ...[
          _buildInfoRow('Quốc gia', _movieDetail!.country),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 15, color: Colors.grey[300], height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // Widget chọn server
  Widget _buildServerSelector() {
    if (_movieDetail == null || _movieDetail!.episodes.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn server',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            _movieDetail!.episodes.length,
                (index) {
              final episode = _movieDetail!.episodes[index];
              final isSelected = _selectedServerIndex == index;

              return ChoiceChip(
                label: Text(
                  episode.serverName,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedServerIndex = index;
                  });
                },
                selectedColor: Colors.red,
                backgroundColor: Colors.grey[850],
                side: BorderSide(
                  color: isSelected ? Colors.red : Colors.grey[700]!,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesSection() {
    if (_movieDetail == null || _movieDetail!.episodes.isEmpty) {
      return SizedBox.shrink();
    }

    final selectedServer = _movieDetail!.episodes[_selectedServerIndex];
    final episodes = selectedServer.serverData;

    if (episodes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Server này chưa có tập phim nào.',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return GetBuilder<MovieController>(
      builder: (controller) {
        final watchedEpisodes = controller.getWatchedEpisodes(widget.movie.slug);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách tập phim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: episodes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final episode = episodes[index];
                final episodeKey = '${selectedServer.serverName}_${episode.name}';
                final isWatched = watchedEpisodes.contains(episodeKey);

                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Màu cam cho tập đã xem, xám cho tập chưa xem
                    backgroundColor: isWatched ? Colors.orange : Colors.grey[900],
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Đánh dấu tập này đã xem
                    controller.markEpisodeAsWatched(
                      widget.movie.slug,
                      selectedServer.serverName,
                      episode.name,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(
                          movieDetail: _movieDetail!,
                          initialEpisodeIndex: index,
                          serverIndex: _selectedServerIndex,
                          initialPosition: (_lastHistory != null && 
                                           _lastHistory!['episodeIndex'] == index && 
                                           _lastHistory!['serverIndex'] == _selectedServerIndex)
                              ? Duration(milliseconds: _lastHistory!['positionMs'] ?? 0)
                              : Duration.zero,
                        ),
                      ),
                    ).then((_) => _loadWatchHistory());
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isWatched)
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.white,
                        ),
                      if (isWatched) SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          episode.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}