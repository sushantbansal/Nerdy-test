import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';

import 'session_service.dart';

/// Friendly spoken narration for early readers.
///
/// Narration is a support, never the only channel: every narrated screen also
/// shows the same words as captions and pictures. If the platform has no voice
/// (or the child muted sound), calls are quietly ignored.
class NarrationService extends GetxService {
  NarrationService(this._session);

  final SessionService _session;
  final FlutterTts _tts = FlutterTts();

  Future<void>? _configuring;
  int _generation = 0;

  bool get enabled => _session.soundEnabled;

  bool get _canPaceSentences =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void onInit() {
    super.onInit();
    // Warm up voices and audio settings before the first question is shown.
    unawaited(_configure());
  }

  Future<void> speak(String text) async {
    final script = text.trim();
    if (script.isEmpty || !enabled) return;

    final generation = ++_generation;
    await _configure();
    if (generation != _generation) return;

    try {
      await _tts.stop();
    } catch (_) {
      // No voice engine yet.
    }

    final sentences = _splitSentences(script);
    if (!_canPaceSentences || sentences.length <= 1) {
      try {
        await _tts.speak(script);
      } catch (_) {
        // A missing voice engine should never interrupt play.
      }
      return;
    }

    for (var index = 0; index < sentences.length; index++) {
      if (generation != _generation) return;
      if (index > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        if (generation != _generation) return;
      }
      try {
        await _tts.speak(sentences[index]).timeout(const Duration(seconds: 15));
      } on TimeoutException {
        // Some engines do not report completion. Fall back to one utterance
        // for the rest instead of leaving the child with half a sentence.
        if (generation != _generation) return;
        try {
          await _tts.stop();
          await _tts.speak(sentences.skip(index).join(' '));
        } catch (_) {
          // Nothing else we can do.
        }
        return;
      } catch (_) {
        return;
      }
    }
  }

  Future<void> stop() async {
    _generation++;
    try {
      await _tts.stop();
    } catch (_) {
      // No voice engine.
    }
  }

  Future<void> _configure() {
    return _configuring ??= _configureOnce();
  }

  Future<void> _configureOnce() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      await _tts.setPitch(1.02);
      await _tts.setVolume(1.0);

      if (!kIsWeb) {
        await _tts.awaitSpeakCompletion(true);
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await _tts.setSharedInstance(true);
        } catch (_) {
          // Older iOS versions.
        }
        try {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            const [
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ],
          );
        } catch (_) {
          // Audio session is unavailable in some test/preview environments.
        }
      }

      final voices = await _tts.getVoices;
      if (voices is List) {
        final best = _bestVoice(voices);
        if (best != null) {
          await _tts.setVoice({'name': best.name, 'locale': best.locale});
        }
      }
    } catch (_) {
      // Keep the platform default when settings or voices are unavailable.
    }
  }

  ({String name, String locale, int score})? _bestVoice(List<dynamic> voices) {
    const noveltyNames = {
      'albert',
      'bad news',
      'bells',
      'boing',
      'bubbles',
      'cellos',
      'good news',
      'jester',
      'organ',
      'superstar',
      'trinoids',
      'whisper',
      'wobble',
      'zarvox',
    };

    ({String name, String locale, int score})? best;
    for (final raw in voices) {
      if (raw is! Map) continue;
      final name = '${raw['name'] ?? ''}'.trim();
      if (name.isEmpty) continue;
      final locale = '${raw['locale'] ?? raw['language'] ?? ''}'.replaceAll(
        '_',
        '-',
      );
      if (!locale.toLowerCase().startsWith('en')) continue;
      final lower = name.toLowerCase();
      if (noveltyNames.any(lower.contains)) continue;

      var score = 0;
      if (locale.toLowerCase() == 'en-us') {
        score += 50;
      } else if (locale.toLowerCase().startsWith('en-gb')) {
        score += 10;
      }
      if (lower.contains('enhanced') ||
          lower.contains('premium') ||
          lower.contains('neural') ||
          lower.contains('natural')) {
        score += 50;
      }
      if (lower.contains('samantha')) score += 25;
      if (lower.contains('ava') || lower.contains('allison')) score += 20;
      if (lower.contains('susan') ||
          lower.contains('zoe') ||
          lower.contains('nicky')) {
        score += 15;
      }
      if (lower.contains('google us english')) score += 30;
      if (lower.contains('female')) score += 20;
      if ('${raw['gender'] ?? ''}'.toLowerCase() == 'female') score += 20;
      if ('${raw['network_required'] ?? ''}'.toLowerCase() == 'false') {
        score += 5;
      }
      final quality = int.tryParse('${raw['quality'] ?? ''}') ?? 0;
      score += (quality.clamp(0, 500) ~/ 10);

      if (best == null || score > best.score) {
        best = (name: name, locale: locale, score: score);
      }
    }
    return best;
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.isNotEmpty)
        .toList(growable: false);
  }
}

/// Builds short, punctuation-friendly scripts from game content.
class NarrationText {
  NarrationText._();

  static String question({
    required String text,
    required List<String> options,
  }) {
    final buffer = StringBuffer(_readable(text));
    if (options.isNotEmpty) {
      final readable = options.map(_readable).toList(growable: false);
      final choices = switch (readable.length) {
        1 => readable.first,
        2 => '${readable[0]} or ${readable[1]}',
        _ =>
          '${readable.take(readable.length - 1).join(', ')}, or '
              '${readable.last}',
      };
      buffer.write(' The choices are $choices.');
    }
    return buffer.toString();
  }

  static String feedback({
    required bool correct,
    required String correctAnswer,
    required String explanation,
  }) {
    if (correct) {
      return 'Yes! $correctAnswer is right. ${_readable(explanation)}';
    }
    return 'Good try. The answer is $correctAnswer. '
        'Let’s look together. ${_readable(explanation)}';
  }

  static String _readable(String value) {
    var text = value
        .replaceAllMapped(
          RegExp(r'\$(\d+(?:\.\d+)?)'),
          (match) => '${match[1]} dollars',
        )
        .replaceAllMapped(
          RegExp(r'(\d),(\d{3})(?!\d)'),
          (match) => '${match[1]}${match[2]}',
        )
        .replaceAll(RegExp(r'=\s*\?'), ' equals what?')
        .replaceAll('×', ' times ')
        .replaceAll('÷', ' divided by ')
        .replaceAll('−', ' minus ')
        .replaceAll('–', ' minus ')
        .replaceAll('+', ' plus ')
        .replaceAll('=', ' equals ')
        .replaceAll('%', ' percent ')
        .replaceAll('°', ' degrees ')
        .replaceAll('/', ' over ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\s+([,.!?])'), r'$1')
        .trim();
    return text;
  }
}
