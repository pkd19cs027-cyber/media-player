import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      color: Color(0xFFE50914), size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Favorites',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  if (provider.favorites.isNotEmpty)
                    Text(
                      '${provider.favorites.length}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white38,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: provider.favorites.isEmpty
                    ? _EmptyFavorites()
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: provider.favorites.length,
                        itemBuilder: (ctx, i) {
                          final video = provider.favorites[i];
                          return VideoCard(
                            video: video,
                            onTap: () => _playVideo(context, video),
                            onFavorite: () =>
                                provider.toggleFavorite(video.id),
                            isGrid: true,
                          )
                              .animate(
                                  delay: Duration(milliseconds: 50 * i))
                              .fadeIn()
                              .scale(
                                  begin: const Offset(0.9, 0.9));
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE50914).withOpacity(0.08),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 44,
              color: Color(0xFFE50914),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn(),
          const SizedBox(height: 8),
          Text(
            'Tap the ♥ on any video to\nadd it to your favorites.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: Colors.white38,
              height: 1.6,
            ),
          ).animate(delay: 300.ms).fadeIn(),
        ],
      ),
    );
  }
}
