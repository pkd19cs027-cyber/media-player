import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/video_provider.dart';
import '../models/video_model.dart';
import '../widgets/video_card.dart';
import '../widgets/featured_banner.dart';
import '../widgets/section_header.dart';
import 'video_player_screen.dart';
import 'dart:math';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0F),
            expandedHeight: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0A0A0F),
                    const Color(0xFF0A0A0F).withOpacity(0),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE50914), Color(0xFFFF6B35)],
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'FlixLocal',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 24,
                    letterSpacing: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white70),
                onPressed: () => _showAddOptions(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white70),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          if (provider.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE50914),
                ),
              ),
            )
          else if (provider.allVideos.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                onAdd: () => _showAddOptions(context, provider),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                // Featured Banner
                if (provider.allVideos.isNotEmpty)
                  FeaturedBanner(
                    video: provider
                        .allVideos[Random().nextInt(provider.allVideos.length)],
                    onPlay: (video) => _playVideo(context, video),
                    onFavorite: (video) => provider.toggleFavorite(video.id),
                  ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: 24),

                // Continue Watching
                if (provider.continueWatching.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Continue Watching',
                    icon: Icons.play_circle_outline_rounded,
                    onSeeAll: () => provider.setNavIndex(1),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: provider.continueWatching.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ContinueWatchingCard(
                          video: provider.continueWatching[i],
                          onTap: () =>
                              _playVideo(context, provider.continueWatching[i]),
                        ),
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideX(begin: 0.1),
                  const SizedBox(height: 28),
                ],

                // Recently Added
                SectionHeader(
                  title: 'Recently Added',
                  icon: Icons.fiber_new_rounded,
                  onSeeAll: () => provider.setNavIndex(1),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.newVideos.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: VideoCard(
                        video: provider.newVideos[i],
                        onTap: () => _playVideo(context, provider.newVideos[i]),
                        onFavorite: () =>
                            provider.toggleFavorite(provider.newVideos[i].id),
                      ),
                    ),
                  ),
                ).animate(delay: 200.ms).fadeIn().slideX(begin: 0.1),
                const SizedBox(height: 28),

                // All Videos
                SectionHeader(
                  title: 'All Videos',
                  icon: Icons.video_library_rounded,
                  onSeeAll: () => provider.setNavIndex(1),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: provider.allVideos.length > 6
                      ? 6
                      : provider.allVideos.length,
                  itemBuilder: (ctx, i) => VideoCard(
                    video: provider.allVideos[i],
                    onTap: () => _playVideo(context, provider.allVideos[i]),
                    onFavorite: () =>
                        provider.toggleFavorite(provider.allVideos[i].id),
                    isGrid: true,
                  )
                      .animate(delay: Duration(milliseconds: 50 * i))
                      .fadeIn()
                      .scale(begin: const Offset(0.9, 0.9)),
                ),
                const SizedBox(height: 100),
              ]),
            ),
        ],
      ),
    );
  }

  void _showAddOptions(BuildContext context, VideoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddOptionsSheet(provider: provider),
    );
  }

  void _playVideo(BuildContext context, VideoModel video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE50914).withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFFE50914).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Color(0xFFE50914),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 28),
          Text(
            'Your Cinema Awaits',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
          const SizedBox(height: 12),
          Text(
            'Add your video files or entire folders\nto start watching.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.white38,
              height: 1.6,
            ),
          ).animate(delay: 300.ms).fadeIn(),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50914),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Add Videos',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.2),
        ],
      ),
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  final VideoProvider provider;

  const _AddOptionsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Add Content',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _SheetOption(
            icon: Icons.video_file_rounded,
            title: 'Pick Videos',
            subtitle: 'Select individual video files',
            onTap: () {
              Navigator.pop(context);
              provider.pickVideos();
            },
          ),
          const SizedBox(height: 12),
          _SheetOption(
            icon: Icons.folder_rounded,
            title: 'Add Folder',
            subtitle: 'Scan entire folder for videos',
            onTap: () {
              Navigator.pop(context);
              provider.pickFolder();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFE50914), size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
