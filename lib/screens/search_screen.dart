import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/video_provider.dart';
import '../widgets/video_card.dart';
import '../models/video_model.dart';
import 'video_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? const Color(0xFFE50914).withOpacity(0.5)
                            : Colors.white12,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: provider.setSearchQuery,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search videos...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Colors.white38),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: Colors.white38, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: provider.searchQuery.isEmpty
                  ? _buildDefaultView(context, provider)
                  : _buildResults(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultView(BuildContext context, VideoProvider provider) {
    if (provider.allVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'No videos yet',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (provider.recentlyPlayed.isNotEmpty) ...[
          Text(
            'Recently Played',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...provider.recentlyPlayed.take(5).map(
                (v) => _VideoListTile(
                  video: v,
                  onTap: () => _playVideo(context, v),
                ),
              ),
          const SizedBox(height: 24),
        ],
        Text(
          'All Videos',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        ...provider.allVideos.map(
          (v) => _VideoListTile(
            video: v,
            onTap: () => _playVideo(context, v),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildResults(BuildContext context, VideoProvider provider) {
    final results = provider.videos;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                color: Colors.white24, size: 64),
            const SizedBox(height: 16),
            Text(
              'No results for "${provider.searchQuery}"',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (ctx, i) => _VideoListTile(
        video: results[i],
        onTap: () => _playVideo(context, results[i]),
      ).animate(delay: Duration(milliseconds: 30 * i)).fadeIn().slideX(),
    );
  }

  void _playVideo(BuildContext context, VideoModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
    );
  }
}

class _VideoListTile extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;

  const _VideoListTile({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141420),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE50914).withOpacity(0.3),
                    const Color(0xFF1A1A2E),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.movie_rounded,
                      color: Colors.white24, size: 28),
                  if (video.isInProgress)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10)),
                        child: LinearProgressIndicator(
                          value: video.watchProgress,
                          backgroundColor: Colors.black38,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE50914)),
                          minHeight: 3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        video.formattedDuration,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        video.formattedFileSize,
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE50914).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFFE50914),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
