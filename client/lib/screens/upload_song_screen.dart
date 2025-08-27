import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _songFile;
  File? _thumbnailFile;
  String _songName = '';
  String _artist = '';
  String _hexCode = 'FFFFFF'; // Default color
  bool _isLoading = false;

  Future<void> _pickSong() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        _songFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickThumbnail() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _thumbnailFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadSong() async {
    if (_songFile == null || _thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a song and a thumbnail.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$BASE_URL/song/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['song_name'] = _songName;
      request.fields['artist'] = _artist;
      request.fields['hex_code'] = _hexCode;
      request.files
          .add(await http.MultipartFile.fromPath('song', _songFile!.path));
      request.files.add(
          await http.MultipartFile.fromPath('thumbnail', _thumbnailFile!.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song uploaded successfully!')),
        );
        Navigator.of(context).pop(true); // Go back and indicate success
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(
            'Failed to upload song: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload New Song')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Song Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _songName = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Artist Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an artist' : null,
                onSaved: (value) => _artist = value!,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickSong,
                    icon: const Icon(Icons.music_note),
                    label: const Text('Pick Song'),
                  ),
                  if (_songFile != null)
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickThumbnail,
                    icon: const Icon(Icons.image),
                    label: const Text('Pick Thumbnail'),
                  ),
                  if (_thumbnailFile != null)
                    const Icon(Icons.check, color: Colors.green),
                ],
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _uploadSong,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Upload'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
