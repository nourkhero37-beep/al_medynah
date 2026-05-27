class LiveTvChannel {
  final int id;
  final String name;
  final String url;

  const LiveTvChannel({
    required this.id,
    required this.name,
    required this.url,
  });

  factory LiveTvChannel.fromJson(Map<String, dynamic> json) {
    return LiveTvChannel(
      id: json['id'] as int,
      name: json['name'] as String,
      url: json['url'] as String,
    );
  }
}

class VideoType {
  final int id;
  final String name;

  const VideoType({required this.id, required this.name});

  factory VideoType.fromJson(Map<String, dynamic> json) {
    return VideoType(id: json['id'] as int, name: json['video_type'] as String);
  }
}

class VideoItem {
  final int id;
  final int videoType;
  final String videoUrl;
  final String thumbnailUrl;

  const VideoItem({
    required this.id,
    required this.videoType,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'] as int,
      videoType: json['video_type'] as int,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['video_thumb_url'] as String,
    );
  }
}

class ReciterVideos {
  final int id;
  final String reciterName;
  final List<VideoItem> videos;

  const ReciterVideos({
    required this.id,
    required this.reciterName,
    required this.videos,
  });

  factory ReciterVideos.fromJson(Map<String, dynamic> json) {
    return ReciterVideos(
      id: json['id'] as int,
      reciterName: json['reciter_name'] as String,
      videos: (json['videos'] as List<dynamic>)
          .map((v) => VideoItem.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}
