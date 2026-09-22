# 2 人・別 PC で同時並行開発する時の運用ルール (案 v0)

この repo で検証するルールの一覧。2 人 (フロント担当 / バック担当で固定) が、それぞれ自分の PC と自分の Claude で同時に進める前提。
「案 v0」= まだ 2 台で回して確かめていない。確かめた結果は下の「検証で確かめること」の欄に書き足す。

## 考え方 (先に 3 行)

- 「誰がやるか」はフロント / バックの固定で決まるので、仕分ける役は要らない
- コンフリクトはゼロにできない。**起きる場所を 1 か所 (契約) に寄せ、起きる時を決めた瞬間 (契約の PR) にずらし、残りは小さく早く出す**
- 見張り役 (PR を見て重なりを知らせる役) は「早く気づく」ための物で、防ぐのは上の構造のほう

## ルール一覧

| # | ルール | なぜ | 何で担保するか |
|---|---|---|---|
| 1 | 担当はフロント / バックで固定する | 誰がやるかを毎回決めなくて済む。1 つのフォルダを触る人が 1 人になる | `frontend/` `backend/` の分け方と CODEOWNERS |
| 2 | 1 つの機能は、フロントの issue とバックの issue の対で切る | 同じ機能を 2 人が同時に進められる。対にしておくと、繋ぐ時にどれとどれかが分かる | issue の雛形の「対になる issue」欄 |
| 3 | 接続部の約束事 (契約) は `contract/` に置き、契約だけの PR を先に通す | 2 人が同時に触るファイルを契約 1 つに絞れる。フロントは契約からモックを作って先に進め、バックは契約どおりに作る | `contract/` は 2 人の担当 (CODEOWNERS)。契約の変更は専用 PR |
| 4 | 着手の前に「触る見込みのファイル」を issue に書く | 相手が着手する時に、重なりを見られる。見張り役の材料になる | issue の雛形の欄。案 3 なら各自の Claude が書く |
| 5 | branch は 2 日以内に main へ戻す。PR は 1 つで完結する小さな変更にする (目安 100 行) | 長く開いた branch ほど、戻す時にぶつかる。小さいほどぶつかっても直しやすい | 目安。数字は出典のもの |
| 6 | main の最新を取り込んでからでないと merge できない | 先に merge された相手の変更を取り込んでから merge するので、main が壊れない。merge queue の代わり | main の保護の設定 (Require branches to be up to date) |
| 7 | 担当外のフォルダを触る PR は、担当がレビューする | 自分の場所を相手に勝手に変えられない。変えるなら担当が見る | CODEOWNERS → 自動でレビュー依頼が飛ぶ |

## 見張り役の置き方 (3 案。排他ではなく積める)

| 案 | 見る役 | 動くきっかけ | 費用 | 「push を見ていて割り振る役」への応え方 |
|---|---|---|---|---|
| 1. 機械の見張り | CODEOWNERS + PR ごとに走る検査 (AI なし) | PR が出た時 | GitHub Actions の実行時間だけ | 見張るが、割り振りの判断はしない |
| 2. GitHub 上の Claude | claude-code-action で GitHub の中で Claude を動かす | PR・issue・定期実行 | Actions の実行時間 + Claude の利用料 | 正面から応える |
| 3. 各自の Claude | 着手の時に open な PR と issue を読み、触る見込みを issue に書く | 着手した時 | 0 円 | 応えない (着手の瞬間だけ) |

積む順の案: 1 を土台に入れる → 3 を足す → 機械で拾えない食い違いが出てから 2 を載せる。

## 1 つの機能を回す流れ

1. 契約を決める — `contract/` だけを変える PR を 1 本。2 人で見て merge (ルール 3)
2. issue を対で立てる — フロント用とバック用 (ルール 2)。「触る見込みのファイル」を書く (ルール 4)
3. 各自の PC で着手 — branch と worktree を作り、自分の Claude に issue を読ませる
4. 実装 — フロントは契約からモックで進める。バックは契約どおりに作る。相手のフォルダは触らない (ルール 1)
5. PR — 小さく (ルール 5)。相手のフォルダを触っていれば相手にレビュー依頼が飛ぶ (ルール 7)
6. merge — main の最新を取り込んでから (ルール 6)
7. 繋いで確かめる — 両方 merge した後、契約どおりに動くか

## 検証で確かめること (2 台で回す)

| # | 確かめること | 結果 |
|---|---|---|
| A | 相手のフォルダを触る PR を出すと、相手にレビュー依頼が飛ぶか (ルール 7) | 未 |
| B | 自分のフォルダだけの PR で「担当の承認を必須」にすると、作者は自分の PR を承認できないので止まるか。止まるなら、2 人が互いに見る形にするか、承認は必須にせず依頼だけにするか | 未 |
| C | main が進んだ後の古い branch は、最新を取り込むまで merge が止まるか (ルール 6) | 未 |
| D | 契約だけの PR → 対の issue → 各 PC で実装 → 繋ぐ、を最後まで通した時、`contract/` 以外でぶつかる場所が出るか。出たら、それが「共有ファイル」の置き場の候補 | 未 |
| E | PR ごとの検査 (案 1) が、「触る見込みのファイル」と実際の差分、進行中の他の PR との重なりを測って知らせられるか | 未 |
| F | 案 3 を各自の Claude の着手の手順に足した時、相手の issue の「触る見込みのファイル」を拾って書けるか | 未 |

## まだ決めていないこと

- 共有ファイル (依存の一覧・設定・共通の型) の置き場と担当。検証 D で出た場所から決める
- 契約を何で書くか (OpenAPI など)。実案件の技術の構成が決まってから
- 整形ツールの設定を repo に入れて 2 台で揃えるか (出典なしの実務の案)

## 出典 (ルール 3・5・6 の根拠)

- 契約を実装より先に書く: OpenAPI Initiative "Best Practices" https://learn.openapis.org/best-practices.html
- branch は 2 日以内: trunkbaseddevelopment.com "Short-Lived Feature Branches" https://trunkbaseddevelopment.com/short-lived-feature-branches/
- 同時に開く branch は 3 本以下: DORA "Trunk-based development" https://dora.dev/capabilities/trunk-based-development/
- PR は 100 行が目安: Google Engineering Practices "Small CLs" https://google.github.io/eng-practices/review/developer/small-cls.html
- main の最新を取り込んでから merge は merge queue と同じ利点: GitHub Docs "Managing a merge queue" https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue
- CODEOWNERS: GitHub Docs "About code owners" https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
