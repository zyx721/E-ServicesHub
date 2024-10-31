// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://192.168.85.163:5000/api/auth'; // Replace with your backend URL

  // Sign-Up Function
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'User created successfully'};
    } else {
      return {'success': false, 'message': jsonDecode(response.body)['msg']};
    }
  }

  // Login Function
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'token': data['token']};
    } else {
      return {'success': false, 'message': jsonDecode(response.body)['msg']};
    }
  }
}
