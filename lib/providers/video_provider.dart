import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
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
  DateTime? _lastProgressPersistAt;

  static const Duration _progressPersistInterval = Duration(seconds: 10);

  static const List<String> supportedExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
    '3gp',
    'ts'
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

      _recentlyPlayed = _videos.where((v) => v.playCount > 0).toList()
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
      final hasPermission = await _ensureStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage/media permission not granted for video import.');
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        var addedCount = 0;
        for (final file in result.files) {
          if (file.path != null) {
            if (await _addVideo(file.path!)) {
              addedCount++;
            }
          }
        }
        debugPrint('Pick videos completed. Added $addedCount items.');
        if (addedCount > 0) {
          await _saveToPrefs();
        }
      }
    } catch (e) {
      debugPrint('Error picking videos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickFolder() async {
    _isLoading = true;
    notifyListeners();

    try {
      final hasPermission = await _ensureStoragePermission();
      if (!hasPermission) {
        debugPrint('Storage/media permission not granted for folder scan.');
        return;
      }

      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final addedCount = await _scanDirectory(result);
        debugPrint(
            'Folder scan completed. Added $addedCount items from: $result');
        if (addedCount > 0) {
          await _saveToPrefs();
        }
      }
    } catch (e) {
      debugPrint('Error picking folder: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> _scanDirectory(String dirPath) async {
    final normalizedPath = _normalizeDirectoryPath(dirPath);
    if (normalizedPath == null) {
      debugPrint('Unsupported folder path: $dirPath');
      return 0;
    }

    final dir = Directory(normalizedPath);
    if (!await dir.exists()) return 0;

    var addedCount = 0;

    final entities =
        dir.list(recursive: true, followLinks: false).handleError((error) {
      debugPrint('Skipping inaccessible entry while scanning: $error');
    });

    await for (final entity in entities) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase().replaceAll('.', '');
        if (supportedExtensions.contains(ext)) {
          if (await _addVideo(entity.path)) {
            addedCount++;
          }
        }
      }
    }

    return addedCount;
  }

  Future<bool> _addVideo(String filePath) async {
    // Check if already added
    if (_videos.any((v) => v.path == filePath)) return false;

    final file = File(filePath);
    if (!await file.exists()) return false;

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
    return true;
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.videos.isGranted ||
        await Permission.storage.isGranted) {
      return true;
    }

    final videosStatus = await Permission.videos.request();
    if (videosStatus.isGranted || videosStatus.isLimited) {
      return true;
    }

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      return true;
    }

    return false;
  }

  String? _normalizeDirectoryPath(String rawPath) {
    if (rawPath.isEmpty) return null;

    if (!rawPath.startsWith('content://')) {
      return rawPath;
    }

    if (!Platform.isAndroid) {
      return null;
    }

    final uri = Uri.tryParse(rawPath);
    if (uri == null) {
      return null;
    }

    if (uri.authority != 'com.android.externalstorage.documents') {
      return null;
    }

    final treeIndex = uri.pathSegments.indexOf('tree');
    if (treeIndex == -1 || treeIndex + 1 >= uri.pathSegments.length) {
      return null;
    }

    final documentId = Uri.decodeComponent(uri.pathSegments[treeIndex + 1]);
    return _androidDocumentIdToPath(documentId);
  }

  String? _androidDocumentIdToPath(String documentId) {
    final separatorIndex = documentId.indexOf(':');
    if (separatorIndex == -1) {
      return null;
    }

    final volume = documentId.substring(0, separatorIndex);
    final relativePath = documentId.substring(separatorIndex + 1);

    if (volume.toLowerCase() == 'primary') {
      if (relativePath.isEmpty) {
        return '/storage/emulated/0';
      }
      return '/storage/emulated/0/$relativePath';
    }

    if (relativePath.isEmpty) {
      return '/storage/$volume';
    }

    return '/storage/$volume/$relativePath';
  }

  void updateWatchProgress(String videoId, Duration position, Duration total,
      {bool forcePersist = false}) {
    final index = _videos.indexWhere((v) => v.id == videoId);
    if (index == -1) return;

    final currentVideo = _videos[index];
    final normalizedPosition = Duration(seconds: position.inSeconds);
    final normalizedDuration =
        total.inMilliseconds > 0 ? total : currentVideo.duration;

    final positionChanged =
        currentVideo.watchPosition.inSeconds != normalizedPosition.inSeconds;
    final durationChanged = currentVideo.duration != normalizedDuration;

    if (!positionChanged && !durationChanged) return;

    _videos[index] = currentVideo.copyWith(
      watchPosition: normalizedPosition,
      duration: normalizedDuration,
    );

    final now = DateTime.now();
    final shouldPersist = forcePersist ||
        _lastProgressPersistAt == null ||
        now.difference(_lastProgressPersistAt!) >= _progressPersistInterval;

    if (shouldPersist) {
      _lastProgressPersistAt = now;
      _saveToPrefs();
    }

    if (forcePersist) {
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

  void removeVideos(List<String> videoIds) {
    if (videoIds.isEmpty) return;

    final ids = videoIds.toSet();
    _videos.removeWhere((v) => ids.contains(v.id));
    _recentlyPlayed.removeWhere((v) => ids.contains(v.id));
    _favorites.removeWhere((v) => ids.contains(v.id));

    if (_currentVideo != null && ids.contains(_currentVideo!.id)) {
      _currentVideo = null;
    }

    _saveToPrefs();
    notifyListeners();
  }

  void removeVideo(String videoId) {
    removeVideos([videoId]);
  }

  void clearAll() {
    _videos.clear();
    _recentlyPlayed.clear();
    _favorites.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
