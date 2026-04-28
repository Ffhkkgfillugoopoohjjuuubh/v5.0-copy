import 'dart:async';

class RevenueOptimizer {
  final StreamController<void> _adRefreshController =
      StreamController<void>.broadcast();
  final List<Timer> _timers = <Timer>[];

  Stream<void> get adRefreshStream => _adRefreshController.stream;

  Stream<String> streamWords(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    final controller = StreamController<String>();

    if (words.isEmpty) {
      controller.close();
      return controller.stream;
    }

    final intervalMilliseconds = wordIntervalMilliseconds(words.length);
    var index = 0;

    late final Timer adTimer;
    adTimer = Timer(const Duration(seconds: 30), () {
      _adRefreshController.add(null);
      _timers.remove(adTimer);
    });
    _timers.add(adTimer);

    late final Timer wordTimer;
    wordTimer = Timer.periodic(
      Duration(milliseconds: intervalMilliseconds),
      (timer) {
        if (index >= words.length) {
          timer.cancel();
          _timers.remove(wordTimer);
          controller.close();
          return;
        }

        controller.add(words[index]);
        index += 1;
      },
    );

    _timers.add(wordTimer);

    controller.onCancel = () {
      wordTimer.cancel();
      _timers.remove(wordTimer);
    };

    return controller.stream;
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
      return 30;
    }
    return (30000 / wordCount).clamp(30, 180).round();
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _adRefreshController.close();
  }
}
