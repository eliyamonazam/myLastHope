class Song {
  final String id;
  final String songName;
  final String artist;
  final String thumbnailUrl;
  final String songUrl;
  bool isFavorited; // <-- این فیلد جدید اضافه شده است

  Song({
    required this.id,
    required this.songName,
    required this.artist,
    required this.thumbnailUrl,
    required this.songUrl,
    this.isFavorited = false, // مقدار اولیه false است
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      songName: json['songName'],
      artist: json['artist'],
      thumbnailUrl: json['thumbnailUrl'],
      songUrl: json['songUrl'],
    );
  }
}
