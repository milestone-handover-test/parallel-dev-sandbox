#!/usr/bin/env bash
# frontend/format-message.sh の試験。`bash frontend/test-format-message.sh` で全部流す。
# 落ちた場合が 1 つでもあれば rc 1 で終わる。道具を入れずに 2 台で同じに走らせるため、bash だけで書く。

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$here/format-message.sh"

pass=0
fail=0

check() {
  local name="$1" input="$2" want="$3" got
  got=$(format_message "$input")
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'ok   %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n' "$name"
    printf '     want: %q\n' "$want"
    printf '     got:  %q\n' "$got"
  fi
}

check "普通の文字列はそのまま出る" "hello" "hello"
check "前後の空白が落ちる" $'  \thello world\t  ' "hello world"
check "改行が空白 1 つになる" $'hello\nworld' "hello world"

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
