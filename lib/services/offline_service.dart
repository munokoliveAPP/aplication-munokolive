/* Copyright © 2024 Munokolive Music. Conçu et Développé par Christian Anisonok. Tous droits réservés. */
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/event_model.dart';
import '../models/location_model.dart';
import '../models/user_profile.dart';

class OfflineService {
  final Connectivity _connectivity = Connectivity();

  // Hive Box Names
  static const String _eventsBoxName = 'events_cache';
  static const String _locationsBoxName = 'locations_cache';
  static const String _usersBoxName = 'users_cache';

  // Initialization
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_eventsBoxName);
    await Hive.openBox(_locationsBoxName);
    await Hive.openBox(_usersBoxName);
  }

  // Connectivity
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  Stream<bool> get connectivityStream {
    return _connectivity.onConnectivityChanged.map(_isConnected);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return !results.contains(ConnectivityResult.none);
  }

  // --- CURRENT USER CACHE ---
  static const String _currentUserKey = 'current_user_profile';

  Future<void> saveCurrentUserProfile(UserProfile profile) async {
    final box = Hive.box(_usersBoxName);
    await box.put(_currentUserKey, profile.toJson());
  }

  UserProfile? getCurrentUserProfile() {
    final box = Hive.box(_usersBoxName);
    final data = box.get(_currentUserKey);
    if (data == null) return null;

    try {
      final jsonMap = Map<String, dynamic>.from(data as Map);
      return UserProfile.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  // --- EVENTS CACHE ---
  List<EventModel> getEvents() {
    final box = Hive.box(_eventsBoxName);
    if (box.isEmpty) return [];

    // Sort by eventDate logic if needed, but UI usually sorts.
    // We just return raw cached list.
    return box.values.map((e) {
      // Hive stores Map<dynamic, dynamic>, need to cast to Map<String, dynamic>
      final jsonMap = Map<String, dynamic>.from(e as Map);
      return EventModel.fromJson(jsonMap);
    }).toList();
  }

  Future<void> saveEvents(List<EventModel> events) async {
    final box = Hive.box(_eventsBoxName);
    await box.clear(); // Replace cache strategy
    final Map<String, Map<String, dynamic>> data = {
      for (var e in events) e.id: e.toJson(),
    };
    await box.putAll(data);
  }

  // --- LOCATIONS CACHE ---
  List<LocationModel> getLocations() {
    final box = Hive.box(_locationsBoxName);
    if (box.isEmpty) return [];
    return box.values.map((e) {
      final jsonMap = Map<String, dynamic>.from(e as Map);
      return LocationModel.fromJson(jsonMap);
    }).toList();
  }

  Future<void> saveLocations(List<LocationModel> locations) async {
    final box = Hive.box(_locationsBoxName);
    await box.clear();
    final Map<String, Map<String, dynamic>> data = {
      for (var l in locations) l.id: l.toJson(),
    };
    await box.putAll(data);
  }

  // --- USERS/MEMBERS CACHE ---
  List<UserProfile> getUsers() {
    final box = Hive.box(_usersBoxName);
    if (box.isEmpty) return [];
    return box.values.map((e) {
      final jsonMap = Map<String, dynamic>.from(e as Map);
      return UserProfile.fromJson(jsonMap);
    }).toList();
  }

  Future<void> saveUsers(List<UserProfile> users) async {
    final box = Hive.box(_usersBoxName);
    await box.clear();
    final Map<String, Map<String, dynamic>> data = {
      for (var u in users) u.id: u.toJson(),
    };
    await box.putAll(data);
  }
}
