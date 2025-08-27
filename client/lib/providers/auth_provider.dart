import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  final _storage = const FlutterSecureStorage();

  bool get isAuthenticated => _token != null;
  String? get token => _token;

  Future<void> login(String email, String password) async {
    final url = Uri.parse('$BASE_URL/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _token = responseData['token'];
        await _storage.write(key: 'authToken', value: _token);
        notifyListeners();
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    final url = Uri.parse('$BASE_URL/auth/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to sign up: ${response.body}');
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'authToken');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final storedToken = await _storage.read(key: 'authToken');
    if (storedToken == null) {
      return false;
    }
    _token = storedToken;
    notifyListeners();
    return true;
  }
}
