import 'dart:async';
import 'package:flutter/foundation.dart';

/// Provider Cache Manager
/// Phase 4 Optimization - State Management
/// 
/// Manages cross-provider caching to reduce redundant API calls
/// and improve state sharing between providers
class ProviderCache {
  static final ProviderCache _instance = ProviderCache._internal();
  factory ProviderCache() => _instance;
  ProviderCache._internal();
  
  // Cache storage
  final Map<String, CacheEntry> _cache = {};
  
  // Cache configuration
  Duration defaultCacheDuration = const Duration(minutes: 5);
  
  /// Get cached value
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    
    // Check if expired
    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return entry.value as T?;
  }
  
  /// Set cache value
  void set<T>(String key, T value, {Duration? duration}) {
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(duration ?? defaultCacheDuration),
    );
  }
  
  /// Check if key exists and is valid
  bool contains(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      _cache.remove(key);
      return false;
    }
    return true;
  }
  
  /// Invalidate cache entry
  void invalidate(String key) {
    _cache.remove(key);
  }
  
  /// Invalidate cache by pattern
  void invalidatePattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }
  
  /// Clear all cache
  void clear() {
    _cache.clear();
  }
  
  /// Get cache statistics
  CacheStats getStats() {
    final now = DateTime.now();
    int valid = 0;
    int expired = 0;
    
    for (var entry in _cache.values) {
      if (entry.isExpired) {
        expired++;
      } else {
        valid++;
      }
    }
    
    return CacheStats(
      totalEntries: _cache.length,
      validEntries: valid,
      expiredEntries: expired,
    );
  }
  
  /// Clean expired entries
  void cleanExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }
}

/// Cache entry
class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;
  
  CacheEntry({
    required this.value,
    required this.expiresAt,
  });
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Cache statistics
class CacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  
  CacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
  });
  
  double get hitRate => totalEntries > 0 ? validEntries / totalEntries : 0.0;
}

/// Cache keys constants
class CacheKeys {
  // Employee cache
  static const String employees = 'employees';
  static String employee(int id) => 'employee_$id';
  static String employeeByEmployeeId(String employeeId) => 'employee_eid_$employeeId';
  
  // Site cache
  static const String sites = 'sites';
  static String site(int id) => 'site_$id';
  
  // Holiday cache
  static const String holidays = 'holidays';
  static String holiday(int id) => 'holiday_$id';
  
  // Dashboard cache
  static String dashboard(String employeeId) => 'dashboard_$employeeId';
  
  // Attendance cache
  static String attendance(String employeeId, String date) => 'attendance_${employeeId}_$date';
  static String attendanceRange(String employeeId, String startDate, String endDate) => 
      'attendance_${employeeId}_${startDate}_$endDate';
  
  // Task cache
  static const String tasks = 'tasks';
  static String task(int id) => 'task_$id';
  static String employeeTasks(String employeeId) => 'tasks_employee_$employeeId';
  
  // Leave cache
  static String leaves(String employeeId) => 'leaves_$employeeId';
  static String leave(int id) => 'leave_$id';
}

