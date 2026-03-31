import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_model.dart';

class VideoProvider extends ChangeNotifier {
  List<VideoModel> _videos = [];
  List<VideoModel> _recentlyPlayed = [];
  List<VideoModel> _favorites = [];
  VideoModel? _currentVideo;
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  int _currentNavIndex = 0;

  static const List<String> supportedExtensions = [
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', '3gp', 'ts'
  ];

  // Getters
  List<VideoModel> get videos => _filteredVideos;
  List<VideoModel> get allVideos => _videos;
  List<VideoModel> get recentlyPlayed => _recentlyPlayed;
  List<VideoModel> get favorites => _favorites;
  VideoModel? get currentVideo => _currentVideo;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  int get currentNavIndex => _currentNavIndex;

  List<VideoModel> get continueWatching =>
      _videos.where((v) => v.isInProgress).toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));

  List<VideoModel> get newVideos {
    final sorted = [..._videos];
    sorted.sort((a, b) =>
        (b.dateAdded ?? DateTime(0)).compareTo(a.dateAdded ?? DateTime(0)));
    return sorted.take(10).toList();
  }

  List<String> get categories {
    final cats = {'All', ..._videos.map((v) => v.category ?? 'Uncategorized')};
    return cats.toList();
  }

  List<VideoModel> get _filteredVideos {
    var list = [..._videos];
    if (_searchQuery.isNotEmpty) {
      list = list
          .where((v) =>
              v.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedCategory != 'All') {
      list = list
          .where((v) => (v.category ?? 'Uncategorized') == _selectedCategory)
          .toList();
    }
    return list;
  }

  VideoProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final videosJson = prefs.getStringList('videos') ?? [];
      _videos = videosJson
          .map((json) => VideoModel.fromJson(jsonDecode(json)))
          .where((v) => v.exists)
          .toList();

      _recentlyPlayed = _videos
          .where((v) => v.playCount > 0)
          .toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));

      _favorites = _videos.where((v) => v.isFavorite).toList();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final videosJson = _videos.map((v) => jsonEncode(v.toJson())).toList();
    await prefs.setStringList('videos', videosJson);
  }

  Future<void> pickVideos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            await _addVideo(file.path!);
          }
        }
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Error picking videos: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> pickFolder() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        await _scanDirectory(result);
        await _saveToPrefs();
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _scanDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        if (supportedExtensions.contains(ext)) {
          await _addVideo(entity.path);
        }
      }
    }
  }

  Future<void> _addVideo(String filePath) async {
    // Check if already added
    if (_videos.any((v) => v.path == filePath)) return;

    final file = File(filePath);
    if (!await file.exists()) return;

    final stat = await file.stat();
    final fileName = p.basename(filePath);
    final id = DateTime.now().millisecondsSinceEpoch.toString() +
        filePath.hashCode.toString();

    final video = VideoModel(
      id: id,
      title: fileName,
      path: filePath,
      fileSize: stat.size,
      dateAdded: stat.modified,
    );

    _videos.add(video);
  }

  void updateWatchProgress(String videoId, Duration position, Duration total) {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      _videos[index] = _videos[index].copyWith(watchPosition: position);
      if (total.inMilliseconds > 0) {
        _videos[index] = _videos[index].copyWith(duration: total);
      }
      _saveToPrefs();
      notifyListeners();
    }
  }

  void markPlayed(String videoId) {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      _videos[index] =
          _videos[index].copyWith(playCount: _videos[index].playCount + 1);

      _recentlyPlayed.removeWhere((v) => v.id == videoId);
      _recentlyPlayed.insert(0, _videos[index]);
      if (_recentlyPlayed.length > 20) _recentlyPlayed.removeLast();

      _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleFavorite(String videoId) {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index != -1) {
      final newFav = !_videos[index].isFavorite;
      _videos[index] = _videos[index].copyWith(isFavorite: newFav);

      if (newFav) {
        _favorites.add(_videos[index]);
      } else {
        _favorites.removeWhere((v) => v.id == videoId);
      }

      _saveToPrefs();
      notifyListeners();
    }
  }

  void setCurrentVideo(VideoModel? video) {
    _currentVideo = video;
    if (video != null) markPlayed(video.id);
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    notifyListeners();
  }

  void removeVideo(String videoId) {
    _videos.removeWhere((v) => v.id == videoId);
    _recentlyPlayed.removeWhere((v) => v.id == videoId);
    _favorites.removeWhere((v) => v.id == videoId);
    _saveToPrefs();
    notifyListeners();
  }

  void clearAll() {
    _videos.clear();
    _recentlyPlayed.clear();
    _favorites.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
