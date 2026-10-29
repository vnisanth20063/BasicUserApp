import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

/// Custom Exception class for descriptive API error reporting
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Service handling all HTTP REST API communication with the Node.js backend
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final uri = Uri.parse(ApiConfig.healthUrl);
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve all registered users from GET /api/users
  Future<List<UserModel>> fetchUsers() async {
    try {
      final uri = Uri.parse(ApiConfig.usersUrl);
      final response = await _client
          .get(uri)
          .timeout(ApiConfig.timeoutDuration);

      final Map<String, dynamic> body = _decodeResponse(response);

      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> usersJson = body['data'] as List<dynamic>? ?? [];
        return usersJson
            .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        final errorMsg = body['message'] ?? 'Failed to load users from server.';
        throw ApiException(errorMsg, response.statusCode);
      }
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at ${ApiConfig.baseUrl}.\n'
        '• Ensure the Node.js server is running.\n'
        '• If using a physical phone, ensure phone and PC are on the same Wi-Fi and use your PC\'s LAN IP.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out while contacting ${ApiConfig.baseUrl}. Please check your network connection.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException {
      throw ApiException('Received an invalid response format from the server.');
    }
  }

  /// Register a new user via POST /api/users
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.usersUrl);
      final payload = jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
      });

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: payload,
          )
          .timeout(ApiConfig.timeoutDuration);

      final Map<String, dynamic> body = _decodeResponse(response);

      if (response.statusCode == 201 && body['success'] == true) {
        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      } else {
        final errorMsg = body['message'] ??
            'Registration failed with status ${response.statusCode}.';
        throw ApiException(errorMsg, response.statusCode);
      }
    } on SocketException {
      throw ApiException(
        'Cannot connect to backend at ${ApiConfig.baseUrl}.\n'
        '• Ensure the Node.js server is running.\n'
        '• If using a physical phone, ensure phone and PC are on the same Wi-Fi and use your PC\'s LAN IP.',
      );
    } on TimeoutException {
      throw ApiException(
        'Connection timed out while contacting ${ApiConfig.baseUrl}. Please check your network connection.',
      );
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on FormatException {
      throw ApiException('Received an invalid response format from the server.');
    }
  }

  /// Safely decode response body into JSON
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': false,
        'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? "Error"}',
        'data': null,
      };
    }
  }
}

