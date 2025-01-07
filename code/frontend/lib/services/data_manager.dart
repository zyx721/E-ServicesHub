import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  bool _isInitialized = false;
  late Box<Map> _usersBox;
  late Box<Map> _currentUserBox;
  late Box<Map> _providersBox;
  
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('📦 DataManager already initialized');
      return;
    }

    debugPrint('📦 Initializing DataManager...');
    await Hive.initFlutter();
    _usersBox = await Hive.openBox<Map>('users_data');
    _currentUserBox = await Hive.openBox<Map>('current_user_data');
    _providersBox = await Hive.openBox<Map>('providers_data');
    _isInitialized = true;
    debugPrint('✅ DataManager initialized successfully');
  }

  Future<void> fetchAndStoreInitialData() async {
    debugPrint('🔄 Starting comprehensive data fetch...');
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('❌ No user logged in, skipping data fetch');
      return;
    }

    try {
      // 1. Fetch and store current user data
      debugPrint('📥 Fetching current user data...');
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (currentUserDoc.exists) {
        await _currentUserBox.put('userData', currentUserDoc.data() as Map);
        debugPrint('✅ Stored current user data');

        // 2. Fetch and store all users from same city
        final userCity = currentUserDoc.data()?['city'];
        if (userCity != null) {
          debugPrint('📥 Fetching users from city: $userCity');
          
          // Fetch regular users
          final cityUsers = await FirebaseFirestore.instance
              .collection('users')
              .where('city', isEqualTo: userCity)
              .where('isProvider', isEqualTo: false)
              .get();

          // Fetch service providers
          final providers = await FirebaseFirestore.instance
              .collection('users')
              .where('city', isEqualTo: userCity)
              .where('isProvider', isEqualTo: true)
              .get();

          // Store users data
          final usersData = <String, Map>{};
          for (var doc in cityUsers.docs) {
            usersData[doc.id] = doc.data();
          }
          await _usersBox.putAll(usersData);
          debugPrint('✅ Stored ${usersData.length} city users');

          // Store providers data
          final providersData = <String, Map>{};
          for (var doc in providers.docs) {
            providersData[doc.id] = doc.data();
          }
          await _providersBox.putAll(providersData);
          debugPrint('✅ Stored ${providersData.length} service providers');
        }
      }
      
      debugPrint('✅ Initial data fetch and storage completed successfully');
    } catch (e) {
      debugPrint('❌ Error during initial data fetch: $e');
      throw e; // Rethrow to handle in login screen
    }
  }

  Map? getCurrentUserData() {
    if (!_isInitialized) {
      debugPrint('❌ DataManager not initialized');
      return null;
    }
    return _currentUserBox.get('userData');
  }

  List<Map<String, dynamic>> getCityUsers() {
    if (!_isInitialized) {
      debugPrint('❌ DataManager not initialized');
      return [];
    }
    return _usersBox.values.map((data) => Map<String, dynamic>.from(data)).toList();
  }

  List<Map<String, dynamic>> getServiceProviders() {
    if (!_isInitialized) {
      debugPrint('❌ DataManager not initialized');
      return [];
    }
    return _providersBox.values.map((data) => Map<String, dynamic>.from(data)).toList();
  }

  Future<void> updateLocalUserData(String userId, Map<String, dynamic> updates) async {
    if (!_isInitialized) return;
    
    if (userId == FirebaseAuth.instance.currentUser?.uid) {
      var userData = getCurrentUserData();
      if (userData != null) {
        userData.addAll(updates);
        await _currentUserBox.put('userData', userData);
      }
    }
    
    // Update in providers or users box as needed
    if (_providersBox.containsKey(userId)) {
      var data = _providersBox.get(userId);
      data?.addAll(updates);
      await _providersBox.put(userId, data!);
    } else if (_usersBox.containsKey(userId)) {
      var data = _usersBox.get(userId);
      data?.addAll(updates);
      await _usersBox.put(userId, data!);
    }
  }

  Future<void> clearData() async {
    await _usersBox.clear();
    await _currentUserBox.clear();
    await _providersBox.clear();
    debugPrint('🧹 Cleared all cached data');
  }
}
