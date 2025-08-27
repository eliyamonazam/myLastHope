import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/favorite_model.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _fetchProfileData();
  }

  Future<Map<String, dynamic>> _fetchProfileData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final headers = {'Authorization': 'Bearer $token'};

    try {
      // Fetch user data and favorites in parallel
      final userResponseFuture =
          http.get(Uri.parse('$BASE_URL/auth/me'), headers: headers);
      final favoritesResponseFuture = http
          .get(Uri.parse('$BASE_URL/song/list/favorites'), headers: headers);

      final responses =
          await Future.wait([userResponseFuture, favoritesResponseFuture]);

      // Process user data
      if (responses[0].statusCode != 200)
        throw Exception('Failed to load user data');
      final userData = User.fromJson(json.decode(responses[0].body));

      // Process favorites data
      if (responses[1].statusCode != 200)
        throw Exception('Failed to load favorites');
      final List<dynamic> favoritesData = json.decode(responses[1].body);
      final favorites =
          favoritesData.map((data) => Favorite.fromJson(data)).toList();

      return {'user': userData, 'favorites': favorites};
    } catch (error) {
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).logout();
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found.'));
          }

          final User user = snapshot.data!['user'];
          final List<Favorite> favorites = snapshot.data!['favorites'];

          return Column(
            children: [
              // User Info Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.deepPurple,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(user.email,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.grey)),
                  ],
                ),
              ),
              const Divider(),
              // Favorites List
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Text('Favorite Songs',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: favorites.isEmpty
                    ? const Center(
                        child: Text('You have no favorite songs yet.'))
                    : ListView.builder(
                        itemCount: favorites.length,
                        itemBuilder: (ctx, index) {
                          final favoriteSong = favorites[index].song;
                          return ListTile(
                            leading: Image.network(favoriteSong.thumbnailUrl,
                                width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(favoriteSong.songName),
                            subtitle: Text(favoriteSong.artist),
                          );
                        },
                      ),
              ),
              // Logout Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    // Navigate back to the auth screen after logout
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
              Container(width: 30 ,height: 30,),
            ],
          );
        },
      ),
    );
  }
}
