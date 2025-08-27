import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../models/favorite_model.dart';
import '../providers/auth_provider.dart';
import '../models/song_model.dart';
import '../utils/constants.dart';
import '../services/download_service.dart'; // <-- Make sure this import is here
import './upload_song_screen.dart';
import './now_playing_screen.dart';
import './profile_screen.dart';

// Enum for search type
enum SearchType { songName, artist }

class SongListScreen extends StatefulWidget {
  const SongListScreen({super.key});
  @override
  _SongListScreenState createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  List<Song>? _songs;
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  SearchType _searchType = SearchType.songName;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchAllSongs();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_searchController.text.trim().isEmpty) {
        _fetchAllSongs();
      } else {
        _performSearch(_searchController.text.trim());
      }
    });
  }

  Future<void> _fetchData({required Uri url}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final headers = {'Authorization': 'Bearer $token'};

    try {
      final songsResponse = await http.get(url, headers: headers);
      if (songsResponse.statusCode != 200)
        throw Exception('Failed to load songs');

      final favoritesResponse = await http
          .get(Uri.parse('$BASE_URL/song/list/favorites'), headers: headers);
      if (favoritesResponse.statusCode != 200)
        throw Exception('Failed to load favorites');

      final List<dynamic> songsData = json.decode(songsResponse.body);
      final List<dynamic> favoritesData = json.decode(favoritesResponse.body);

      final List<Song> fetchedSongs =
          songsData.map((data) => Song.fromJson(data)).toList();
      final Set<String> favoriteSongIds =
          favoritesData.map((data) => Favorite.fromJson(data).song.id).toSet();

      for (var song in fetchedSongs) {
        song.isFavorited = favoriteSongIds.contains(song.id);
      }

      if (mounted) {
        setState(() {
          _songs = fetchedSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAllSongs() async {
    await _fetchData(url: Uri.parse('$BASE_URL/song/list'));
  }

  Future<void> _performSearch(String query) async {
    final searchTypeString =
        _searchType == SearchType.artist ? 'artist' : 'songName';
    final url =
        Uri.parse('$BASE_URL/song/search?query=$query&type=$searchTypeString');
    await _fetchData(url: url);
  }

  Future<void> _toggleFavorite(Song song) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final url = Uri.parse('$BASE_URL/song/favorite');

    if (!mounted) return;
    setState(() {
      song.isFavorited = !song.isFavorited;
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'songId': song.id}),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            song.isFavorited = !song.isFavorited;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Could not update favorite status.')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          song.isFavorited = !song.isFavorited;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
              )
                  .then((_) {
                _fetchAllSongs();
              });
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (ctx) => const UploadSongScreen()),
          );
          if (result == true) {
            _fetchAllSongs();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Songs',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchAllSongs();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: [
                    _searchType == SearchType.songName,
                    _searchType == SearchType.artist
                  ],
                  onPressed: (index) {
                    setState(() {
                      _searchType =
                          index == 0 ? SearchType.songName : SearchType.artist;
                    });
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Song Name')),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Artist')),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error: $_error', textAlign: TextAlign.center),
        ),
      );
    }
    if (_songs == null || _songs!.isEmpty) {
      return Center(
        child: Text(_searchController.text.isEmpty
            ? 'No songs found.'
            : 'No results for "${_searchController.text}"'),
      );
    }

    return ListView.builder(
      itemCount: _songs!.length,
      itemBuilder: (ctx, index) {
        final song = _songs![index];
        return ListTile(
          leading: Image.network(
            song.thumbnailUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.music_note),
          ),
          title: Text(song.songName),
          subtitle: Text(song.artist),
          // --- THIS IS THE CORRECTED PART ---
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  song.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorited ? Colors.red : Colors.grey,
                ),
                onPressed: () => _toggleFavorite(song),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Download',
                onPressed: () {
                  DownloadService().downloadSong(
                    context,
                    url: song.songUrl,
                    fileName: '${song.artist} - ${song.songName}',
                  );
                },
              ),
            ],
          ),
          onTap: () {
            _audioPlayer.stop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => NowPlayingScreen(
                  song: song,
                  audioPlayer: _audioPlayer,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
