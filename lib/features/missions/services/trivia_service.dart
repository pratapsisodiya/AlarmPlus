import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TriviaQuestion {
  TriviaQuestion({required this.question, required this.options, required this.answerIndex});

  final String question;
  final List<String> options;
  final int answerIndex;

  factory TriviaQuestion.fromMap(Map<String, dynamic> map) {
    final opts = (map['options'] as List<dynamic>).map((e) => e.toString()).toList();
    return TriviaQuestion(
      question: map['q'] as String? ?? map['question'] as String,
      options: opts,
      answerIndex: (map['answer'] as int?) ?? (map['correct_answer_index'] as int? ?? 0),
    );
  }
}

class TriviaService {
  static const _cacheKey = 'trivia_cache';
  static const _cacheDateKey = 'trivia_cache_date';
  static final _rng = Random();

  static Future<List<TriviaQuestion>> getQuestions({int count = 3}) async {
    final questions = await _loadQuestions();
    questions.shuffle(_rng);
    return questions.take(count).toList();
  }

  static Future<List<TriviaQuestion>> _loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final cacheDate = prefs.getString(_cacheDateKey);

    if (cacheDate == today) {
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        try {
          final list = jsonDecode(raw) as List<dynamic>;
          return list.map((e) => TriviaQuestion.fromMap(e as Map<String, dynamic>)).toList();
        } catch (_) {}
      }
    }

    return _loadFallback();
  }

  static Future<List<TriviaQuestion>> _loadFallback() async {
    final raw = await rootBundle.loadString('assets/data/trivia_fallback.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => TriviaQuestion.fromMap(e as Map<String, dynamic>)).toList();
  }

  static Future<List<String>> getWordList() async {
    final raw = await rootBundle.loadString('assets/data/word_list.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  static String scrambleWord(String word) {
    final chars = word.split('');
    // Keep shuffling until different from original
    for (var i = 0; i < 10; i++) {
      chars.shuffle(_rng);
      if (chars.join() != word) return chars.join();
    }
    return chars.join();
  }
}
