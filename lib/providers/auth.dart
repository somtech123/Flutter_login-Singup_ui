import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/http_execption.dart';

class Auth with ChangeNotifier {
  String? _token;
  String? _userId;
  DateTime? _expryDate;
  Timer? _authTimer;

  bool get isAuth {
    return token != null;
  }

  String? get token {
    if (_expryDate != null &&
        _expryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=[API_KEY]');
    try {
      final response = await http.post(
        url,
        body: json.encode(
            {'email': email, 'password': password, 'returnSecureToken': true}),
      );
      final responseData = json.decode(response.body);
      print(responseData);
      if (responseData['error'] != null) {
        throw HttpExecption(responseData['error']['message']);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expryDate = DateTime.now()
          .add(Duration(seconds: int.parse(responseData['expiresIn'])));
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        'token': _token,
        'userId': _userId,
        'expiryDate': _expryDate!.toIso8601String()
      });
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<void> singup(String email, String password) async {
    return _authenticate(email, password, 'signUp');
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extratedUserData =
        json.decode(prefs.getString('userData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extratedUserData['expiryDate'] as String);
    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extratedUserData['token'];
    _userId = extratedUserData['userId'];
    _expryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = '';
    _userId = '';
    _expryDate = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
