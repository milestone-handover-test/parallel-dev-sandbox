#!/usr/bin/env bash
# PR ごとの検査 (案 1「機械の見張り」)。AI は使わない。
#
# 1. この PR が触るファイルと、他の open な PR が触るファイルの重なりを測る → 重なりがあれば失敗 (rc=1)
# 2. この PR に結びつく issue の「触る見込みのファイル」と、実際の差分を比べる → 見込みの外を触っていれば注意 (rc は変えない)
#
# 使い方: REPO=owner/name PR_NUMBER=N .github/scripts/check-overlap.sh
#   OVERLAP_OUT=<ファイル> を渡すと、重なった相手の PR 番号と重なったファイルを 1 行ずつ (番号<TAB>ファイル,ファイル) そこに書く。workflow が相手の PR に知らせるのに使う
# 出力: 標準出力に報告 (Markdown)。workflow はこれを PR のコメントに貼る。
set -u

: "${REPO:?REPO (owner/name) が要る}"
: "${PR_NUMBER:?PR_NUMBER が要る}"

files_of_pr() {
  gh api "repos/$REPO/pulls/$1/files" --paginate --jq '.[].filename' | sort -u
}

MY_FILES=$(files_of_pr "$PR_NUMBER")
rc=0
echo "## 見張りの結果 (PR #$PR_NUMBER)"
echo
echo "### 1. 他の open な PR との重なり"
echo
found=0
for other in $(gh pr list -R "$REPO" --state open --json number --jq '.[].number'); do
  [ "$other" = "$PR_NUMBER" ] && continue
  OTHER_FILES=$(files_of_pr "$other")
  common=$(comm -12 <(echo "$MY_FILES") <(echo "$OTHER_FILES"))
  if [ -n "$common" ]; then
    found=1
    rc=1
    echo "- **PR #$other と重なる**:"
    echo "$common" | sed 's/^/  - `/; s/$/`/'
    if [ -n "${OVERLAP_OUT:-}" ]; then
      printf '%s\t%s\n' "$other" "$(echo "$common" | paste -sd, -)" >> "$OVERLAP_OUT"
    fi
  fi
done
[ "$found" = 0 ] && echo "- 重なりは無い"
echo

echo "### 2. issue の「触る見込みのファイル」との比較"
echo
# 比べる issue は、確かな順に 3 つの手で探す
#   1. この PR が閉じる issue (本文の「Closes #番号」など、GitHub が PR と結びつけた物)
#   2. branch 名の issue-番号
#   3. 本文に出る番号のうち、issue である物の最初の 1 つ (「対になる issue #16」のような別の issue を拾うことがあるので、推定と書く)
ISSUE=$(gh pr view "$PR_NUMBER" -R "$REPO" --json closingIssuesReferences --jq '.closingIssuesReferences[0].number // empty')
HOW="この PR が閉じる issue"
if [ -z "$ISSUE" ]; then
  HEAD=$(gh pr view "$PR_NUMBER" -R "$REPO" --json headRefName --jq .headRefName)
  ISSUE=$(printf '%s' "$HEAD" | grep -oE 'issue-?[0-9]+' | grep -oE '[0-9]+' | head -1)
  HOW="branch 名の issue 番号"
fi
if [ -z "$ISSUE" ]; then
  BODY=$(gh pr view "$PR_NUMBER" -R "$REPO" --json body --jq .body)
  for n in $(printf '%s' "$BODY" | grep -oE '#[0-9]+' | grep -oE '[0-9]+' | awk '!seen[$0]++'); do
    if [ "$(gh api "repos/$REPO/issues/$n" --jq 'if .pull_request then "pr" else "issue" end' 2>/dev/null)" = "issue" ]; then
      ISSUE=$n
      HOW="本文に出る最初の issue 番号。推定なので、PR の本文に「Closes #番号」を書くと確かになる"
      break
    fi
  done
fi
if [ -z "$ISSUE" ]; then
  echo "- この PR が閉じる issue (「Closes #番号」) も、branch 名や本文の issue 番号も無いので、比べられない"
else
  echo "- 比べた issue: #$ISSUE ($HOW)"
  DECLARED=$(gh issue view "$ISSUE" -R "$REPO" --json body --jq .body \
    | awk '/^## 触る見込みのファイル/{f=1; next} /^## /{f=0} f' \
    | grep -oE '^- *`?[^` ]+`?' | sed 's/^- *//; s/`//g' | grep -v '^$' | sort -u || true)
  if [ -z "$DECLARED" ]; then
    echo "- issue #$ISSUE に「触る見込みのファイル」が書かれていない"
  else
    echo "- issue #$ISSUE の見込み:"
    echo "$DECLARED" | sed 's/^/  - `/; s/$/`/'
    outside=""
    while IFS= read -r f; do
      hit=0
      while IFS= read -r d; do
        case "$f" in "$d"|"$d"*|"${d%/}/"*) hit=1 ;; esac
      done <<< "$DECLARED"
      [ "$hit" = 0 ] && outside="$outside$f"$'\n'
    done <<< "$MY_FILES"
    if [ -n "$outside" ]; then
      echo "- **見込みの外を触っている** (注意。失敗にはしない):"
      printf '%s' "$outside" | sed 's/^/  - `/; s/$/`/'
    else
      echo "- 実際の差分は、見込みの中に収まっている"
    fi
  fi
fi
echo
echo "### この PR が触るファイル"
echo
echo "$MY_FILES" | sed 's/^/- `/; s/$/`/'
exit $rc
