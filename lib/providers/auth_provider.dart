import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/rbac.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../services/data_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _api.onUnauthorized = () => unawaited(logout());
    _initFuture = _init();
  }

  final ApiClient _api = ApiClient();
  late final DataService dataService = DataService(_api);
  late final Future<void> _initFuture;

  User? _user;
  String? _token;
  bool _initialized = false;
  String? _error;

  User? get user => _user;
  String? get token => _token;
  bool get isInitialized => _initialized;
  bool get isAuthenticated => _user != null && _token != null;
  String? get error => _error;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userRole = prefs.getString('user_role');

      if (_token != null && userEmail != null && userRole != null) {
        _api.setToken(_token);
        _user = User(
          id: userId ?? 0,
          name: userName ?? '',
          email: userEmail,
          role: _roleFromString(userRole),
        );
      }
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    await _initFuture;
    _error = null;

    try {
      final response = await dataService.login(email, password);
      _token = response.token;
      _user = response.user;
      _api.setToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response.token);
      await prefs.setString('refresh_token', response.refreshToken);
      await prefs.setInt('user_id', response.user.id);
      await prefs.setString('user_name', response.user.name);
      await prefs.setString('user_email', response.user.email);
      await prefs.setString('user_role', response.user.role.name);

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _initFuture;
    _user = null;
    _token = null;
    _api.setToken(null);
    dataService.clearCache();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  UserRole _roleFromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'kasir':
        return UserRole.kasir;
      case 'staff_produksi':
      case 'staffProduksi':
        return UserRole.staffProduksi;
      default:
        return UserRole.kasir;
    }
  }
}
