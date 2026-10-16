# 専門家レビュー対象（漢検・優先分）

- 必要な専門性: 漢検の指導者・国語科教員（小〜中学校の漢字指導の経験者）
- `review_meaning_priority.csv`: 意味（AI下書き）のうち疑わしい/多義（needsReview）104字と空欄3字。本番画面には未公開（`kKanjiMeaningVisible = false`）。残り約2,029字（draft）は余力があれば級ごとに。
- `review_readings_E.csv`: 読みの差分のうち判断不能（E）10件。必須確認。
- 依頼文・観点・反映方法: ukalab_core の `docs/expert_review_requests.md` §4 と `docs/expert_review_session_handover.md`
- 判定列は空欄。記録は確認日（年月）と確認者区分のみ。氏名・所属・連絡先は記録しない。意味は辞書の文章に似せず自作の言い換えとする。
