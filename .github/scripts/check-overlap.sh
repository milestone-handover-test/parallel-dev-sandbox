#!/usr/bin/env bash
# PR ごとの検査 (案 1「機械の見張り」)。AI は使わない。
#
# 1. この PR が触るファイルと、他の open な PR が触るファイルの重なりを測る → 重なりがあれば失敗 (rc=1)
# 2. この PR に結びつく issue の「触る見込みのファイル」と、実際の差分を比べる → 見込みの外を触っていれば注意 (rc は変えない)
#
# 使い方: REPO=owner/name PR_NUMBER=N .github/scripts/check-overlap.sh
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
  fi
done
[ "$found" = 0 ] && echo "- 重なりは無い"
echo

echo "### 2. issue の「触る見込みのファイル」との比較"
echo
BODY=$(gh pr view "$PR_NUMBER" -R "$REPO" --json body,headRefName --jq '.body + "\n" + .headRefName')
ISSUE=$(printf '%s' "$BODY" | grep -oE '#[0-9]+|issue-?[0-9]+' | grep -oE '[0-9]+' | head -1 || true)
if [ -z "$ISSUE" ]; then
  echo "- PR の本文にも branch 名にも issue 番号が無いので、比べられない"
else
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
