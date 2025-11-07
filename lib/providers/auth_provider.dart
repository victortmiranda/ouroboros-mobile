import 'package:flutter/material.dart';

class User {
  final String name;
  final String password;

  User({required this.name, required this.password});
}

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  User? _currentUser;
  final List<User> _users = []; // Lista para armazenar usuários registrados

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;

  Future<bool> register(String name, String password) async {
    // Verifica se o usuário já existe
    if (_users.any((user) => user.name == name)) {
      return false; // Usuário já registrado
    }

    // Adiciona o novo usuário
    _users.add(User(name: name, password: password));
    notifyListeners();
    return true;
  }

  Future<bool> login(String name, String password) async {
    // Simula uma chamada de rede
    await Future.delayed(const Duration(seconds: 1));

    try {
      final user = _users.firstWhere((user) => user.name == name && user.password == password);
      _isLoggedIn = true;
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (e) {
      return false; // Usuário não encontrado
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();
  }
}
