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
    this.ready = false,
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
  final bool ready;
  final String? imageAsset;
  final String? videoAsset;
  final String? audioAsset;
  final int? pauseAtMs;
  final Map<String, String> voiceLines;

  factory LevelDefinition.fromJson(Map<String, dynamic> json) {
    return LevelDefinition(
      id: json['id'] as String,
      letterIndex: json['letterIndex'] as int,
      type: typeFromString(json['type'] as String? ?? 'picture_question'),
      title: json['title'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      acceptedAnswers: (json['acceptedAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [(json['answer'] as String?) ?? ''],
      ready: json['ready'] as bool? ?? false,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'letterIndex': letterIndex,
        'type': typeToString(type),
        'title': title,
        'question': question,
        'answer': answer,
        'acceptedAnswers': acceptedAnswers,
        'ready': ready,
        if (imageAsset != null) 'imageAsset': imageAsset,
        if (videoAsset != null) 'videoAsset': videoAsset,
        if (audioAsset != null) 'audioAsset': audioAsset,
        if (pauseAtMs != null) 'pauseAtMs': pauseAtMs,
        if (voiceLines.isNotEmpty) 'voiceLines': voiceLines,
      };

  LevelDefinition copyWith({
    String? id,
    int? letterIndex,
    LevelType? type,
    String? title,
    String? question,
    String? answer,
    List<String>? acceptedAnswers,
    bool? ready,
    String? imageAsset,
    String? videoAsset,
    String? audioAsset,
    int? pauseAtMs,
    Map<String, String>? voiceLines,
    bool clearImage = false,
    bool clearVideo = false,
    bool clearAudio = false,
    bool clearPauseAt = false,
  }) {
    return LevelDefinition(
      id: id ?? this.id,
      letterIndex: letterIndex ?? this.letterIndex,
      type: type ?? this.type,
      title: title ?? this.title,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      acceptedAnswers: acceptedAnswers ?? this.acceptedAnswers,
      ready: ready ?? this.ready,
      imageAsset: clearImage ? null : (imageAsset ?? this.imageAsset),
      videoAsset: clearVideo ? null : (videoAsset ?? this.videoAsset),
      audioAsset: clearAudio ? null : (audioAsset ?? this.audioAsset),
      pauseAtMs: clearPauseAt ? null : (pauseAtMs ?? this.pauseAtMs),
      voiceLines: voiceLines ?? this.voiceLines,
    );
  }

  static LevelType typeFromString(String raw) {
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

  static String typeToString(LevelType type) {
    switch (type) {
      case LevelType.pictureQuestion:
        return 'picture_question';
      case LevelType.videoQuestion:
        return 'video_question';
      case LevelType.audioQuestion:
        return 'audio_question';
      case LevelType.minigame:
        return 'minigame';
    }
  }

  static String typeLabel(LevelType type) {
    switch (type) {
      case LevelType.pictureQuestion:
        return 'Картинка';
      case LevelType.videoQuestion:
        return 'Видео';
      case LevelType.audioQuestion:
        return 'Аудио';
      case LevelType.minigame:
        return 'Мини-игра';
    }
  }

  bool matchesAnswer(String input) {
    final normalized = _normalize(input);
    if (normalized.isEmpty) return false;
    final candidates = <String>{
      _normalize(answer),
      ...acceptedAnswers.map(_normalize),
    };
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

  List<LevelDefinition> get playableLevels =>
      levels.where((l) => l.ready).toList()
        ..sort((a, b) => a.letterIndex.compareTo(b.letterIndex));

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

  Map<String, dynamic> toJson() => {
        'title': title,
        'voiceLines': voiceLines,
        'levels': levels.map((e) => e.toJson()).toList(),
      };

  LevelsPack copyWith({
    String? title,
    List<LevelDefinition>? levels,
    Map<String, String>? voiceLines,
  }) {
    return LevelsPack(
      title: title ?? this.title,
      levels: levels ?? this.levels,
      voiceLines: voiceLines ?? this.voiceLines,
    );
  }

  LevelsPack replaceLevel(int index, LevelDefinition level) {
    final next = [...levels];
    next[index] = level;
    return copyWith(levels: next);
  }
}
