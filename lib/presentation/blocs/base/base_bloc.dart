import 'package:dayflow/core/utils/debug_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  final String tag;

  // Processing control
  bool _isProcessing = false;
  DateTime? _lastLoadTime;
  static const Duration minLoadInterval = Duration(milliseconds: 500);

  BaseBloc({required this.tag, required State initialState})
    : super(initialState);

  // Check if can process request
  bool canProcess({bool forceRefresh = false}) {
    if (_isProcessing && !forceRefresh) {
      logWarning('Operation in progress');
      return false;
    }

    if (_lastLoadTime != null && !forceRefresh) {
      final timeSinceLastLoad = DateTime.now().difference(_lastLoadTime!);
      if (timeSinceLastLoad < minLoadInterval) {
        logVerbose('Too soon to reload');
        return false;
      }
    }

    return true;
  }

  // Processing lifecycle
  void startProcessing() {
    _isProcessing = true;
    _lastLoadTime = DateTime.now();
  }

  void endProcessing() {
    _isProcessing = false;
  }

  // Check processing state
  bool get isProcessing => _isProcessing;

  // Logging shortcuts
  void logInfo(String message, {dynamic data}) {
    DebugLogger.info(message, tag: tag, data: data);
  }

  void logSuccess(String message, {dynamic data}) {
    DebugLogger.success(message, tag: tag, data: data);
  }

  void logError(String message, {dynamic error}) {
    DebugLogger.error(message, tag: tag, error: error);
  }

  void logWarning(String message, {dynamic data}) {
    DebugLogger.warning(message, tag: tag, data: data);
  }

  void logVerbose(String message, {dynamic data}) {
    DebugLogger.verbose(message, tag: tag, data: data);
  }

  // Common error handling
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

  // Common operation wrapper
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
    return super.close();
  }
}
