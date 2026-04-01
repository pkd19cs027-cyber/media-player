import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video_model.dart';

class VideoCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback? onLongPress;
  final bool showSelection;
  final bool isSelected;
  final bool isGrid;

  const VideoCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onFavorite,
    this.onLongPress,
    this.showSelection = false,
    this.isSelected = false,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: isGrid ? null : 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF141420),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE50914)
                : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient BG
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _getColorFromTitle(video.title).withOpacity(0.4),
                            const Color(0xFF0D0D18),
                          ],
                        ),
                      ),
                    ),

                    // Icon
                    Center(
                      child: Icon(
                        Icons.movie_rounded,
                        color: Colors.white.withOpacity(0.15),
                        size: isGrid ? 40 : 32,
                      ),
                    ),

                    // Play button overlay
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(color: Colors.white54, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _ExtBadge(ext: video.extension),
                    ),

                    if (showSelection && isSelected)
                      Positioned.fill(
                        child: Container(
                          color: const Color(0x4DE50914),
                        ),
                      ),

                    if (showSelection)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? const Color(0xFFE50914)
                                : Colors.black54,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF6B35)
                                  : Colors.white30,
                            ),
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check_rounded
                                : Icons.circle_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: onFavorite,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: Icon(
                              video.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: video.isFavorite
                                  ? const Color(0xFFE50914)
                                  : Colors.white60,
                              size: 16,
                            ),
                          ),
                        ),
                      ),

                    // Progress bar
                    if (video.watchProgress > 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: LinearProgressIndicator(
                          value: video.watchProgress,
                          backgroundColor: Colors.black38,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE50914)),
                          minHeight: 3,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    video.formattedDuration,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromTitle(String title) {
    final colors = [
      const Color(0xFFE50914),
      const Color(0xFF4A90D9),
      const Color(0xFF7B68EE),
      const Color(0xFFFF6B35),
      const Color(0xFF00C9A7),
      const Color(0xFFFFD93D),
    ];
    return colors[title.hashCode.abs() % colors.length];
  }
}

class ContinueWatchingCard extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const ContinueWatchingCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF141420),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF1A1A2E),
                        _getColorFromTitle(video.title).withOpacity(0.15),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _getColorFromTitle(video.title).withOpacity(0.2),
                    ),
                    child: const Icon(Icons.movie_rounded,
                        color: Colors.white54, size: 26),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          video.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: video.watchProgress,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFE50914)),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(video.watchProgress * 100).toInt()}% watched',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorFromTitle(String title) {
    final colors = [
      const Color(0xFFE50914),
      const Color(0xFF4A90D9),
      const Color(0xFF7B68EE),
      const Color(0xFFFF6B35),
    ];
    return colors[title.hashCode.abs() % colors.length];
  }
}

class _ExtBadge extends StatelessWidget {
  final String ext;

  const _ExtBadge({required this.ext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        ext,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
