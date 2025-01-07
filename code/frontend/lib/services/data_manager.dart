import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  SharedPreferences? _prefsInstance;
  bool _initialized = false;
  
  factory DataManager() => _instance;
  
  DataManager._internal();

  Future<void> initialize() async {
    if (!_initialized) {
      _prefsInstance = await SharedPreferences.getInstance();
      _initialized = true;
    }
  }

  dynamic _sanitizeObject(dynamic obj) {
    if (obj is Timestamp) {
      return obj.toDate().toIso8601String();
    } else if (obj is DateTime) {
      return obj.toIso8601String();
    } else if (obj is Map) {
      return _sanitizeMap(obj);
    } else if (obj is List) {
      return obj.map((e) => _sanitizeObject(e)).toList();
    }
    return obj;
  }

  Map<String, dynamic> _sanitizeMap(Map<dynamic, dynamic> map) {
    Map<String, dynamic> sanitized = {};
    map.forEach((key, value) {
      if (key is String) {
        sanitized[key] = _sanitizeObject(value);
      }
    });
    return sanitized;
  }

  Future<void> fetchAndCacheAllData(String userId) async {
    try {
      await initialize();
      
      debugPrint('🔍 Fetching data for user: $userId');
      
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        debugPrint('❌ User document does not exist');
        return;
      }
      
      // Sanitize user data before storing
      final userData = _sanitizeMap(userDoc.data()!);
      
      // Ensure basic info exists
      if (userData['basicInfo'] == null) {
        userData['basicInfo'] = {};
      }
      
      String? userCity = userData['city'];
      
      // If city is not set, try to get it from their info
      if (userCity == null || userCity.isEmpty) {
        userCity = userData['basicInfo']?['city'] ?? userData['location']?['city'];
        if (userCity != null && userCity.isNotEmpty) {
          // Update the main city field if we found it in a nested location
          userData['city'] = userCity;
        }
        debugPrint('🏙️ Found city from alternate location: $userCity');
      }
      
      if (userCity == null || userCity.isEmpty) {
        debugPrint('⚠️ No city information found for user');
        return;
      }
      
      debugPrint('🌆 Fetching users from city: $userCity');
      
      final usersInCity = await FirebaseFirestore.instance
          .collection('users')
          .where('city', isEqualTo: userCity)
          .get();
      
      final providers = <Map<String, dynamic>>[];
      final allUsers = <Map<String, dynamic>>[];
      
      for (var doc in usersInCity.docs) {
        // Sanitize each user's data
        final sanitizedData = _sanitizeMap(doc.data());
        final userMap = {
          'uid': doc.id,
          ...sanitizedData,
        };
        
        allUsers.add(userMap);
        if (sanitizedData['isProvider'] == true) {
          providers.add(userMap);
        }
      }
      
      debugPrint('📦 Caching ${providers.length} providers and ${allUsers.length} total users');
      
      // Cache sanitized data
      await _prefsInstance?.setString('current_user_$userId', jsonEncode(userData));
      await _prefsInstance?.setString('providers_$userId', jsonEncode(providers));
      await _prefsInstance?.setString('city_users_$userId', jsonEncode(allUsers));
      await _prefsInstance?.setString('last_fetch_$userId', DateTime.now().toIso8601String());
      await _prefsInstance?.setString('active_user_id', userId);
      
      debugPrint('✅ All data cached successfully for user: $userId');
    } catch (e, stackTrace) {
      debugPrint('❌ Error caching data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Map<String, dynamic>? getCurrentUserData() {
    try {
      final activeUserId = _prefsInstance?.getString('active_user_id');
      if (activeUserId == null) return null;
      
      final userDataString = _prefsInstance?.getString('current_user_$activeUserId');
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting cached user data: $e');
      return null;
    }
  }

  List<Map<String, dynamic>> getCityUsers() {
    try {
      final activeUserId = _prefsInstance?.getString('active_user_id');
      if (activeUserId == null) return [];
      
      final usersString = _prefsInstance?.getString('city_users_$activeUserId');
      if (usersString != null) {
        final List<dynamic> decoded = jsonDecode(usersString);
        return decoded.cast<Map<String, dynamic>>();
      }
      debugPrint('⚠️ No cached city users found');
      return [];
    } catch (e) {
      debugPrint('❌ Error getting cached city users: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> getCachedProviders() {
    try {
      final activeUserId = _prefsInstance?.getString('active_user_id');
      if (activeUserId == null) return [];
      
      final providersString = _prefsInstance?.getString('providers_$activeUserId');
      if (providersString != null) {
        final List<dynamic> decoded = jsonDecode(providersString);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting cached providers: $e');
      return [];
    }
  }

  Future<void> clearCache() async {
    final activeUserId = _prefsInstance?.getString('active_user_id');
    if (activeUserId != null) {
      await _prefsInstance?.remove('current_user_$activeUserId');
      await _prefsInstance?.remove('providers_$activeUserId');
      await _prefsInstance?.remove('city_users_$activeUserId');
      await _prefsInstance?.remove('last_fetch_$activeUserId');
      await _prefsInstance?.remove('active_user_id');
    }
  }

  Future<void> reloadCache() async {
    final currentUser = await getCurrentUserData();
    if (currentUser != null) {
      await fetchAndCacheAllData(currentUser['uid']);
    }
  }

  // Add other necessary methods...
}
