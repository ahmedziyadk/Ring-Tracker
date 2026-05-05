import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String _role = '';
  bool _isLoading = true;
  String _displayName = '';

  User? get user => _user;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  bool get isOffice => _role == 'office';
  bool get isLoading => _isLoading;
  String get makerName => _displayName;
  String get displayName => _displayName;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _fetchUserRole(user.uid);
    } else {
      _role = '';
      _displayName = '';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        _role = data?['role'] ?? 'maker';
        _displayName = data?['name'] ?? '';
      } else {
        _role = 'maker';
        _displayName = '';
      }
    } catch (e) {
      _role = 'maker';
      _displayName = '';
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}

