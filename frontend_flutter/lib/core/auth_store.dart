import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthStore extends ChangeNotifier {
  final ApiClient api;
  User? user;
  String? token;

  AuthStore({required this.api});

  bool get isLoggedIn => token != null;
  bool get isAdmin => user?.role == 'admin';
  bool get isCustomer => user?.role == 'customer';

  Future<bool> login(String email, String password) async {
    final res = await api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    if (res['success'] == true) {
      final data = res['data'];
      token = data['token'];
      user = User.fromJson(data['user']);
      api.setToken(token);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    user = null;
    token = null;
    api.setToken(null);
    notifyListeners();
  }
}
