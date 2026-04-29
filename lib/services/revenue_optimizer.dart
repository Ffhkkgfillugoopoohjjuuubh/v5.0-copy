import 'dart:async';

class RevenueOptimizer {
  static const Duration _targetAdWindow = Duration(seconds: 30);

  final StreamController<bool> _adRefreshController =
      StreamController<bool>.broadcast();

  Timer? _adTimer;
  Timer? _wordTimer;
  DateTime? _deadline;
  Duration _remaining = _targetAdWindow;
  bool _timerElapsed = false;
  bool _wordsComplete = true;
  bool _isPaused = false;

  Stream<bool> get adRefreshSignal => _adRefreshController.stream;
  Stream<bool> get adRefreshStream => adRefreshSignal;

  void startSession(int wordCount) {
    _adTimer?.cancel();
    _wordTimer?.cancel();
    _wordTimer = null;
    _timerElapsed = false;
    _wordsComplete = false;
    _remaining = _targetAdWindow;
    _isPaused = false;
    _emitRefresh();
    _startAdTimer(_targetAdWindow);
  }

  Stream<String> streamWords(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final controller = StreamController<String>();

    _wordTimer?.cancel();
    _wordsComplete = words.isEmpty;
    _maybeEmitFinalRefresh();

    if (words.isEmpty) {
      controller.close();
      return controller.stream;
    }

    final intervalMilliseconds = wordIntervalMilliseconds(words.length);
    var index = 0;

    _wordTimer = Timer.periodic(
      Duration(milliseconds: intervalMilliseconds),
      (timer) {
        if (index >= words.length) {
          timer.cancel();
          if (_wordTimer == timer) {
            _wordTimer = null;
          }
          _wordsComplete = true;
          _maybeEmitFinalRefresh();
          controller.close();
          return;
        }

        controller.add(words[index]);
        index += 1;
      },
    );

    controller.onCancel = () {
      _wordTimer?.cancel();
      _wordTimer = null;
      _wordsComplete = true;
      _maybeEmitFinalRefresh();
    };

    return controller.stream;
  }

  void pauseTimer() {
    if (_isPaused || _adTimer == null || _timerElapsed) {
      return;
    }

    final deadline = _deadline;
    if (deadline != null) {
      _remaining = deadline.difference(DateTime.now());
      if (_remaining.isNegative) {
        _remaining = Duration.zero;
      }
    }
    _adTimer?.cancel();
    _adTimer = null;
    _isPaused = true;
  }

  void resumeTimer() {
    if (!_isPaused || _timerElapsed) {
      return;
    }

    _isPaused = false;
    _startAdTimer(_remaining);
  }

  Duration estimatedDuration(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    return Duration(
      milliseconds: wordIntervalMilliseconds(words) * (words == 0 ? 1 : words),
    );
  }

  int wordIntervalMilliseconds(int wordCount) {
    if (wordCount <= 0) {
      return 40;
    }
    return (30000 / wordCount).clamp(40, 200).round();
  }

  void dispose() {
    _adTimer?.cancel();
    _wordTimer?.cancel();
    _adRefreshController.close();
  }

  void _startAdTimer(Duration duration) {
    _adTimer?.cancel();
    if (duration <= Duration.zero) {
      _handleTimerElapsed();
      return;
    }

    _deadline = DateTime.now().add(duration);
    _adTimer = Timer(duration, _handleTimerElapsed);
  }

  void _handleTimerElapsed() {
    _adTimer?.cancel();
    _adTimer = null;
    _timerElapsed = true;
    _remaining = Duration.zero;
    _maybeEmitFinalRefresh();
  }

  void _maybeEmitFinalRefresh() {
    if (_timerElapsed && _wordsComplete) {
      _emitRefresh();
      _timerElapsed = false;
    }
  }

  void _emitRefresh() {
    if (!_adRefreshController.isClosed) {
      _adRefreshController.add(true);
    }
  }
}
