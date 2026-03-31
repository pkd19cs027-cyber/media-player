import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
        title: Text(
          'Library',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white70),
            onPressed: () => _showAddOptions(context, provider),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white70),
            color: const Color(0xFF1A1A2E),
            onSelected: (value) {},
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'size', child: Text('Sort by Size')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          if (provider.categories.length > 1)
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.categories.length,
                itemBuilder: (ctx, i) {
                  final cat = provider.categories[i];
                  final isSelected = provider.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (_) => provider.setCategory(cat),
                      backgroundColor: const Color(0xFF1A1A2E),
                      selectedColor: const Color(0xFFE50914).withOpacity(0.2),
                      checkmarkColor: const Color(0xFFE50914),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : Colors.white60,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFE50914)
                            : Colors.white12,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatBadge(
                  label: '${provider.videos.length} videos',
                  icon: Icons.movie_outlined,
                ),
                const SizedBox(width: 8),
                _StatBadge(
                  label: '${provider.favorites.length} favorites',
                  icon: Icons.favorite_outline_rounded,
                  color: const Color(0xFFE50914),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: provider.videos.isEmpty
                ? Center(
                    child: Text(
                      'No videos found',
                      style: GoogleFonts.outfit(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: provider.videos.length,
                    itemBuilder: (ctx, i) => VideoCard(
                      video: provider.videos[i],
                      onTap: () => _playVideo(context, provider.videos[i]),
                      onFavorite: () =>
                          provider.toggleFavorite(provider.videos[i].id),
                      isGrid: true,
                    )
                        .animate(delay: Duration(milliseconds: 30 * i))
                        .fadeIn()
                        .scale(begin: const Offset(0.95, 0.95)),
                  ),
          ),
        ],
      ),
    );
  }

  void _playVideo(BuildContext context, VideoModel video) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
  }

  void _showAddOptions(BuildContext context, VideoProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141420),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_file_rounded,
                  color: Color(0xFFE50914)),
              title: const Text('Pick Videos', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                provider.pickVideos();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_rounded,
                  color: Color(0xFFE50914)),
              title: const Text('Add Folder', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                provider.pickFolder();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;

  const _StatBadge({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color ?? Colors.white54),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color ?? Colors.white54)),
        ],
      ),
    );
  }
}
