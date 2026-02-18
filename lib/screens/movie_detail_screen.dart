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

  void _showWatchDialog() {
    if (_movieDetail == null || _movieDetail!.episodes.isEmpty) {
      AppDialogs.showError(context, "Không có tập phim nào để xem.");
      return;
    }

    // Nếu có lịch sử, cho phép tiếp tục xem
    if (_lastHistory != null) {
      _resumeWatching();
      return;
    }

    final selectedServer = _movieDetail!.episodes[_selectedServerIndex];
    if (selectedServer.serverData.isEmpty) {
      AppDialogs.showError(context, "Không có tập phim nào khả dụng.");
      return;
    }

    // Đánh dấu tập đầu tiên đã xem
    _movieController.markEpisodeAsWatched(
      widget.movie.slug,
      selectedServer.serverName,
      selectedServer.serverData[0].name,
    );

    _openPlayer(0, _selectedServerIndex);
  }

  void _resumeWatching() {
    if (_lastHistory == null) return;
    
    final episodeIndex = _lastHistory!['episodeIndex'] ?? 0;
    final serverIndex = _lastHistory!['serverIndex'] ?? 0;
    final positionMs = _lastHistory!['positionMs'] ?? 0;

    _openPlayer(episodeIndex, serverIndex, position: Duration(milliseconds: positionMs));
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
    
    // Hiện loading dialog
    AppDialogs.showLoading(context, message: _isInWatchLater ? 'Đang xóa...' : 'Đang lưu...');

    try {
      final movieController = Get.find<MovieController>();
      
      if (_isInWatchLater) {
        await movieController.removeFromWatchLater(widget.movie.slug);
        await movieController.loadWatchLater();
        setState(() {
          _isInWatchLater = false;
        });
        // Ẩn loading trước khi hiện toast
        AppDialogs.hideLoading(context);
        AppDialogs.showToast(context, 'Đã xóa khỏi danh sách');
      } else {
        final success = await movieController.addToWatchLater(widget.movie.slug);
        if (success) {
          await movieController.loadWatchLater();
          setState(() {
            _isInWatchLater = true;
          });
          // Ẩn loading trước khi hiện toast
          AppDialogs.hideLoading(context);
          AppDialogs.showToast(context, 'Đã thêm vào danh sách');
        } else {
          AppDialogs.hideLoading(context);
        }
      }
    } catch (e) {
      AppDialogs.hideLoading(context);
      AppDialogs.showToast(context, 'Có lỗi xảy ra', isError: true);
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
      actions: [
        Container(
          margin: EdgeInsets.only(right: 8),
          child: _isSavingToWatchLater
              ? Container(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
              : IconButton(
            icon: Icon(
              _isInWatchLater ? Icons.bookmark : Icons.bookmark_border,
              color: _isInWatchLater ? Colors.red : Colors.white,
              size: 26,
            ),
            tooltip: _isInWatchLater ? 'Xóa khỏi danh sách xem sau' : 'Thêm vào danh sách xem sau',
            onPressed: _toggleWatchLater,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              shape: CircleBorder(),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        title: Text(
          widget.movie.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            widget.movie.posterUrl.isNotEmpty
                ? Image.network(
              widget.movie.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Color(0xFF2A2A2A),
                  child: Icon(
                    Icons.movie,
                    size: 64,
                    color: Colors.grey,
                  ),
                );
              },
            )
                : Container(
              color: Color(0xFF2A2A2A),
              child: Icon(
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
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
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
          _buildBasicInfo(),
          SizedBox(height: 16),
          _buildCategoriesSection(),
          SizedBox(height: 16),
          _buildDescriptionSection(),
          SizedBox(height: 16),
          if (_movieDetail != null) ...[
            _buildDetailedInfo(),
            SizedBox(height: 16),
            _buildServerSelector(),
            SizedBox(height: 16),
            _buildEpisodesSection(),
          ],
          SizedBox(height: 32),
          _buildWatchButton(),
        ],
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
        SizedBox(width: 10),
        MovieInfoChip(text: quality),
        SizedBox(width: 10),
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
        Text(
          'Thể loại',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
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

  Widget _buildDescriptionSection() {
    final description = (_movieDetail != null && _movieDetail!.description.isNotEmpty)
        ? _movieDetail!.description
        : widget.movie.description;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Mô tả',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconColor: Colors.red,
        collapsedIconColor: Colors.grey,
        childrenPadding: EdgeInsets.only(bottom: 8),
        children: [
          Text(
            description.isNotEmpty ? description : 'Chưa có mô tả cho phim này.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInfo() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          'Thông tin chi tiết',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconColor: Colors.red,
        collapsedIconColor: Colors.grey,
        childrenPadding: EdgeInsets.only(bottom: 8),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_movieDetail!.director.isNotEmpty) ...[
                _buildInfoRow('Đạo diễn', _movieDetail!.director),
                SizedBox(height: 8),
              ],
              if (_movieDetail!.actors.isNotEmpty) ...[
                _buildInfoRow('Diễn viên', _movieDetail!.actors.join(', ')),
                SizedBox(height: 8),
              ],
              if (_movieDetail!.country.isNotEmpty) ...[
                _buildInfoRow('Quốc gia', _movieDetail!.country),
                SizedBox(height: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Colors.grey[300], height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
            Text(
              'Danh sách tập phim',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: episodes.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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

  Widget _buildWatchButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0, right: 10.0, left: 10.0),
      child: Container(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _showWatchDialog,
          icon: Icon(Icons.play_arrow, color: Colors.white, size: 24),
          label: Text(
            _lastHistory != null 
                ? 'Tiếp tục xem (${_lastHistory!['episodeName']})' 
                : 'Xem phim',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}