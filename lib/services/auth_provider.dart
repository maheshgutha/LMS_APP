import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? avatar;
  final bool isApproved;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatar,
    this.isApproved = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      name: profile?['full_name'] ?? json['name'] ?? json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatar: profile?['avatar_url'],
      isApproved: json['is_approved'] ?? false,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _loading = false;
  String? _error;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? get user => _user;
  bool get loading => _loading;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isLoggedIn => _user != null;
  String get role => _user?.role ?? '';

  bool get isAdmin => role == AppConstants.roleAdmin || role == AppConstants.roleSuperAdmin;
  bool get isManager => role == AppConstants.roleManager;
  bool get isInstructor => role == AppConstants.roleInstructor;
  bool get isStudent => role == AppConstants.roleStudent;
  bool get isIntern => role == AppConstants.roleIntern;

  Future<void> tryAutoLogin() async {
    final userData = await _storage.read(key: 'user_data');
    final token = await _storage.read(key: 'auth_token');
    if (userData != null && token != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userData));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<bool> sendOtp(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await ApiService.post(AppConstants.sendOtpEndpoint, {'email': email}, auth: false);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post(AppConstants.loginEndpoint, {
        'email': email,
        'password': otp,
      }, auth: false);

      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        final userJson = res['user'] ?? res;
        _user = UserModel.fromJson(userJson);
        await _storage.write(key: 'user_data', value: jsonEncode(userJson));
        _loading = false;
        notifyListeners();
        return true;
      }
      // OTP flow
      if (res['message'] != null) {
        _loading = false;
        notifyListeners();
        return true;
      }
      throw Exception('Login failed');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiService.post(AppConstants.verifyOtpEndpoint, {
        'email': email,
        'otp': otp,
      }, auth: false);

      if (res['token'] != null) {
        await ApiService.saveToken(res['token']);
        final userJson = res['user'] ?? res;
        _user = UserModel.fromJson(userJson);
        await _storage.write(key: 'user_data', value: jsonEncode(userJson));
        _loading = false;
        notifyListeners();
        return true;
      }
      throw Exception('OTP verification failed');
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.post(AppConstants.logoutEndpoint, {});
    } catch (_) {}
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.get(AppConstants.profileEndpoint);
      if (res != null) {
        final userJson = res['user'] ?? res;
        _user = UserModel.fromJson(userJson);
        await _storage.write(key: 'user_data', value: jsonEncode(userJson));
        notifyListeners();
      }
    } catch (_) {}
  }
}
