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
  String _friendlyErrorTitle = 'Không thể phát video';
  String _friendlyErrorMessage = 'Đã xảy ra sự cố khi tải video. Vui lòng thử lại sau.';
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
          _handleVideoError(e);
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      } else {
        _friendlyErrorTitle = 'Không tìm thấy video';
        _friendlyErrorMessage = 'Không tìm thấy đường dẫn video cho tập phim này. Vui lòng chọn tập hoặc server khác.';
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  void _toggleFullScreen() async {
    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isLandscape) {
      _isFullScreen = false;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      _isFullScreen = true;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _videoListener() {
    if (_controller != null && _controller!.value.isInitialized) {
      if (_controller!.value.hasError) {
        _handleVideoError(_controller!.value.errorDescription);
        setState(() {
          _hasError = true;
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
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = orientation == Orientation.landscape;
        _isFullScreen = isLandscape;

        return PopScope(
          canPop: !isLandscape,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && isLandscape) {
              _toggleFullScreen();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: isLandscape
                ? _buildVideoArea()
                : SafeArea(
                    child: Column(
                      children: [
                        // Khung video player ở trên cùng (tỷ lệ chuẩn 16:9)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _buildVideoArea(),
                        ),
                        // Thông tin phim và danh sách tập cuộn bên dưới
                        Expanded(
                          child: _buildPortraitDetails(),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isFullScreen ? 16 : 8,
          vertical: _isFullScreen ? 8 : 4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.75),
              Colors.black.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                if (_isFullScreen) {
                  _toggleFullScreen();
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.movieDetail.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isFullScreen ? 16 : 13.5,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentServer.serverData.isNotEmpty && _currentEpisodeIndex < currentServer.serverData.length)
                    Text(
                      '${currentServer.serverData[_currentEpisodeIndex].name} - ${currentServer.serverName}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: _isFullScreen ? 12 : 11,
                        shadows: [
                          Shadow(
                            offset: const Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.7),
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
    );
  }

  Widget _buildVideoArea() {
    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video Player
            if (!_isLoading && _controller != null && _controller!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Nền đen và Loading khi đang tải
            if (_isLoading)
              Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Đang tải video...',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: _isFullScreen ? 15 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Phản hồi tua 10s khi double tap
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
                                  Icon(Icons.fast_rewind, color: Colors.white, size: _isFullScreen ? 48 : 34),
                                  Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: _isFullScreen ? 14 : 12)),
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
                                  Icon(Icons.fast_forward, color: Colors.white, size: _isFullScreen ? 48 : 34),
                                  Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: _isFullScreen ? 14 : 12)),
                                ],
                              ),
                            ) 
                          : null,
                      ),
                    ),
                  ),
                ],
              ),
            
            // Error State
            if (_hasError)
              _buildErrorState(),

            // Video Controls và Header với hiệu ứng mờ dần mượt mà
            if (_controller != null && _controller!.value.isInitialized && !_hasError)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Stack(
                      children: [
                        _buildVideoControls(),
                        _buildHeader(),
                      ],
                    ),
                  ),
                ),
              ),

            // Luôn hiện Header khi đang loading hoặc có lỗi để người dùng có thể bấm Quay lại
            if ((_hasError || _isLoading) && _showControls)
              _buildHeader(),

            // Thanh thông báo đếm ngược chuyển tập tiếp theo
            if (_showNextEpisodeNotice)
              _buildNextEpisodeNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.75),
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
                    icon: Icon(Icons.replay_10, color: Colors.white, size: _isFullScreen ? 32 : 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final current = _controller!.value.position;
                      _controller!.seekTo(current - const Duration(seconds: 10));
                      _showSeekFeedback(false);
                    },
                  ),
                  SizedBox(width: _isFullScreen ? 24 : 16),
                  IconButton(
                    onPressed: _togglePlayPause,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      size: _isFullScreen ? 64 : 46,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  SizedBox(width: _isFullScreen ? 24 : 16),
                  IconButton(
                    icon: Icon(Icons.forward_10, color: Colors.white, size: _isFullScreen ? 32 : 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final current = _controller!.value.position;
                      _controller!.seekTo(current + const Duration(seconds: 10));
                      _showSeekFeedback(true);
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isFullScreen ? 16 : 10,
              vertical: _isFullScreen ? 10 : 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoProgressIndicator(
                  _controller!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                SizedBox(height: _isFullScreen ? 8 : 4),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_controller!.value.position),
                            style: TextStyle(color: Colors.white, fontSize: _isFullScreen ? 14 : 11.5),
                          ),
                          Text(
                            " / ",
                            style: TextStyle(color: Colors.grey, fontSize: _isFullScreen ? 14 : 11.5),
                          ),
                          Text(
                            _formatDuration(_controller!.value.duration),
                            style: TextStyle(color: Colors.grey, fontSize: _isFullScreen ? 14 : 11.5),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _changePlaybackSpeed,
                      child: Icon(Icons.speed, color: Colors.white, size: _isFullScreen ? 24 : 19),
                    ),
                    // Nút danh sách tập phim (khi ở toàn màn hình ngang)
                    if (_isFullScreen && widget.movieDetail.episodes[_currentServerIndex].serverData.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0),
                        child: GestureDetector(
                          onTap: () => _showEpisodesDialog(context),
                          child: const Icon(Icons.playlist_play_rounded, color: Colors.white, size: 26),
                        ),
                      ),
                    // Nút tập tiếp theo
                    if (widget.movieDetail.episodes[_currentServerIndex].serverData.length > _currentEpisodeIndex + 1)
                      Padding(
                        padding: EdgeInsets.only(left: _isFullScreen ? 14.0 : 10.0),
                        child: GestureDetector(
                          onTap: _goToNextEpisode,
                          child: Icon(Icons.skip_next, color: Colors.white, size: _isFullScreen ? 28 : 22),
                        ),
                      ),
                    SizedBox(width: _isFullScreen ? 10.0 : 6.0),
                    IconButton(
                      icon: Icon(
                        _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: Colors.white,
                        size: _isFullScreen ? 26 : 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _toggleFullScreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitDetails() {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tên phim - Tập hiện tại
            _buildMovieTitle(),
            const SizedBox(height: 20),

            // 2. Danh sách tập phim
            _buildEpisodesSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieTitle() {
    String titleText = widget.movieDetail.name;
    if (widget.movieDetail.episodes.isNotEmpty &&
        _currentServerIndex < widget.movieDetail.episodes.length) {
      final currentServer = widget.movieDetail.episodes[_currentServerIndex];
      if (currentServer.serverData.isNotEmpty &&
          _currentEpisodeIndex < currentServer.serverData.length) {
        final epName = currentServer.serverData[_currentEpisodeIndex].name;
        titleText = '${widget.movieDetail.name} - $epName';
      }
    }

    return Text(
      titleText,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 0.3,
        height: 1.3,
      ),
    );
  }

  Widget _buildEpisodesSection() {
    if (widget.movieDetail.episodes.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    final serverData = currentServer.serverData;

    if (serverData.isEmpty) {
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
      builder: (movieController) {
        final watchedEpisodes = movieController.getWatchedEpisodes(widget.movieDetail.slug);

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
            const SizedBox(height: 12),
            GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: serverData.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final ep = serverData[index];
                final isCurrent = index == _currentEpisodeIndex;
                final isWatched = watchedEpisodes.contains('${currentServer.serverName}_${ep.name}');

                Color bgColor;
                if (isCurrent) {
                  bgColor = Colors.red;
                } else if (isWatched) {
                  bgColor = Colors.orange;
                } else {
                  bgColor = Colors.grey[900]!;
                }

                return InkWell(
                  onTap: () {
                    if (!isCurrent) {
                      _changeEpisode(index);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent
                          ? Border.all(color: Colors.redAccent, width: 1.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCurrent) ...[
                          const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 3),
                        ] else if (isWatched) ...[
                          const Icon(Icons.check_circle, color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                        ],
                        Flexible(
                          child: Text(
                            ep.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
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
    if (currentServer.serverData.length <= _currentEpisodeIndex + 1) return const SizedBox.shrink();
    
    final nextEpisode = currentServer.serverData[_currentEpisodeIndex + 1];

    if (!_isFullScreen) {
      // Mini banner cho khung video ở chế độ dọc
      return Positioned(
        bottom: 38,
        left: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.8), width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_outline, color: Colors.redAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tập tiếp sau ${_countdownSeconds}s: ${nextEpisode.name}',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _goToNextEpisode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Phát', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAutoPlayStopped = true;
                    _showNextEpisodeNotice = false;
                  });
                  _nextEpisodeTimer?.cancel();
                },
                child: const Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Positioned(
      bottom: 120, // Cao hơn thanh tiến trình
      right: 20,
      child: AnimatedOpacity(
        opacity: _showNextEpisodeNotice ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1),
            boxShadow: const [
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
                  const Icon(Icons.play_circle_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tập tiếp theo sau $_countdownSeconds s',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAutoPlayStopped = true;
                        _showNextEpisodeNotice = false;
                      });
                      _nextEpisodeTimer?.cancel();
                    },
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                nextEpisode.name,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _goToNextEpisode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Phát ngay', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isAutoPlayStopped = true;
                        _showNextEpisodeNotice = false;
                      });
                      _nextEpisodeTimer?.cancel();
                    },
                    child: const Text('Dừng lại', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _countdownSeconds / 20,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  minHeight: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVideoError(dynamic error) {
    final rawError = error?.toString() ?? '';
    debugPrint('🚨 [Video Player Error Detail]: $rawError');

    if (rawError.contains('MediaCodec') ||
        rawError.contains('VideoError') ||
        rawError.contains('Renderer') ||
        rawError.contains('format_supported') ||
        rawError.contains('Format(')) {
      _friendlyErrorTitle = 'Định dạng video không tương thích';
      _friendlyErrorMessage =
          'Bộ giải mã phần cứng trên thiết bị không hỗ trợ tỷ lệ phân giải này của tập phim. Vui lòng thử lại hoặc chọn tập khác.';
    } else if (rawError.contains('SocketException') ||
        rawError.contains('TimeoutException') ||
        rawError.contains('HttpDataSource') ||
        rawError.contains('network') ||
        rawError.contains('connection') ||
        rawError.contains('Failed to connect')) {
      _friendlyErrorTitle = 'Lỗi kết nối mạng';
      _friendlyErrorMessage =
          'Không thể tải dữ liệu video do đường truyền internet không ổn định. Vui lòng kiểm tra lại kết nối Wi-Fi hoặc 4G.';
    } else if (rawError.contains('403') ||
        rawError.contains('404') ||
        rawError.contains('not found')) {
      _friendlyErrorTitle = 'Nguồn phát tạm thời gián đoạn';
      _friendlyErrorMessage =
          'Nguồn phát của tập phim này tạm thời bị gián đoạn từ máy chủ. Vui lòng chọn tập hoặc server khác.';
    } else {
      _friendlyErrorTitle = 'Không thể phát video này';
      _friendlyErrorMessage =
          'Đã xảy ra sự cố khi tải luồng phát video. Vui lòng nhấn Thử lại hoặc chọn tập khác.';
    }
  }

  void _changeEpisode(int newIndex) {
    _nextEpisodeTimer?.cancel();
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    if (newIndex >= 0 && newIndex < currentServer.serverData.length) {
      setState(() {
        _currentEpisodeIndex = newIndex;
        _isLoading = true;
        _hasError = false;
        _showNextEpisodeNotice = false;
        _isAutoPlayStopped = false;
      });
      _initializeVideo();
    }
  }

  void _changeServer(int newServerIndex) {
    if (newServerIndex >= 0 && newServerIndex < widget.movieDetail.episodes.length) {
      setState(() {
        _currentServerIndex = newServerIndex;
        if (_currentEpisodeIndex >= widget.movieDetail.episodes[newServerIndex].serverData.length) {
          _currentEpisodeIndex = 0;
        }
        _isLoading = true;
        _hasError = false;
      });
      _initializeVideo();
    }
  }

  void _showEpisodesDialog(BuildContext context) {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.playlist_play_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Danh sách tập phim',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: currentServer.serverData.length,
                    itemBuilder: (context, index) {
                      final isCurrent = index == _currentEpisodeIndex;
                      final ep = currentServer.serverData[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          if (!isCurrent) {
                            _changeEpisode(index);
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isCurrent ? Colors.red : const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent ? Colors.redAccent : Colors.white12,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            ep.name,
                            style: TextStyle(
                              color: isCurrent ? Colors.white : Colors.white70,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showServersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF161616),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dns_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chọn Server phát',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...List.generate(widget.movieDetail.episodes.length, (index) {
                  final server = widget.movieDetail.episodes[index];
                  final isCurrent = index == _currentServerIndex;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!isCurrent) {
                        _changeServer(index);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isCurrent ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent ? Colors.redAccent : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isCurrent ? Colors.redAccent : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              server.serverName,
                              style: TextStyle(
                                color: isCurrent ? Colors.white : Colors.white70,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    final currentServer = widget.movieDetail.episodes[_currentServerIndex];
    final hasMultipleServers = widget.movieDetail.episodes.length > 1;
    final hasMultipleEpisodes = currentServer.serverData.length > 1;

    if (!_isFullScreen) {
      // Compact error card cho khung player phía trên khi ở chế độ dọc
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161616).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _friendlyErrorTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _friendlyErrorMessage,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _initializeVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.refresh_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Thử lại',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (_isFullScreen) {
                        _toggleFullScreen();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_back, color: Colors.white70, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Quay lại',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: const Color(0xFF161616).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                color: Colors.redAccent,
                size: 34,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _friendlyErrorTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _friendlyErrorMessage,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12.5,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                InkWell(
                  onTap: _initializeVideo,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50914), Color(0xFFB81D24)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Thử lại',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasMultipleEpisodes)
                  InkWell(
                    onTap: () => _showEpisodesDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.playlist_play_rounded, color: Colors.white70, size: 17),
                          SizedBox(width: 5),
                          Text(
                            'Chọn tập',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (hasMultipleServers)
                  InkWell(
                    onTap: () => _showServersDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF262626),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.dns_rounded, color: Colors.white70, size: 16),
                          SizedBox(width: 5),
                          Text(
                            'Đổi Server',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    if (_isFullScreen) {
                      _toggleFullScreen();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back, color: Colors.white60, size: 15),
                        SizedBox(width: 4),
                        Text(
                          'Quay lại',
                          style: TextStyle(color: Colors.white60, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}