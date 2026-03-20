import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/movie_detail.dart';
import '../controllers/movie_controller.dart';
import '../controllers/connectivity_controller.dart';

class VideoPlayerScreen extends StatefulWidget {
  final MovieDetail movieDetail;
  final int initialEpisodeIndex;
  final int serverIndex; // Thêm parameter này

  const VideoPlayerScreen({
    Key? key,
    required this.movieDetail,
    this.initialEpisodeIndex = 0,
    this.serverIndex = 0,
    this.initialPosition = Duration.zero, // Thêm vị trí bắt đầu
  }) : super(key: key);

  final Duration initialPosition;

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentEpisodeIndex = 0;
  int _currentServerIndex = 0; // Thêm biến theo dõi server hiện tại
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isFullScreen = true;
  Timer? _hideControlsTimer;
  double _playbackSpeed = 1.0;
  bool _showForwardIcon = false;
  bool _showBackwardIcon = false;
  Timer? _seekIconTimer;
  Timer? _historyTimer; // Timer lưu lịch sử
  bool _isFirstLoad = true;
  Worker? _connectivityWorker;

  // Các biến cho tính năng tự động chuyển tập
  bool _showNextEpisodeNotice = false;
  int _countdownSeconds = 20;
  Timer? _nextEpisodeTimer;
  bool _isAutoPlayStopped = false;

  final List<double> _speedOptions = [
    0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentEpisodeIndex = widget.initialEpisodeIndex;
    _currentServerIndex = widget.serverIndex; // Khởi tạo server index
    _initializeVideo();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable(); // Giữ màn hình luôn sáng
    
    // Đảm bảo wakelock được bật sau khi UI ổn định
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WakelockPlus.enable();
    });
    
    // Bắt đầu lưu lịch sử mỗi 10 giây
    _historyTimer = Timer.periodic(const Duration(seconds: 30), (_) => _saveWatchHistory());

    // Tự động tải lại khi có mạng
    _connectivityWorker = ever(Get.find<ConnectivityController>().isConnectedRx, (bool connected) {
      if (connected && _hasError && mounted) {
        print('🌐 Đang tải lại video sau khi khôi phục mạng...');
        _initializeVideo();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Đảm bảo wakelock được bật lại khi quay lại ứng dụng
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _nextEpisodeTimer?.cancel(); // Hủy countdown timer
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WakelockPlus.disable(); // Tắt giữ màn hình sáng
    _seekIconTimer?.cancel();
    _historyTimer?.cancel();
    _connectivityWorker?.dispose();
    _saveWatchHistory(); // Lưu lần cuối trước khi thoát
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    // Reset trạng thái tự động chuyển tập
    _nextEpisodeTimer?.cancel();
    await WakelockPlus.enable(); // Ensure screen stays on while loading
    setState(() {
      _showNextEpisodeNotice = false;
      _countdownSeconds = 20;
      _isAutoPlayStopped = false;
    });

    if (widget.movieDetail.episodes.isNotEmpty) {
      // Sử dụng server hiện tại thay vì hardcode [0]
      final currentServer = widget.movieDetail.episodes[_currentServerIndex];
      final episodeData = currentServer.serverData[_currentEpisodeIndex];

      String videoUrl = episodeData.linkM3u8;

      // In thông tin ra console
      print('═══════════════════════════════════════');
      print('🎥 VIDEO PLAYER - ĐANG LOAD');
      print('═══════════════════════════════════════');
      print('📺 Phim: ${widget.movieDetail.name}');
      print('🖥️  Server: ${currentServer.serverName}');
      print('📝 Tập: ${episodeData.name}');
      print('🎬 Link M3U8: $videoUrl');
      print('═══════════════════════════════════════\n');

      if (videoUrl.isNotEmpty) {
        setState(() {
          _isLoading = true;
          _hasError = false;
          _errorMessage = '';
        });
        try {
          if (_controller != null) {
            // Ngắt listener và xóa controller cũ ngay lập tức để tránh lỗi Build
            _controller!.removeListener(_videoListener);
            final oldController = _controller;
            _controller = null; 
            setState(() {}); // Buộc UI render lại trạng thái không có video
            await oldController!.dispose();
          }
          
          _controller = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
            formatHint: VideoFormat.hls,
          );

          await _controller!.initialize();

          // Lấy vị trí đã lưu cho tập này
          final prefs = await SharedPreferences.getInstance();
          final savedPosMs = prefs.getInt('pos_${widget.movieDetail.slug}_${_currentServerIndex}_$_currentEpisodeIndex');
          Duration startPosition = Duration.zero;

          if (savedPosMs != null && savedPosMs > 0) {
            startPosition = Duration(milliseconds: savedPosMs);
          } else if (_isFirstLoad && widget.initialPosition != Duration.zero) {
            startPosition = widget.initialPosition;
          }
          
          if (startPosition != Duration.zero) {
            await _controller!.seekTo(startPosition);
          }
          _isFirstLoad = false;

          setState(() {
            _isLoading = false;
            _hasError = false;
          });

          _controller!.play();
          _isPlaying = true;
          _controller!.setPlaybackSpeed(_playbackSpeed);
          
          _controller!.addListener(_videoListener);
          
          // Đảm bảo wakelock được bật khi bắt đầu phát
          await WakelockPlus.enable();

          // Đánh dấu tập này đã xem
          _markCurrentEpisodeAsWatched();

        } catch (e) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Không thể phát video: ${e.toString()}';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Không tìm thấy link video cho tập này';
        });
      }
    }
  }

  void _toggleFullScreen() async {
    if (_isFullScreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.hasError) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Lỗi khi phát: ${_controller!.value.errorDescription}';
          _isLoading = false;
        });
        return;
      }

      final isPlaying = _controller!.value.isPlaying;
      final isCompleted = _controller!.value.position >= _controller!.value.duration;

      if (_isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });
      }

      // Khi video đang phát, đảm bảo UI cập nhật và màn hình luôn sáng
      if (isPlaying) {
        setState(() {});
        WakelockPlus.enable(); 
      }

      // Logic tự động chuyển tập (Hiện popup trong 20s cuối)
      final duration = _controller!.value.duration;
      final position = _controller!.value.position;
      final remaining = (duration - position).inSeconds;
      final currentServer = widget.movieDetail.episodes[_currentServerIndex];
      final hasNext = currentServer.serverData.length > _currentEpisodeIndex + 1;

      if (hasNext && !_isAutoPlayStopped) {
        if (!_showNextEpisodeNotice && remaining <= 20 && remaining > 0) {
          setState(() {
            _showNextEpisodeNotice = true;
            _countdownSeconds = remaining > 0 ? remaining : 20;
          });
          _startCountdown();
        } else if (_showNextEpisodeNotice && remaining > 20) {
          // Người dùng tua ngược lại ngoài vùng 20s
          setState(() {
            _showNextEpisodeNotice = false;
          });
          _nextEpisodeTimer?.cancel();
        }
      }

      if (isCompleted) {
        if (!_isAutoPlayStopped) {
          _controller!.removeListener(_videoListener);
          _goToNextEpisode();
        } else {
          // Nếu đã bấm dừng tự động chuyển tập, giữ ở tập hiện tại
          setState(() {
            _showControls = true;
            _isPlaying = false;
          });
        }
      }
    }
  }

  void _goToNextEpisode() {
    _nextEpisodeTimer?.cancel(); // Hủy timer nếu đang chạy
    
    final nextIndex = _currentEpisodeIndex + 1;
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];

    if (currentServer.serverData.length > nextIndex) {
      setState(() {
        _currentEpisodeIndex = nextIndex;
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _showNextEpisodeNotice = false;
        _isAutoPlayStopped = false;
      });
      _initializeVideo();
    } else {
      setState(() {
        _showControls = true;
        _showNextEpisodeNotice = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_controller != null) {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
        WakelockPlus.enable(); // Đảm bảo bật lại khi nhấn play
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _changePlaybackSpeed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.only(top: 200),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.75)),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tốc độ phát', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _speedOptions.length,
                    itemBuilder: (context, index) {
                      final speed = _speedOptions[index];
                      final isSelected = _playbackSpeed == speed;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _playbackSpeed = speed;
                              });
                              _controller?.setPlaybackSpeed(speed);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              margin: EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red[700] : Colors.grey[850],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${speed}x',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            _buildVideoArea(),

            if (_showControls)
              _buildHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movieDetail.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.5),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentServer.serverData.length > 1)
                      Text(
                        '${currentServer.serverData[_currentEpisodeIndex].name} - ${currentServer.serverName}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Chỉ hiển thị video khi khởi tạo xong và KHÔNG ở trạng thái loading
            if (!_isLoading && _controller != null && _controller!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Nền đen và Loading khi đang tải tập mới
            if (_isLoading)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Đang tải tập mới...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            if (_controller != null && _controller!.value.isInitialized)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: () {
                        final current = _controller!.value.position;
                        _controller!.seekTo(current - const Duration(seconds: 10));
                        _showSeekFeedback(false);
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        color: Colors.transparent,
                        child: _showBackwardIcon 
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fast_rewind, color: Colors.white, size: 48),
                                  Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ) 
                          : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: () {
                        final current = _controller!.value.position;
                        _controller!.seekTo(current + const Duration(seconds: 10));
                        _showSeekFeedback(true);
                      },
                      behavior: HitTestBehavior.translucent,
                      child: Container(
                        color: Colors.transparent,
                        child: _showForwardIcon 
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fast_forward, color: Colors.white, size: 48),
                                  Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ) 
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
            
            if (_hasError)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeVideo,
                    child: Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),

            if (_showControls && _controller != null && _controller!.value.isInitialized)
              _buildVideoControls(),

            // Thanh thông báo chuyển tập tiếp theo
            if (_showNextEpisodeNotice)
              _buildNextEpisodeNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.replay_10, color: Colors.white, size: 32),
                      onPressed: () {
                        final current = _controller!.value.position;
                        _controller!.seekTo(current - Duration(seconds: 10));
                        _showSeekFeedback(false);
                      },
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    SizedBox(width: 20),
                    IconButton(
                      icon: Icon(Icons.forward_10, color: Colors.white, size: 32),
                      onPressed: () {
                        final current = _controller!.value.position;
                        _controller!.seekTo(current + Duration(seconds: 10));
                        _showSeekFeedback(true);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  VideoProgressIndicator(
                    _controller!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_controller!.value.position),
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
                            Text(" / ",
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                            Text(
                              _formatDuration(_controller!.value.duration),
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: _changePlaybackSpeed,
                        child: Icon(Icons.speed, color: Colors.white, size: 24),
                      ),
                      // Nút tập tiếp theo
                      if (widget.movieDetail.episodes[_currentServerIndex].serverData.length > _currentEpisodeIndex + 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: GestureDetector(
                            onTap: _goToNextEpisode,
                            child: Icon(Icons.skip_next, color: Colors.white, size: 28),
                          ),
                        ),
                      SizedBox(width: 10.0),
                      IconButton(
                        icon: Icon(
                            _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: Colors.white, size: 24),
                        onPressed: _toggleFullScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeekFeedback(bool isForward) {
    _seekIconTimer?.cancel();
    setState(() {
      if (isForward) {
        _showForwardIcon = true;
        _showBackwardIcon = false;
      } else {
        _showBackwardIcon = true;
        _showForwardIcon = false;
      }
    });

    _seekIconTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showForwardIcon = false;
          _showBackwardIcon = false;
        });
      }
    });
  }

  // Lưu lịch sử xem vào SharedPreferences (Vị trí thời gian)
  Future<void> _saveWatchHistory() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Chỉ lưu lịch sử nếu phim nằm trong danh sách "Xem Sau"
    final movieController = Get.find<MovieController>();
    if (!movieController.isMovieInWatchLater(widget.movieDetail.slug)) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final historyData = {
        'episodeIndex': _currentEpisodeIndex,
        'serverIndex': _currentServerIndex,
        'positionMs': _controller!.value.position.inMilliseconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'movieName': widget.movieDetail.name,
        'episodeName': widget.movieDetail.episodes[_currentServerIndex].serverData[_currentEpisodeIndex].name,
      };

      await prefs.setString('history_${widget.movieDetail.slug}', json.encode(historyData));
      
      // Lưu vị trí xem cho tập cụ thể (phục việc phát tiếp khi chuyển tập)
      await prefs.setInt('pos_${widget.movieDetail.slug}_${_currentServerIndex}_$_currentEpisodeIndex', _controller!.value.position.inMilliseconds);
      
      print('💾 Đã lưu lịch sử: ${_controller!.value.position.inSeconds}s (Tập ${_currentEpisodeIndex})');
    } catch (e) {
      print('❌ Lỗi khi lưu lịch sử: $e');
    }
  }

  // Đánh dấu tập hiện tại là đã xem
  Future<void> _markCurrentEpisodeAsWatched() async {
    // Chỉ đánh dấu tập đã xem nếu phim nằm trong danh sách "Xem Sau"
    final movieController = Get.find<MovieController>();
    if (!movieController.isMovieInWatchLater(widget.movieDetail.slug)) {
      return;
    }

    try {
      final currentServer = widget.movieDetail.episodes[_currentServerIndex];
      final episodeData = currentServer.serverData[_currentEpisodeIndex];
      
      final movieController = Get.find<MovieController>();
      await movieController.markEpisodeAsWatched(
        widget.movieDetail.slug,
        currentServer.serverName,
        episodeData.name,
      );
    } catch (e) {
      print('❌ Lỗi khi đánh dấu tập đã xem: $e');
    }
  }

  // Bắt đầu đếm ngược chuyển tập
  void _startCountdown() {
    _nextEpisodeTimer?.cancel();
    _nextEpisodeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        // Kiểm tra lại một lần nữa trước khi chuyển tập
        if (!_isAutoPlayStopped && _controller != null) {
          _goToNextEpisode();
        }
      }
    });
  }

  // Widget thông báo chuyển tập tiếp theo
  Widget _buildNextEpisodeNotice() {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    if (currentServer.serverData.length <= _currentEpisodeIndex + 1) return SizedBox.shrink();
    
    final nextEpisode = currentServer.serverData[_currentEpisodeIndex + 1];
    
    return Positioned(
      bottom: 120, // Cao hơn thanh tiến trình
      right: 20,
      child: AnimatedOpacity(
        opacity: _showNextEpisodeNotice ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          width: 280,
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tập tiếp theo sau $_countdownSeconds s',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAutoPlayStopped = true;
                        _showNextEpisodeNotice = false;
                      });
                      _nextEpisodeTimer?.cancel();
                    },
                    child: Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                nextEpisode.name,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToNextEpisode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Phát ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAutoPlayStopped = true;
                        _showNextEpisodeNotice = false;
                      });
                      _nextEpisodeTimer?.cancel();
                    },
                    child: Text('Dừng lại', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _countdownSeconds / 20,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}