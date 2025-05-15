import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OfflineService {
  // Singleton implementation
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  // Properties
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _connectivitySubscription;
  bool _isOnline = true;
  final _syncController = StreamController<bool>.broadcast();
  final _pendingSyncItems = <String, Map<String, dynamic>>{};
  final _uuid = Uuid();

  // Stream to listen for sync events
  Stream<bool> get syncStream => _syncController.stream;

  // Initialize the service
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      // If we're back online and were previously offline, sync data
      if (_isOnline && wasOffline) {
        syncPendingData();
      }

      // Notify listeners about connectivity status
      _syncController.add(_isOnline);
    });

    // Load pending sync items from storage
    await _loadPendingSyncItems();
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }

  // Check if device is online
  bool get isOnline => _isOnline;

  // Sync all pending data
  Future<bool> syncPendingData() async {
    if (!_isOnline || _pendingSyncItems.isEmpty) {
      return false;
    }

    try {
      // Here we would typically call Firebase or other backend APIs
      // to sync each pending item based on its type and data

      final itemsToSync = Map<String, Map<String, dynamic>>.from(_pendingSyncItems);
      bool allSuccessful = true;

      for (final entry in itemsToSync.entries) {
        final item = entry.value;
        final type = item['type'] as String;
        final data = item['data'] as Map<String, dynamic>;

        bool success = false;

        // Handle different types of data
        switch (type) {
          case 'workout':
            success = await _syncWorkoutData(data);
            break;
          case 'profile':
            success = await _syncProfileData(data);
            break;
          case 'nutrition':
            success = await _syncNutritionData(data);
            break;
          default:
            success = false;
        }

        if (success) {
          _pendingSyncItems.remove(entry.key);
        } else {
          allSuccessful = false;
        }
      }

      // Save updated pending items list
      await _savePendingSyncItems();

      // Notify listeners
      _syncController.add(_isOnline);

      return allSuccessful;
    } catch (e) {
      debugPrint('Error syncing data: $e');
      return false;
    }
  }

  // Queue data for syncing later when offline
  Future<String> queueDataForSync(String type, Map<String, dynamic> data) async {
    final itemId = _uuid.v4();
    _pendingSyncItems[itemId] = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _savePendingSyncItems();
    return itemId;
  }

  // Save data (try online first, fallback to offline queue)
  Future<bool> saveData(String type, Map<String, dynamic> data) async {
    if (_isOnline) {
      bool success = false;

      // Try to save online
      switch (type) {
        case 'workout':
          success = await _syncWorkoutData(data);
          break;
        case 'profile':
          success = await _syncProfileData(data);
          break;
        case 'nutrition':
          success = await _syncNutritionData(data);
          break;
        default:
          success = false;
      }

      if (success) {
        return true;
      }
    }

    // If online save failed or we're offline, queue for later
    await queueDataForSync(type, data);
    return false;
  }

  // Get count of pending sync items
  int get pendingSyncCount => _pendingSyncItems.length;

  // Implementation of sync methods for different data types
  // These would typically call Firebase or your backend APIs
  Future<bool> _syncWorkoutData(Map<String, dynamic> data) async {
    // Here you would make API calls to save workout data
    // For now we'll simulate success
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }

  Future<bool> _syncProfileData(Map<String, dynamic> data) async {
    // Here you would make API calls to save profile data
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }

  Future<bool> _syncNutritionData(Map<String, dynamic> data) async {
    // Here you would make API calls to save nutrition data
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }

  // Load pending sync items from SharedPreferences
  Future<void> _loadPendingSyncItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('pending_sync_items');

      if (data != null) {
        final decoded = jsonDecode(data) as Map<String, dynamic>;

        _pendingSyncItems.clear();
        decoded.forEach((key, value) {
          _pendingSyncItems[key] = Map<String, dynamic>.from(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading pending sync items: $e');
    }
  }

  // Save pending sync items to SharedPreferences
  Future<void> _savePendingSyncItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_sync_items', jsonEncode(_pendingSyncItems));
    } catch (e) {
      debugPrint('Error saving pending sync items: $e');
    }
  }
}