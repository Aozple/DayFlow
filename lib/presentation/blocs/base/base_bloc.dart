import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/utils/app_date_utils.dart';
import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  final String tag;

  bool _isProcessing = false;
  DateTime? _lastLoadTime;
  static const Duration minLoadInterval = AppConstants.quickExportDuration;

  BaseBloc({required this.tag, required State initialState})
    : super(initialState);

  bool canProcess({bool forceRefresh = false}) {
    if (_isProcessing && !forceRefresh) {
      logWarning('Operation in progress');
      return false;
    }

    if (_lastLoadTime != null && !forceRefresh) {
      final timeSinceLastLoad = AppDateUtils.now.difference(_lastLoadTime!);
      if (timeSinceLastLoad < minLoadInterval) {
        logVerbose(
          'Too soon to reload',
          data: '${timeSinceLastLoad.inMilliseconds}ms',
        );
        return false;
      }
    }

    return true;
  }

  void startProcessing() {
    _isProcessing = true;
    _lastLoadTime = AppDateUtils.now;
    logVerbose('Processing started');
  }

  void endProcessing() {
    _isProcessing = false;
    logVerbose('Processing ended');
  }

  bool get isProcessing => _isProcessing;

  void _log(
    void Function(String, {String? tag, dynamic data}) logMethod,
    String message, {
    dynamic data,
  }) {
    logMethod(message, tag: tag, data: data);
  }

  void logInfo(String message, {dynamic data}) =>
      _log(DebugLogger.info, message, data: data);

  void logSuccess(String message, {dynamic data}) =>
      _log(DebugLogger.success, message, data: data);

  void logError(String message, {dynamic error}) =>
      DebugLogger.error(message, tag: tag, error: error);

  void logWarning(String message, {dynamic data}) =>
      _log(DebugLogger.warning, message, data: data);

  void logVerbose(String message, {dynamic data}) =>
      _log(DebugLogger.verbose, message, data: data);

  Future<void> handleError(
    dynamic error,
    Emitter<State> emit,
    State Function(String) createErrorState,
    State? fallbackState,
  ) async {
    logError('Operation failed', error: error);

    emit(createErrorState(error.toString()));

    if (fallbackState != null) {
      await Future.delayed(const Duration(seconds: 1));
      emit(fallbackState);
    }
  }

  Future<void> performOperation<T>({
    required String operationName,
    required Future<T> Function() operation,
    required Emitter<State> emit,
    State? loadingState,
    required State Function(T) successState,
    State Function(String)? errorState,
    State? fallbackState,
    bool checkProcessing = true,
  }) async {
    if (checkProcessing && !canProcess()) return;

    startProcessing();

    try {
      logInfo('Starting $operationName');

      if (loadingState != null) {
        emit(loadingState);
      }

      final result = await operation();

      emit(successState(result));
      logSuccess('$operationName completed');
    } catch (e) {
      if (errorState != null) {
        await handleError(e, emit, errorState, fallbackState);
      } else {
        logError('$operationName failed', error: e);
      }
    } finally {
      endProcessing();
    }
  }

  @override
  Future<void> close() {
    logInfo('Closing $tag');

    // Cleanup processing state
    _isProcessing = false;
    _lastLoadTime = null;

    return super.close();
  }
}
