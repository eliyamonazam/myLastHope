import './song_model.dart';

class Favorite {
  final String id;
  final Song song;

  Favorite({
    required this.id,
    required this.song,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      song: Song.fromJson(json['song']),
    );
  }
}
