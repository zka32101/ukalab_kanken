/// 出題形式・カテゴリの内部名（reading/stroke など）を、画面に出す日本語名にする。
/// 模擬試験（ExamCategory）と練習モード（PracticeMode）の両方の内部名を扱う。
/// 画面に内部名の英語をそのまま出さないよう、表示は必ずここを通す。
const Map<String, String> categoryLabels = {
  'reading': '読み',
  'meaning': '意味',
  'stroke': '画数',
  'writing': '書き取り',
  'usage': '使い方',
  'mixed': '混合',
  'radical': '部首',
  'compoundStructure': '熟語の構成',
  'strokeCount': '画数',
};

/// 知らない値は、そのまま出す（落とさない）。
String categoryLabel(String key) => categoryLabels[key] ?? key;
