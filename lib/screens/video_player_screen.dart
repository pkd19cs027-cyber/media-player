import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';

enum _GestureAxis { none, horizontal, vertical }

enum _VerticalGestureMode { none, brightness, volume }

class _GestureHudData {
  final IconData icon;
  final String label;
  final double value;

  const _GestureHudData({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;
  Timer? _gestureHudTimer;
  final ValueNotifier<_GestureHudData?> _gestureHudNotifier =
      ValueNotifier<_GestureHudData?>(null);
  late final VideoProvider _videoProvider;
  _GestureAxis _gestureAxis = _GestureAxis.none;
  _VerticalGestureMode _verticalGestureMode = _VerticalGestureMode.none;
  Offset _gestureDelta = Offset.zero;
  bool _isLeftSideGesture = false;
  double _pendingSeekSeconds = 0;
  double _brightnessLevel = 0.5;
  double _volumeLevel = 1.0;
  int _lastProgressSecond = -1;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _videoProvider = context.read<VideoProvider>();
    _loadInitialGestureValues();
    _isFavorite = widget.video.isFavorite;
    _initPlayer();

    // Allow landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.file(
        widget.video.file,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: false,
          mixWithOthers: false,
        ),
      );
      await _videoController!.initialize();
      _volumeLevel = _videoController!.value.volume.clamp(0.0, 1.0);

      // Seek to last position
      if (widget.video.watchPosition > Duration.zero) {
        await _videoController!.seekTo(widget.video.watchPosition);
      }
      _lastProgressSecond = widget.video.watchPosition.inSeconds;

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: const Color(0xFFE50914),
          handleColor: const Color(0xFFFF6B35),
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: const ColoredBox(color: Colors.black),
        autoInitialize: true,
      );

      _startProgressUpdates();

      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Could not play this video.\n${e.toString()}';
      });
    }
  }

  void _startProgressUpdates() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final controller = _videoController;
      if (controller == null) return;

      final value = controller.value;
      if (!value.isInitialized) return;
      if (!value.isPlaying) return;

      final dur = value.duration;
      if (dur.inSeconds <= 0) return;

      final posInSeconds = value.position.inSeconds;
      if (posInSeconds == _lastProgressSecond) return;
      _lastProgressSecond = posInSeconds;

      _videoProvider.updateWatchProgress(
        widget.video.id,
        value.position,
        dur,
      );
    });
  }

  Future<void> _loadInitialGestureValues() async {
    try {
      _brightnessLevel =
          (await ScreenBrightness.instance.application).clamp(0.0, 1.0);
    } catch (_) {
      _brightnessLevel = 0.5;
    }
  }

  void _onPlayerPanStart(DragStartDetails details) {
    _gestureDelta = Offset.zero;
    _pendingSeekSeconds = 0;
    _gestureAxis = _GestureAxis.none;
    _verticalGestureMode = _VerticalGestureMode.none;
    _isLeftSideGesture =
        details.localPosition.dx < (MediaQuery.of(context).size.width / 2);
    _gestureHudTimer?.cancel();
  }

  void _onPlayerPanUpdate(DragUpdateDetails details) {
    _gestureDelta += details.delta;

    if (_gestureAxis == _GestureAxis.none) {
      if (_gestureDelta.distance < 8) return;

      final isHorizontal = _gestureDelta.dx.abs() >= _gestureDelta.dy.abs();
      _gestureAxis =
          isHorizontal ? _GestureAxis.horizontal : _GestureAxis.vertical;

      if (_gestureAxis == _GestureAxis.vertical) {
        _verticalGestureMode = _isLeftSideGesture
            ? _VerticalGestureMode.brightness
            : _VerticalGestureMode.volume;
      }
    }

    if (_gestureAxis == _GestureAxis.horizontal) {
      _handleHorizontalGesture(details.delta.dx);
    } else if (_gestureAxis == _GestureAxis.vertical) {
      _handleVerticalGesture(details.delta.dy);
    }
  }

  Future<void> _onPlayerPanEnd(DragEndDetails details) async {
    if (_gestureAxis == _GestureAxis.horizontal) {
      final controller = _videoController;
      if (controller != null && controller.value.isInitialized) {
        final value = controller.value;
        final duration = value.duration;
        final deltaSeconds = _pendingSeekSeconds.round();
        if (duration.inSeconds > 0 && deltaSeconds != 0) {
          final target = _clampPosition(
            value.position + Duration(seconds: deltaSeconds),
            duration,
          );
          await controller.seekTo(target);
          _lastProgressSecond = target.inSeconds;
          _videoProvider.updateWatchProgress(widget.video.id, target, duration);

          final sign = deltaSeconds > 0 ? '+' : '';
          _updateGestureHud(
            icon: deltaSeconds > 0
                ? Icons.fast_forward_rounded
                : Icons.fast_rewind_rounded,
            text: '$sign${deltaSeconds}s  ${_formatDuration(target)}',
            value: duration.inMilliseconds > 0
                ? (target.inMilliseconds / duration.inMilliseconds)
                : 0,
          );
        }
      }
    }

    _gestureAxis = _GestureAxis.none;
    _verticalGestureMode = _VerticalGestureMode.none;
    _pendingSeekSeconds = 0;
    _scheduleGestureHudHide();
  }

  void _handleHorizontalGesture(double deltaX) {
    _pendingSeekSeconds =
        (_pendingSeekSeconds + (deltaX / 14)).clamp(-180, 180);
    final seconds = _pendingSeekSeconds.round();
    final sign = seconds >= 0 ? '+' : '';
    _updateGestureHud(
      icon:
          seconds >= 0 ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
      text: '$sign${seconds}s',
      value: 0,
    );
  }

  void _handleVerticalGesture(double deltaY) {
    final change = (-deltaY / 260).clamp(-0.08, 0.08).toDouble();

    if (_verticalGestureMode == _VerticalGestureMode.brightness) {
      _brightnessLevel = (_brightnessLevel + change).clamp(0.05, 1.0);
      unawaited(
        ScreenBrightness.instance
            .setApplicationScreenBrightness(_brightnessLevel)
            .catchError((_) {}),
      );

      _updateGestureHud(
        icon: Icons.brightness_6_rounded,
        text: 'Brightness ${(_brightnessLevel * 100).round()}%',
        value: _brightnessLevel,
      );
      return;
    }

    if (_verticalGestureMode == _VerticalGestureMode.volume) {
      _volumeLevel = (_volumeLevel + change).clamp(0.0, 1.0);
      _videoController?.setVolume(_volumeLevel);

      _updateGestureHud(
        icon: _volumeLevel == 0
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        text: 'Volume ${(_volumeLevel * 100).round()}%',
        value: _volumeLevel,
      );
    }
  }

  Duration _clampPosition(Duration value, Duration max) {
    if (value < Duration.zero) return Duration.zero;
    if (value > max) return max;
    return value;
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void _updateGestureHud({
    required IconData icon,
    required String text,
    required double value,
  }) {
    _gestureHudTimer?.cancel();
    _gestureHudNotifier.value = _GestureHudData(
      icon: icon,
      label: text,
      value: value.clamp(0.0, 1.0),
    );
  }

  void _scheduleGestureHudHide() {
    _gestureHudTimer?.cancel();
    _gestureHudTimer = Timer(const Duration(milliseconds: 700), () {
      _gestureHudNotifier.value = null;
    });
  }

  @override
  void dispose() {
    // Reset orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final value = _videoController?.value;
    if (value != null && value.isInitialized && value.duration.inSeconds > 0) {
      _videoProvider.updateWatchProgress(
        widget.video.id,
        value.position,
        value.duration,
        forcePersist: true,
      );
    }

    _progressTimer?.cancel();
    _gestureHudTimer?.cancel();
    _gestureHudNotifier.dispose();
    unawaited(
      ScreenBrightness.instance
          .resetApplicationScreenBrightness()
          .catchError((_) {}),
    );
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = _isLandscape(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video Player Area
          if (isLandscape)
            Expanded(child: _buildPlayer())
          else
            SizedBox(
              height: MediaQuery.of(context).size.width * 9 / 16 + 56,
              child: _buildPlayer(),
            ),

          // Info Panel (portrait only)
          if (!isLandscape)
            Expanded(
              child: _buildInfoPanel(context),
            ),
        ],
      ),
    );
  }

  bool _isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  Widget _buildPlayer() {
    if (_hasError) {
      return _ErrorWidget(
          message: _errorMessage, onBack: () => Navigator.pop(context));
    }

    if (!_isInitialized) {
      return _LoadingWidget(
          video: widget.video, onBack: () => Navigator.pop(context));
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          RepaintBoundary(
            child: Chewie(controller: _chewieController!),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: _onPlayerPanStart,
              onPanUpdate: _onPlayerPanUpdate,
              onPanEnd: _onPlayerPanEnd,
            ),
          ),
          ValueListenableBuilder<_GestureHudData?>(
            valueListenable: _gestureHudNotifier,
            builder: (context, hud, _) {
              if (hud == null) return const SizedBox.shrink();
              return Center(
                child: _GestureHud(
                  icon: hud.icon,
                  label: hud.label,
                  value: hud.value,
                ),
              );
            },
          ),
          // Back button overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    final provider = _videoProvider;

    return Container(
      color: const Color(0xFF0A0A0F),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Favorite
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.video.displayTitle,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    provider.toggleFavorite(widget.video.id);
                    setState(() => _isFavorite = !_isFavorite);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isFavorite
                          ? const Color(0xFFE50914).withOpacity(0.2)
                          : Colors.white.withOpacity(0.08),
                    ),
                    child: Icon(
                      _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFavorite
                          ? const Color(0xFFE50914)
                          : Colors.white54,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(
                  icon: Icons.timer_outlined,
                  label: widget.video.formattedDuration,
                ),
                _MetaChip(
                  icon: Icons.storage_outlined,
                  label: widget.video.formattedFileSize,
                ),
                _MetaChip(
                  icon: Icons.videocam_outlined,
                  label: widget.video.extension,
                  color: const Color(0xFFE50914),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress bar
            if (widget.video.watchProgress > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progress',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  Text(
                    '${(widget.video.watchProgress * 100).toInt()}% watched',
                    style:
                        const TextStyle(color: Color(0xFFE50914), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.video.watchProgress,
                  backgroundColor: Colors.white12,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.replay_rounded,
                    label: 'Restart',
                    onTap: () {
                      _videoController?.seekTo(Duration.zero);
                      _videoController?.play();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    color: Colors.red.withOpacity(0.1),
                    iconColor: Colors.red,
                    onTap: () {
                      provider.removeVideo(widget.video.id);
                      Navigator.pop(context);
                    },
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? Colors.white).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white60),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? iconColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: iconColor ?? Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GestureHud extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;

  const _GestureHud({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFE50914)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onBack;

  const _LoadingWidget({required this.video, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.width * 9 / 16 + 56,
      color: const Color(0xFF0D0D18),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFE50914),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: onBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onBack;

  const _ErrorWidget({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D18),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFE50914), size: 56),
              const SizedBox(height: 16),
              Text(
                'Playback Error',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
