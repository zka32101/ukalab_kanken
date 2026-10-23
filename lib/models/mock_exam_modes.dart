/// Mock exam modes and configurations
enum ExamMode {
  standardExam, // 標準試験（全問題）
  speedExam, // 速度試験（時間制限あり）
  focusedExam, // 集中試験（特定分野のみ）
  weakAreasExam, // 弱点対策試験
  randomExam, // ランダム試験
  progressiveExam, // 段階式試験（難易度段階的）
}

enum ExamDifficulty {
  easy, // 簡単
  medium, // 標準
  hard, // 難しい
  veryHard, // 非常に難しい
}

enum ExamCategory {
  reading, // 読み
  meaning, // 意味
  stroke, // 画数
  writing, // 書き
  usage, // 使い方
  // 以下は、アプリの中で作る出題分野（lib/data/local_exam_questions.dart）。mixed は必ず最後に置く
  // （カテゴリ選択の一覧は「最後の mixed を除く」と決めている）。
  yoji, // 四字熟語
  antonym, // 対義語
  synonym, // 類義語
  homophone, // 同音・同訓異字
  errorCorrection, // 誤字訂正
  radicalName, // 部首名
  okurigana, // 送りがな
  mixed, // 混合
}

/// Mock exam configuration
class ExamConfig {
  final int questionCount; // 問題数
  final int timeLimit; // 時間制限（分）
  final ExamMode mode; // 試験モード
  final ExamDifficulty difficulty; // 難易度
  final List<ExamCategory> categories; // カテゴリ
  final int targetLevel; // 目標級
  final bool showExplanations; // 解説表示
  final bool allowReview; // 見直し可能
  final bool randomizeOrder; // 問題順序ランダム
  final int passThreshold; // 合格ライン（%）

  ExamConfig({
    required this.questionCount,
    required this.timeLimit,
    required this.mode,
    required this.difficulty,
    required this.categories,
    required this.targetLevel,
    this.showExplanations = true,
    this.allowReview = true,
    this.randomizeOrder = true,
    this.passThreshold = 60,
  });

  // examQuestionsの問題数は級によって異なる（5級はパイロットで増量済み、
  // 他の級は1級につき20問程度）。各モードの問題数は実際に用意できる件数を
  // 超えないようにしている。件数を増やす場合は
  // scripts/seed-exam-questions-l9-l5.js・scripts/generate-exam-questions-pilot.js
  // 側のデータ拡充と合わせてここも見直すこと（lib/screens/mock_exam_modes_screen.dartの
  // サブタイトル表示もquestionCountと連動させている）。

  /// 日本漢字能力検定の公式の検定時間（分）。8級以下（8・9・10級）は40分、
  /// 7級以上は60分（日本漢字能力検定協会の公表値）。
  static int officialMinutes(int level) =>
      (level >= 8 && level <= 10) ? 40 : 60;

  /// 日本漢字能力検定の公式の合格基準（満点に対する得点率の目安・%）。
  /// 1・2級と8〜10級は80％程度、3〜7級は70％程度（協会の各級の概要ページ）。
  /// 公式の表記が「程度」のため、本番の合否ではなく模擬試験の目安として使う。
  ///
  /// 模擬試験の level は int で、準2級は 25、準1級は 15（mock_exam_modes_screen.dart の
  /// 変換）。準2級は70％程度、準1級は80％程度。8以上で一括りにすると準2級(25)が
  /// 40分・80％になってしまうため、8〜10級だけを明示する。
  static int officialPassPercent(int level) =>
      (level <= 2 || level == 15 || (level >= 8 && level <= 10)) ? 80 : 70;

  /// 合格ライン以上か。小数の誤差が出ないよう整数で比べる（境界ちょうどは合格）。
  bool isPass(int correct, int total) =>
      total > 0 && correct * 100 >= passThreshold * total;

  /// Standard exam (official format)
  factory ExamConfig.standard({int level = 3}) => ExamConfig(
    questionCount: 20,
    timeLimit: officialMinutes(level),
    mode: ExamMode.standardExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  /// Speed exam: time-limited
  factory ExamConfig.speed({int level = 3}) => ExamConfig(
    questionCount: 20,
    timeLimit: 60,
    mode: ExamMode.speedExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  /// Focused exam: questions on a specific category（1級・1カテゴリあたり5問のみ）
  factory ExamConfig.focused({
    required ExamCategory category,
    int level = 3,
  }) => ExamConfig(
    questionCount: 5,
    timeLimit: 45,
    mode: ExamMode.focusedExam,
    difficulty: ExamDifficulty.medium,
    categories: [category],
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  /// Weak areas exam: Adaptive based on user performance
  factory ExamConfig.weakAreas({int level = 3}) => ExamConfig(
    questionCount: 20,
    timeLimit: 90,
    mode: ExamMode.weakAreasExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  /// Random exam: Mix of all question types
  factory ExamConfig.random({int level = 3}) => ExamConfig(
    questionCount: 20,
    timeLimit: 90,
    mode: ExamMode.randomExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  /// Progressive exam: Difficulty increases with correct answers
  factory ExamConfig.progressive({int level = 3}) => ExamConfig(
    questionCount: 20,
    timeLimit: 150,
    mode: ExamMode.progressiveExam,
    difficulty: ExamDifficulty.medium,
    categories: ExamCategory.values,
    targetLevel: level,
    passThreshold: officialPassPercent(level),
  );

  Map<String, dynamic> toJson() => {
    'questionCount': questionCount,
    'timeLimit': timeLimit,
    'mode': mode.toString(),
    'difficulty': difficulty.toString(),
    'categories': categories.map((c) => c.toString()).toList(),
    'targetLevel': targetLevel,
    'showExplanations': showExplanations,
    'allowReview': allowReview,
    'randomizeOrder': randomizeOrder,
    'passThreshold': passThreshold,
  };

  factory ExamConfig.fromJson(Map<String, dynamic> json) => ExamConfig(
    questionCount: json['questionCount'] as int? ?? 50,
    timeLimit: json['timeLimit'] as int? ?? 120,
    mode: ExamMode.values.firstWhere(
      (m) => m.toString() == json['mode'],
      orElse: () => ExamMode.standardExam,
    ),
    difficulty: ExamDifficulty.values.firstWhere(
      (d) => d.toString() == json['difficulty'],
      orElse: () => ExamDifficulty.medium,
    ),
    categories: (json['categories'] as List?)
        ?.map((c) => ExamCategory.values.firstWhere(
          (cat) => cat.toString() == c,
          orElse: () => ExamCategory.mixed,
        ))
        .toList() ?? ExamCategory.values.toList(),
    targetLevel: json['targetLevel'] as int? ?? 3,
    showExplanations: json['showExplanations'] as bool? ?? true,
    allowReview: json['allowReview'] as bool? ?? true,
    randomizeOrder: json['randomizeOrder'] as bool? ?? true,
    passThreshold: json['passThreshold'] as int? ?? 60,
  );
}

/// Enhanced exam question with metadata
class EnhancedExamQuestion {
  final String questionId;
  final String kanji;
  final String questionType;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final int level; // 10-1級
  final ExamDifficulty difficulty;
  final ExamCategory category;
  final double averageTimeSeconds;
  final double correctnessRate; // ユーザーの正答率
  final int userAttempts; // ユーザーが解いた回数
  final List<String> commonMistakes; // よくある間違い
  final String? additionalTip; // 追加ヒント

  const EnhancedExamQuestion({
    required this.questionId,
    required this.kanji,
    required this.questionType,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.level,
    required this.difficulty,
    required this.category,
    required this.averageTimeSeconds,
    required this.correctnessRate,
    required this.userAttempts,
    required this.commonMistakes,
    this.additionalTip,
  });

  factory EnhancedExamQuestion.fromJson(Map<String, dynamic> json) =>
    EnhancedExamQuestion(
      questionId: json['questionId'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      questionType: json['questionType'] as String? ?? 'reading',
      question: json['question'] as String? ?? '',
      options: List<String>.from(json['options'] as List? ?? []),
      correctAnswer: json['correctAnswer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      level: json['level'] as int? ?? 3,
      difficulty: ExamDifficulty.values.firstWhere(
        (d) => d.toString() == json['difficulty'],
        orElse: () => ExamDifficulty.medium,
      ),
      category: ExamCategory.values.firstWhere(
        (c) => c.toString() == json['category'],
        orElse: () => ExamCategory.mixed,
      ),
      averageTimeSeconds: (json['averageTimeSeconds'] as num?)?.toDouble() ?? 0.0,
      correctnessRate: (json['correctnessRate'] as num?)?.toDouble() ?? 0.0,
      userAttempts: json['userAttempts'] as int? ?? 0,
      commonMistakes: List<String>.from(json['commonMistakes'] as List? ?? []),
      additionalTip: json['additionalTip'] as String?,
    );

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'kanji': kanji,
    'questionType': questionType,
    'question': question,
    'options': options,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'level': level,
    'difficulty': difficulty.toString(),
    'category': category.toString(),
    'averageTimeSeconds': averageTimeSeconds,
    'correctnessRate': correctnessRate,
    'userAttempts': userAttempts,
    'commonMistakes': commonMistakes,
    'additionalTip': additionalTip,
  };
}
