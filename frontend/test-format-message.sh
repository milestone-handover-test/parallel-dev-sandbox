#!/usr/bin/env bash
# frontend/format-message.sh の試験。`bash frontend/test-format-message.sh` で全部流す。
# 落ちた場合が 1 つでもあれば rc 1 で終わる。道具を入れずに 2 台で同じに走らせるため、bash だけで書く。

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$here/format-message.sh"

pass=0
fail=0

# 4 つ目の引数にロケールを渡すと、そのロケールで呼ぶ (呼ぶ側のロケールに左右されないかを見るため)
check() {
  local name="$1" input="$2" want="$3" loc="${4:-}" got
  got=$(if [ -n "$loc" ]; then LC_ALL=$loc; fi; format_message "$input")
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

# 文字 $1 を $2 個並べる
repeat() {
  local out
  printf -v out '%*s' "$2" ''
  printf '%s' "${out// /$1}"
}

check "普通の文字列はそのまま出る" "hello" "hello"
check "前後の空白が落ちる" $'  \thello world\t  ' "hello world"
check "改行が空白 1 つになる" $'hello\nworld' "hello world"
check "続く改行はまとめて空白 1 つになる" $'hello\n\nworld' "hello world"
check "Windows の改行 (\\r\\n) も空白 1 つになる" $'hello\r\nworld' "hello world"
check "改行の前後の空白もまとめて空白 1 つになる" $'hello  \n\t world' "hello world"
check "全角空白は文字として残る" "こんにちは　世界" "こんにちは　世界"
check "80 文字ちょうどは切らない" "$(repeat a 80)" "$(repeat a 80)"
check "81 文字は先頭 79 文字 + … になる" "$(repeat a 81)" "$(repeat a 79)…"
check "空白をまとめた後の長さで切るかを決める" "$(repeat a 40)$(repeat ' ' 50)$(repeat b 39)" "$(repeat a 40) $(repeat b 39)"
check "日本語もバイトでなく文字で数える" "$(repeat あ 81)" "$(repeat あ 79)…"
check "呼ぶ側のロケールが C でも文字で数える" "$(repeat あ 81)" "$(repeat あ 79)…" C

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
