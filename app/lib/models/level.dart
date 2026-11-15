enum LevelType {
  pictureQuestion,
  videoQuestion,
  audioQuestion,
  minigame,
}

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.letterIndex,
    required this.type,
    required this.title,
    required this.question,
    required this.answer,
    required this.acceptedAnswers,
    this.imageAsset,
    this.videoAsset,
    this.audioAsset,
    this.pauseAtMs,
    this.voiceLines = const {},
  });

  final String id;
  final int letterIndex;
  final LevelType type;
  final String title;
  final String question;
  final String answer;
  final List<String> acceptedAnswers;
  final String? imageAsset;
  final String? videoAsset;
  final String? audioAsset;
  final int? pauseAtMs;
  final Map<String, String> voiceLines;

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as String,
      letterIndex: json['letterIndex'] as int,
      type: _parseType(json['type'] as String),
      title: json['title'] as String? ?? '',
      question: json['question'] as String,
      answer: json['answer'] as String,
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [json['answer'] as String],
      imageAsset: json['imageAsset'] as String?,
      videoAsset: json['videoAsset'] as String?,
      audioAsset: json['audioAsset'] as String?,
      pauseAtMs: json['pauseAtMs'] as int?,
      voiceLines: (json['voiceLines'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  static LevelType _parseType(String raw) {
    switch (raw) {
      case 'picture_question':
        return LevelType.pictureQuestion;
      case 'video_question':
        return LevelType.videoQuestion;
      case 'audio_question':
        return LevelType.audioQuestion;
      case 'minigame':
        return LevelType.minigame;
      default:
        return LevelType.pictureQuestion;
    }
  }

  bool matchesAnswer(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return false;
    final candidates = <String>{_normalize(answer), ...acceptedAnswers.map(_normalize)};
    return candidates.contains(normalized);
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class LevelsPack {
  const LevelsPack({
    required this.title,
    required this.levels,
    required this.voiceLines,
  });

  final String title;
  final List<LevelDefinition> levels;
  final Map<String, String> voiceLines;

  factory LevelsPack.fromJson(Map<String, dynamic> json) {
    return LevelsPack(
      title: json['title'] as String? ?? 'С днем рождения, Соня',
      levels: (json['levels'] as List<dynamic>)
          .map((e) => LevelDefinition.fromJson(e as Map<String, dynamic>))
          .toList(),
      voiceLines: (json['voiceLines'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }
}
