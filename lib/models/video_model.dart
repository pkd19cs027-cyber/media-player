import 'dart:io';

class VideoModel {
  final String id;
  final String title;
  final String path;
  final String? thumbnailPath;
  final Duration? duration;
  final int? fileSize;
  final DateTime? dateAdded;
  Duration watchPosition;
  bool isFavorite;
  int playCount;
  String? category;

  VideoModel({
    required this.id,
    required this.title,
    required this.path,
    this.thumbnailPath,
    this.duration,
    this.fileSize,
    this.dateAdded,
    this.watchPosition = Duration.zero,
    this.isFavorite = false,
    this.playCount = 0,
    this.category,
  });

  File get file => File(path);

  bool get exists => file.existsSync();

  String get displayTitle {
    // Clean up filename to look more like a movie title
    String name = title
        .replaceAll(RegExp(r'\.(mp4|mkv|avi|mov|wmv|flv|webm|m4v)$',
            caseSensitive: false), '')
        .replaceAll(RegExp(r'[._\-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Title case
    return name.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String get formattedDuration {
    if (duration == null) return '--:--';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  double get watchProgress {
    if (duration == null || duration!.inMilliseconds == 0) return 0.0;
    return (watchPosition.inMilliseconds / duration!.inMilliseconds).clamp(0.0, 1.0);
  }

  bool get isWatched => watchProgress > 0.9;

  bool get isInProgress => watchProgress > 0.05 && !isWatched;

  String get extension {
    return path.split('.').last.toUpperCase();
  }

  VideoModel copyWith({
    String? id,
    String? title,
    String? path,
    String? thumbnailPath,
    Duration? duration,
    int? fileSize,
    DateTime? dateAdded,
    Duration? watchPosition,
    bool? isFavorite,
    int? playCount,
    String? category,
  }) {
    return VideoModel(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      watchPosition: watchPosition ?? this.watchPosition,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'thumbnailPath': thumbnailPath,
      'durationMs': duration?.inMilliseconds,
      'fileSize': fileSize,
      'dateAdded': dateAdded?.millisecondsSinceEpoch,
      'watchPositionMs': watchPosition.inMilliseconds,
      'isFavorite': isFavorite,
      'playCount': playCount,
      'category': category,
    };
  }

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      fileSize: json['fileSize'] as int?,
      dateAdded: json['dateAdded'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dateAdded'] as int)
          : null,
      watchPosition: Duration(milliseconds: json['watchPositionMs'] ?? 0),
      isFavorite: json['isFavorite'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
      category: json['category'] as String?,
    );
  }
}
