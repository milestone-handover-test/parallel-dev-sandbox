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

# 弾く入力: 標準出力に何も出さず、標準エラーに理由を 1 行出して rc 2 で終わるかを見る
check_reject() {
  local name="$1" input="$2" out err rc
  out=$(format_count "$input" 2>/dev/null)
  rc=$?
  err=$(format_count "$input" 2>&1 >/dev/null)
  if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ -n "$err" ] && [[ $err != *$'\n'* ]]; then
    pass=$((pass + 1))
    printf 'ok   %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n' "$name"
    printf '     want: rc 2 / 標準出力は空 / 標準エラーに 1 行\n'
    printf '     got:  rc %s / 標準出力 %q / 標準エラー %q\n' "$rc" "$out" "$err"
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
check "マイナスの整数も数として区切る" "-1234" "-1,234"
check "桁数が 3 の倍数のマイナスは先頭にカンマを入れない" "-123" "-123"

check_reject "空は弾く" ""
check_reject "文字だけは弾く" "abc"
check_reject "数字の間に文字を含むと弾く" "12a4"
check_reject "小数は弾く" "1234.5"

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
