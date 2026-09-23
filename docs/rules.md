# 2 人・別 PC で同時並行開発する時の運用ルール (案 v1)

この repo で検証したルールの一覧。2 人 (フロント担当 / バック担当で固定) が、それぞれ自分の PC と自分の Claude で同時に進める前提。
「案 v1」= 2026-09-23 に 2 台の PC (アカウント 2 つ) で回して確かめた結果を反映した版。v0 からの差分は「検証で分かった事」の節。

## 考え方 (先に 3 行)

- 「誰がやるか」はフロント / バックの固定で決まるので、仕分ける役は要らない
- コンフリクトはゼロにできない。**起きる場所を 1 か所 (契約) に寄せ、起きる時を決めた瞬間 (契約の PR) にずらし、残りは小さく早く出す**
- 見張り役 (PR を見て重なりを知らせる役) は「早く気づく」ための物で、防ぐのは上の構造のほう

## ルール一覧

| # | ルール | なぜ | 誰が守るか |
|---|---|---|---|
| 1 | 担当はフロント / バックで固定する | 誰がやるかを毎回決めなくて済む。1 つのフォルダを触る人が 1 人になる | GitHub の設定 (`frontend/` `backend/` の分け方と CODEOWNERS) |
| 2 | 1 つの機能は、フロントの issue とバックの issue の対で切る | 同じ機能を 2 人が同時に進められる。対にしておくと、繋ぐ時にどれとどれかが分かる | 人 (issue の雛形の「対になる issue」欄が思い出させる) |
| 3 | 接続部の約束事 (契約) は `contract/` に置き、契約だけの PR を先に通す | 2 人が同時に触るファイルを契約 1 つに絞れる。フロントは契約からモックを作って先に進め、バックは契約どおりに作る | 人 (+ GitHub の設定: `contract/` は 2 人の担当なので相手の承認が要る) |
| 4 | 着手の前に「触る見込みのファイル」を issue に書く。**フォルダでなくファイル単位で** | 相手が着手する時に、重なりを見られる。見張り役の材料になる。フォルダ単位だと広く重なって見える | plugin の手順 (着手 skill に入れる。まだ無い) |
| 5 | branch は 2 日以内に main へ戻す。PR は 1 つで完結する小さな変更にする (目安 100 行)。**作業中は早めに Draft PR で出す** | 長く開いた branch ほど、戻す時にぶつかる。Draft で出せば相手と検査から見える | plugin の手順 (完了 skill が促す。まだ無い) |
| 6 | main の最新を取り込んでからでないと merge できない | 先に merge された相手の変更を取り込んでから merge するので、main が壊れない。merge queue の代わり | GitHub の設定 (main の保護 `strict`。画面では「Update branch」ボタンで取り込む) |
| 7 | 担当外のフォルダを触る PR は、担当がレビューする。**自分のフォルダだけの PR は 1 人で merge できる**。**相手の PR の merge ボタンは押さない (Update branch も)** (2026-09-24 に足した) | 自分の場所を相手に勝手に変えられない。並行で進めたいのに merge が相手待ちになる事を避ける。GitHub には PR ごとに押せる人を決める設定が無く、相手の画面でも押せてしまう | GitHub の設定 (CODEOWNERS + 承認の人数 0 + 担当の承認必須)。相手の PR を押さない事は人が守る (押し間違えると、検査の workflow が PR に「作者以外が merge した」「作者以外がこの PR の branch を更新した」を書く) |
| 8 | PR の本文に `Closes #番号` を書き、merge で issue を閉じる | 閉じ忘れた issue の「触る見込み」が、終わった作業なのに重なりとして出続ける | plugin の手順 (完了 skill に入れる。まだ無い) |

## 見張り役の置き方 (3 案。排他ではなく積める。3 つとも検証で動いた)

| 案 | 見る役 | 動くきっかけ | 費用 | 「push を見ていて割り振る役」への応え方 | この repo での実体 |
|---|---|---|---|---|---|
| 1. 機械の検査 | CODEOWNERS + PR ごとに走る検査 (AI なし) | PR が出た時 | GitHub Actions の分数だけ (Team は月 3,000 分込み) | 見張るが、割り振りの判断はしない | `.github/workflows/territory-check.yml` + `.github/scripts/check-overlap.sh` |
| 2. GitHub の中の Claude | claude-code-action で GitHub の中で Claude を動かす | PR・issue・定期実行 | Actions の分数 + Claude の利用分 (誰かのサブスク枠か、会社の API キー) | 正面から応える | `.github/workflows/claude-watch.yml` (secret `CLAUDE_CODE_OAUTH_TOKEN`) |
| 3. 各自の Claude | 着手の時に open な PR と issue を読み、触る見込みを issue に書く | 着手した時 | 0 円 | 応えない (着手の瞬間だけ) | 手で頼んで確認 (skill 化はまだ) |

積む順の案: 1 を土台に入れる → 3 を足す → 機械で拾えない食い違いが出てから 2 を載せる。

## 1 つの機能を回す流れ

1. 契約を決める — `contract/` だけを変える PR を 1 本。2 人で見て merge (ルール 3)
2. issue を対で立てる — フロント用とバック用 (ルール 2)。「触る見込みのファイル」をファイル単位で書く (ルール 4)
3. 各自の PC で着手 — branch と worktree を作り、自分の Claude に issue を読ませる。早めに Draft PR で出す (ルール 5)
4. 実装 — フロントは契約からモックで進める。バックは契約どおりに作る。相手のフォルダは触らない (ルール 1)
5. PR — 小さく (ルール 5)。本文に `Closes #番号` (ルール 8)。相手のフォルダを触っていれば相手にレビュー依頼が飛ぶ (ルール 7)
6. merge — main の最新を取り込んでから (ルール 6)。自分のフォルダだけなら 1 人で押せる (ルール 7)
7. 繋いで確かめる — 両方 merge した後、契約どおりに動くか

## 検証の結果 (2026-09-23、2 台で回した)

| # | 確かめたこと | 結果 | 痕跡 |
|---|---|---|---|
| A | 相手のフォルダを触る PR を出すと、相手にレビュー依頼が飛ぶか (ルール 7) | **飛んだ**。merge は BLOCKED (「Waiting on code owner review」) | PR #7 (contract/、2 人担当) / PR #12 (frontend/ をバック担当が触った) |
| B | 自分のフォルダだけの PR を、承認の人数 0 + 担当の承認必須の設定で、作者 1 人で merge できるか | **できた**。依頼 0・承認 0 で merge ボタンが押せた | PR #9 (backend/) / PR #10 (frontend/) |
| C | main が進んだ後の古い branch は、最新を取り込むまで merge が止まるか (ルール 6) | **止まった**。「This branch is out-of-date with the base branch」→ Update branch → 検査が走り直し → merge | PR #8 / PR #9 |
| D | 契約だけの PR → 対の issue → 各 PC で実装 → 繋ぐ、を通した時、`contract/` 以外でぶつかる場所が出るか | **出なかった** (ダミーの 1 機能。実案件で再確認) | PR #7 → #10 → #9 |
| E | PR ごとの検査 (案 1) が、重なりを測って知らせられるか | **赤になった**。他の open な PR と同じファイルで `check` = FAILURE、merge が止まった。issue の見込みとの比較も動いた | PR #13 (vs #12) |
| F | 案 3 を各自の Claude に頼んだ時、相手の issue の「触る見込み」を拾って書けるか | **書けた**。open な PR と issue を読み、重なり (フォルダ単位の見込みと) を issue にコメント | issue #11 |
| G | 案 2 (GitHub の中の Claude) が PR を読んでコメントするか | **動いた**。差分・他の PR・open な issue の見込み・契約との食い違いを読んでコメント | PR #8 以降の全 PR |

## 検証で分かった事 (v0 → v1 の差分)

- 見込みは**ファイル単位**で書く (ルール 4)。`frontend/` のようにフォルダで書くと、その下の全部と重なって見える (案 1 の検査は前方一致、案 3 の Claude も同じ読み方をした)
- PR に **`Closes #番号`** を書く (ルール 8)。無いと issue が open のまま残り、終わった作業の見込みが重なりとして出続ける (F で実際に起きた)
- 作業中は早めに **Draft PR** で出す (ルール 5)。ローカルの作業は検査にも Claude にも見えない。Draft も open な PR なので検査は見る。Draft には担当へのレビュー依頼が飛ばない (GitHub の公式ドキュメント)
- 承認の形は**チームの選択**。「承認の人数 0 + 担当の承認」= 自分のフォルダは 1 人で merge (検証した形) / 「承認 1 人以上」を足す = 全 PR を互いに見る。設定 1 つで切り替えられる
- 案 2 の secret は `/install-github-app` (Claude Code の Quick setup) で入れる。手で貼ると中身が欠けて動かない事があった (1 回目の失敗の原因)。`gh` に `workflow` の権限が要る

## まだ決めていないこと

- 共有ファイル (依存の一覧・設定・共通の型) の置き場と担当。ダミーでは出なかったので、実案件で出た場所から決める
- 契約を何で書くか (OpenAPI など)。実案件の技術の構成が決まってから
- 案 2 を使う時、Claude の利用分を誰の契約にするか (個人のサブスク枠 / 会社の API キー)
- 整形ツールの設定を repo に入れて 2 台で揃えるか (出典なしの実務の案)

## 出典 (ルール 3・5・6 の根拠)

- 契約を実装より先に書く: OpenAPI Initiative "Best Practices" https://learn.openapis.org/best-practices.html
- branch は 2 日以内: DORA "Working in small batches" https://dora.dev/capabilities/working-in-small-batches/
- 同時に開く branch は 3 本以下: DORA "Trunk-based development" https://dora.dev/capabilities/trunk-based-development/
- PR は小さく、1 つの目的に (「目安 100 行」はチームの決め): GitHub Docs "Helping others review your changes" https://docs.github.com/en/pull-requests/concepts/helping-others-review-your-changes
- main の最新を取り込んでから merge は merge queue と同じ利点: GitHub Docs "Managing a merge queue" https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue
- CODEOWNERS / Draft には依頼が飛ばない: GitHub Docs "About code owners" https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- 案 2 の認証と費用: Claude Code Docs "GitHub Actions" https://code.claude.com/docs/en/github-actions
- Actions の分数: GitHub Docs "GitHub Actions billing" https://docs.github.com/en/billing/concepts/product-billing/github-actions
