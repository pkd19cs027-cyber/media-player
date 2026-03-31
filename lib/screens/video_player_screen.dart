import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video_model.dart';
import '../providers/video_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
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
      _videoController = VideoPlayerController.file(widget.video.file);
      await _videoController!.initialize();

      // Seek to last position
      if (widget.video.watchPosition > Duration.zero) {
        await _videoController!.seekTo(widget.video.watchPosition);
      }

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
        placeholder: Container(color: Colors.black),
        autoInitialize: true,
      );

      // Update progress periodically
      _videoController!.addListener(_progressListener);

      setState(() => _isInitialized = true);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Could not play this video.\n${e.toString()}';
      });
    }
  }

  void _progressListener() {
    if (_videoController == null) return;
    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;
    if (dur.inSeconds > 0) {
      context.read<VideoProvider>().updateWatchProgress(
            widget.video.id,
            pos,
            dur,
          );
    }
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

    _videoController?.removeListener(_progressListener);
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video Player Area
          Expanded(
            flex: _isLandscape(context) ? 1 : 0,
            child: Container(
              color: Colors.black,
              child: _buildPlayer(),
            ),
          ),

          // Info Panel (portrait only)
          if (!_isLandscape(context))
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
      return _ErrorWidget(message: _errorMessage, onBack: () => Navigator.pop(context));
    }

    if (!_isInitialized) {
      return _LoadingWidget(video: widget.video, onBack: () => Navigator.pop(context));
    }

    return SizedBox(
      width: double.infinity,
      height: _isLandscape(context)
          ? double.infinity
          : MediaQuery.of(context).size.width * 9 / 16 + 56,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),
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
    final provider = context.watch<VideoProvider>();

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
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? const Color(0xFFE50914) : Colors.white54,
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
                    style: const TextStyle(
                        color: Color(0xFFE50914), fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.video.watchProgress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFE50914)),
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
