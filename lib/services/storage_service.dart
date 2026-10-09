import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class StorageService extends GetxService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<StorageService> init() async {
    return this;
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'token_saved_at', value: DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('StorageService: Failed to save token: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final savedAtStr = await _storage.read(key: 'token_saved_at');
      if (token != null && savedAtStr != null) {
        final savedAt = DateTime.tryParse(savedAtStr);
        if (savedAt != null) {
          final difference = DateTime.now().difference(savedAt);
          if (difference.inDays >= 7) {
            // Token expired after 7 days
            await removeToken();
            return null;
          }
        }
      }
      return token;
    } catch (e) {
      debugPrint('StorageService: Failed to read token: $e');
      return null;
    }
  }

  Future<void> removeToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'token_saved_at');
    } catch (e) {
      debugPrint('StorageService: Failed to remove token: $e');
    }
  }

  Future<void> saveUserData(String data) async {
    try {
      await _storage.write(key: 'user_data', value: data);
    } catch (e) {
      debugPrint('StorageService: Failed to save user data: $e');
    }
  }

  Future<void> saveUserName(String name) async {
    try {
      await _storage.write(key: 'user_name', value: name);
    } catch (e) {
      debugPrint('StorageService: Failed to save username: $e');
    }
  }

  Future<String?> getUserName() async {
    try {
      return await _storage.read(key: 'user_name');
    } catch (e) {
      debugPrint('StorageService: Failed to read username: $e');
      return null;
    }
  }

  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: 'user_data');
    } catch (e) {
      debugPrint('StorageService: Failed to read user data: $e');
      return null;
    }
  }

  Future<void> saveVendorId(int id) async {
    try {
      await _storage.write(key: 'vendor_id', value: id.toString());
    } catch (e) {
      debugPrint('StorageService: Failed to save vendor id: $e');
    }
  }

  Future<int?> getVendorId() async {
    try {
      final idStr = await _storage.read(key: 'vendor_id');
      return idStr != null ? int.tryParse(idStr) : null;
    } catch (e) {
      debugPrint('StorageService: Failed to read vendor id: $e');
      return null;
    }
  }
  
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('StorageService: Failed to clear all: $e');
    }
  }
}
