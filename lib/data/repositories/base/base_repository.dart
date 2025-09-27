import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class BaseRepository<T> {
  final String tag;
  final Box _box;

  // Cache management
  List<T>? _cachedItems;
  DateTime? _lastCacheUpdate;
  static const Duration cacheDuration = Duration(minutes: 5);
  static const Duration quickCacheDuration = Duration(seconds: 10);

  BaseRepository({required String boxName, required this.tag})
    : _box = Hive.box(boxName);

  // Abstract methods to implement
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getId(T item);
  bool isDeleted(T item);

  // Cache management
  void invalidateCache() {
    _cachedItems = null;
    _lastCacheUpdate = null;
    DebugLogger.verbose('Cache invalidated', tag: tag);
  }

  bool isCacheValid() {
    if (_cachedItems == null || _lastCacheUpdate == null) return false;

    // Check if cache was force invalidated
    try {
      final settingsBox = Hive.box(AppConstants.settingsBox);
      final forceInvalidation = settingsBox.get('_force_cache_invalidation');
      if (forceInvalidation != null) {
        final invalidationTime = DateTime.fromMillisecondsSinceEpoch(
          forceInvalidation,
        );
        if (invalidationTime.isAfter(_lastCacheUpdate!)) {
          DebugLogger.info('Cache invalidated by background action', tag: tag);
          settingsBox.delete('_force_cache_invalidation'); // Clear flag
          return false;
        }
      }
    } catch (e) {
      // Ignore error, continue with normal cache validation
    }

    final age = DateTime.now().difference(_lastCacheUpdate!);
    return age < cacheDuration;
  }

  void updateCache(List<T> items) {
    _cachedItems = items;
    _lastCacheUpdate = DateTime.now();
  }

  // Smart cache validation based on operation type
  bool isCacheValidForOperation(String operationType) {
    if (_cachedItems == null || _lastCacheUpdate == null) return false;

    final age = DateTime.now().difference(_lastCacheUpdate!);

    // Use different durations for different operations
    switch (operationType) {
      case 'read':
      case 'filter':
      case 'search':
        return age < cacheDuration; // 5 minutes for read operations
      case 'write':
      case 'update':
      case 'delete':
        return age < quickCacheDuration; // 10 seconds after write operations
      default:
        return age < cacheDuration;
    }
  }

  // Type conversion helpers
  dynamic convertValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), convertValue(v))),
      );
    } else if (value is List) {
      return value.map(convertValue).toList();
    }
    return value;
  }

  Map<String, dynamic> convertToTypedMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;

    if (data is Map) {
      try {
        final converted = <String, dynamic>{};
        data.forEach((key, value) {
          converted[key.toString()] = convertValue(value);
        });
        return converted;
      } catch (e) {
        DebugLogger.error('Map conversion failed', tag: tag, error: e);
        rethrow;
      }
    }

    throw Exception(
      'Cannot convert ${data.runtimeType} to Map<String, dynamic>',
    );
  }

  // Common CRUD operations
  Future<String> add(T item) async {
    try {
      final id = getId(item);
      await _box.put(id, toMap(item));
      invalidateCache();
      DebugLogger.success('Item added', tag: tag, data: id);
      return id;
    } catch (e) {
      DebugLogger.error('Failed to add item', tag: tag, error: e);
      throw Exception('Failed to add item: $e');
    }
  }

  T? get(String id) {
    try {
      // Check cache first
      if (isCacheValid()) {
        try {
          return _cachedItems?.firstWhere((item) => getId(item) == id);
        } catch (_) {
          // Not in cache, continue
        }
      }

      final data = _box.get(id);
      if (data != null) {
        final typedMap = convertToTypedMap(data);
        return fromMap(typedMap);
      }
      return null;
    } catch (e) {
      DebugLogger.error('Failed to get item', tag: tag, error: e);
      return null;
    }
  }

  List<T> getAll({
    bool includeDeleted = false,
    bool forceRefresh = false,
    String operationType = 'read',
  }) {
    try {
      // Use operation-based cache validation
      final shouldRefresh =
          forceRefresh ||
          shouldRefreshFromBackground() ||
          !isCacheValidForOperation(operationType);

      // Return cached if valid
      if (!shouldRefresh && _cachedItems != null && !includeDeleted) {
        DebugLogger.verbose(
          'Cache hit',
          tag: tag,
          data: '${_cachedItems!.length} items',
        );
        return _cachedItems!;
      }

      // Load from storage
      final items = <T>[];
      final keys = _box.keys.toList(); // Convert to list once

      for (final key in keys) {
        try {
          final data = _box.get(key);
          if (data != null) {
            final typedMap = convertToTypedMap(data);
            final item = fromMap(typedMap);

            if (includeDeleted || !isDeleted(item)) {
              items.add(item);
            }
          }
        } catch (e) {
          DebugLogger.warning(
            'Skipping corrupted item',
            tag: tag,
            data: '$key: $e',
          );
          continue;
        }
      }

      // Update cache only for non-deleted items
      if (!includeDeleted) {
        updateCache(items);
        _clearBackgroundChangeFlag();
      }

      DebugLogger.success(
        'Items loaded',
        tag: tag,
        data:
            '${items.length} items, cache: ${shouldRefresh ? "refreshed" : "hit"}',
      );

      return items;
    } catch (e) {
      DebugLogger.error('Failed to get all items', tag: tag, error: e);

      // Fallback to cache if available
      if (_cachedItems != null && !includeDeleted) {
        DebugLogger.warning('Returning stale cache due to error', tag: tag);
        return _cachedItems!;
      }

      return [];
    }
  }

  Future<void> update(T item) async {
    try {
      final id = getId(item);
      await _box.put(id, toMap(item));
      invalidateCache();
      DebugLogger.success('Item updated', tag: tag, data: id);
    } catch (e) {
      DebugLogger.error('Failed to update item', tag: tag, error: e);
      throw Exception('Failed to update item: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
      invalidateCache();
      DebugLogger.success('Item deleted', tag: tag, data: id);
    } catch (e) {
      DebugLogger.error('Failed to delete item', tag: tag, error: e);
      throw Exception('Failed to delete item: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.clear();
      invalidateCache();
      DebugLogger.success('All items cleared', tag: tag);
    } catch (e) {
      DebugLogger.error('Failed to clear items', tag: tag, error: e);
      throw Exception('Failed to clear all items: $e');
    }
  }

  // Check if data changed in background
  bool shouldRefreshFromBackground() {
    try {
      final settingsBox = Hive.box(AppConstants.settingsBox);
      final lastBackgroundChange = settingsBox.get('_background_data_changed');

      if (lastBackgroundChange != null && _lastCacheUpdate != null) {
        final backgroundTime = DateTime.fromMillisecondsSinceEpoch(
          lastBackgroundChange,
        );
        return backgroundTime.isAfter(_lastCacheUpdate!);
      }

      return lastBackgroundChange != null;
    } catch (e) {
      return false;
    }
  }

  void _clearBackgroundChangeFlag() {
    try {
      final settingsBox = Hive.box(AppConstants.settingsBox);
      settingsBox.delete('_background_data_changed');
    } catch (e) {
      // Ignore error
    }
  }

  // Batch operations for better performance
  Future<List<String>> addBatch(List<T> items) async {
    try {
      final ids = <String>[];

      // Prepare all data first
      final dataMap = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final id = getId(item);
        dataMap[id] = toMap(item);
        ids.add(id);
      }

      // Write in batch
      await _box.putAll(dataMap);

      invalidateCache();
      DebugLogger.success(
        'Batch add completed',
        tag: tag,
        data: '${ids.length} items',
      );

      return ids;
    } catch (e) {
      DebugLogger.error('Failed to add batch', tag: tag, error: e);
      throw Exception('Failed to add batch: $e');
    }
  }

  Future<void> updateBatch(List<T> items) async {
    try {
      final dataMap = <String, Map<String, dynamic>>{};
      for (final item in items) {
        final id = getId(item);
        dataMap[id] = toMap(item);
      }

      await _box.putAll(dataMap);
      invalidateCache();

      DebugLogger.success(
        'Batch update completed',
        tag: tag,
        data: '${items.length} items',
      );
    } catch (e) {
      DebugLogger.error('Failed to update batch', tag: tag, error: e);
      throw Exception('Failed to update batch: $e');
    }
  }

  Future<void> deleteBatch(List<String> ids) async {
    try {
      await _box.deleteAll(ids);
      invalidateCache();

      DebugLogger.success(
        'Batch delete completed',
        tag: tag,
        data: '${ids.length} items',
      );
    } catch (e) {
      DebugLogger.error('Failed to delete batch', tag: tag, error: e);
      throw Exception('Failed to delete batch: $e');
    }
  }
}
