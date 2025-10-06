import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

abstract class BaseRepository<T> {
  final String tag;
  final Box _box;

  List<T>? _cachedItems;
  DateTime? _lastCacheUpdate;
  Box? _cachedSettingsBox;

  Box get _settingsBox {
    _cachedSettingsBox ??= Hive.box(AppConstants.settingsBox);
    return _cachedSettingsBox!;
  }

  BaseRepository({required String boxName, required this.tag})
    : _box = Hive.box(boxName);

  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T item);
  String getId(T item);
  bool isDeleted(T item);

  R? _executeWithErrorHandling<R>(
    String operation,
    R? Function() action, {
    R? fallback,
  }) {
    try {
      return action();
    } catch (e) {
      DebugLogger.error('Failed to $operation', tag: tag, error: e);

      if (e.toString().contains('Hive')) {
        _cachedItems = null;
        _lastCacheUpdate = null;
      }

      return fallback;
    }
  }

  Future<R> _executeAsyncWithErrorHandling<R>(
    String operation,
    Future<R> Function() action,
  ) async {
    try {
      return await action();
    } catch (e) {
      DebugLogger.error('Failed to $operation', tag: tag, error: e);
      throw Exception('Failed to $operation: $e');
    }
  }

  void invalidateCache() {
    _cachedItems = null;
    _lastCacheUpdate = null;
    DebugLogger.verbose('Cache invalidated', tag: tag);
  }

  void forceCleanup() {
    _cachedItems = null;
    _lastCacheUpdate = null;
    _cachedSettingsBox = null;
  }

  bool isCacheValid() {
    if (_cachedItems == null || _lastCacheUpdate == null) return false;

    final age = AppDateUtils.now.difference(_lastCacheUpdate!);
    if (age >= AppConstants.defaultCacheDuration) return false;

    return _executeWithErrorHandling('check cache invalidation', () {
          final forceInvalidation = _settingsBox.get(
            '_force_cache_invalidation',
          );
          if (forceInvalidation != null) {
            final invalidationTime = DateTime.fromMillisecondsSinceEpoch(
              forceInvalidation,
            );
            if (invalidationTime.isAfter(_lastCacheUpdate!)) {
              DebugLogger.info(
                'Cache invalidated by background action',
                tag: tag,
              );
              _settingsBox.delete('_force_cache_invalidation');
              return false;
            }
          }
          return true;
        }, fallback: true) ??
        true;
  }

  void updateCache(List<T> items) {
    if (items.length > 50) {
      _cachedItems = null;
      _lastCacheUpdate = null;
      return;
    }
    _cachedItems = items;
    _lastCacheUpdate = AppDateUtils.now;
  }

  bool isCacheValidForOperation(String operationType) {
    if (_cachedItems == null || _lastCacheUpdate == null) return false;

    final age = AppDateUtils.now.difference(_lastCacheUpdate!);

    switch (operationType) {
      case 'read':
      case 'filter':
      case 'search':
        return age < AppConstants.defaultCacheDuration;
      case 'write':
      case 'update':
      case 'delete':
        return age < AppConstants.quickExportDuration;
      default:
        return age < AppConstants.defaultCacheDuration;
    }
  }

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
      final converted = <String, dynamic>{};
      data.forEach((key, value) {
        converted[key.toString()] = convertValue(value);
      });
      return converted;
    }

    throw Exception(
      'Cannot convert ${data.runtimeType} to Map<String, dynamic>',
    );
  }

  Future<String> add(T item) async {
    return _executeAsyncWithErrorHandling('add item', () async {
      final id = getId(item);
      await _box.put(id, toMap(item));
      invalidateCache();
      DebugLogger.success('Item added', tag: tag, data: id);
      return id;
    });
  }

  T? get(String id) {
    return _executeWithErrorHandling('get item', () {
      if (isCacheValid()) {
        try {
          return _cachedItems?.firstWhere((item) => getId(item) == id);
        } catch (_) {}
      }

      final data = _box.get(id);
      if (data != null) {
        final typedMap = convertToTypedMap(data);
        return fromMap(typedMap);
      }
      return null;
    });
  }

  List<T> getAll({
    bool includeDeleted = false,
    bool forceRefresh = false,
    String operationType = 'read',
  }) {
    return _executeWithErrorHandling('get all items', () {
          final shouldRefresh =
              forceRefresh ||
              shouldRefreshFromBackground() ||
              !isCacheValidForOperation(operationType);

          if (!shouldRefresh && _cachedItems != null && !includeDeleted) {
            DebugLogger.verbose(
              'Cache hit',
              tag: tag,
              data: '${_cachedItems!.length} items',
            );
            return _cachedItems!;
          }

          final items = <T>[];
          final keys = _box.keys.toList();

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
        }, fallback: _cachedItems ?? []) ??
        [];
  }

  Future<void> update(T item) async {
    return _executeAsyncWithErrorHandling('update item', () async {
      final id = getId(item);
      await _box.put(id, toMap(item));
      invalidateCache();
      DebugLogger.success('Item updated', tag: tag, data: id);
    });
  }

  Future<void> delete(String id) async {
    return _executeAsyncWithErrorHandling('delete item', () async {
      await _box.delete(id);
      invalidateCache();
      DebugLogger.success('Item deleted', tag: tag, data: id);
    });
  }

  Future<void> clearAll() async {
    return _executeAsyncWithErrorHandling('clear all items', () async {
      await _box.clear();
      invalidateCache();
      DebugLogger.success('All items cleared', tag: tag);
    });
  }

  bool shouldRefreshFromBackground() {
    return _executeWithErrorHandling('check background refresh', () {
          final lastBackgroundChange = _settingsBox.get(
            '_background_data_changed',
          );

          if (lastBackgroundChange != null && _lastCacheUpdate != null) {
            final backgroundTime = DateTime.fromMillisecondsSinceEpoch(
              lastBackgroundChange,
            );
            return backgroundTime.isAfter(_lastCacheUpdate!);
          }

          return lastBackgroundChange != null;
        }, fallback: false) ??
        false;
  }

  void _clearBackgroundChangeFlag() {
    _executeWithErrorHandling('clear background flag', () {
      _settingsBox.delete('_background_data_changed');
      return null;
    });
  }

  Future<List<String>> addBatch(List<T> items) async {
    return _executeAsyncWithErrorHandling('add batch', () async {
      final ids = <String>[];
      final dataMap = <String, Map<String, dynamic>>{};

      for (final item in items) {
        final id = getId(item);
        dataMap[id] = toMap(item);
        ids.add(id);
      }

      await _box.putAll(dataMap);
      invalidateCache();
      DebugLogger.success(
        'Batch add completed',
        tag: tag,
        data: '${ids.length} items',
      );
      return ids;
    });
  }

  Future<void> updateBatch(List<T> items) async {
    return _executeAsyncWithErrorHandling('update batch', () async {
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
    });
  }

  Future<void> deleteBatch(List<String> ids) async {
    return _executeAsyncWithErrorHandling('delete batch', () async {
      await _box.deleteAll(ids);
      invalidateCache();
      DebugLogger.success(
        'Batch delete completed',
        tag: tag,
        data: '${ids.length} items',
      );
    });
  }
}
