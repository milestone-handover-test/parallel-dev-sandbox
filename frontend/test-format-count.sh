#!/usr/bin/env bash
# frontend/format-count.sh の試験。`bash frontend/test-format-count.sh` で全部流す。
# 落ちた場合が 1 つでもあれば rc 1 で終わる。道具を入れずに 2 台で同じに走らせるため、bash だけで書く。

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$here/format-count.sh"

pass=0
fail=0

check() {
  local name="$1" input="$2" want="$3" got
  got=$(format_count "$input")
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

check "0 はそのまま出る" "0" "0"
check "1 桁はそのまま出る" "7" "7"
check "3 桁ちょうどはカンマを入れない" "999" "999"
check "4 桁で初めてカンマが入る" "1000" "1,000"
check "5 桁は先頭 2 桁の後にカンマ" "12345" "12,345"
check "6 桁は先頭 3 桁の後にカンマ" "123456" "123,456"
check "7 桁はカンマが 2 つ入る" "1234567" "1,234,567"
check "途中の 0 も桁として残る" "1000000" "1,000,000"

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
