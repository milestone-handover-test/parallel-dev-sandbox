#!/usr/bin/env bash
# frontend/format-ago.sh の試験。`bash frontend/test-format-ago.sh` で全部流す。
# format-ago.sh はこの file の隣から読むので、repo の外から `bash <この file のパス>` で流しても同じ結果になる。
# 全部通れば rc 0、落ちた場合が 1 つでもあれば rc 1 で終わる。道具を入れずに 2 台で同じに走らせるため、bash だけで書く。

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. "$here/format-ago.sh"

pass=0
fail=0

check() {
  local name="$1" input="$2" want="$3" got
  got=$(format_ago "$input")
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

# 弾く入力: 標準出力に何も出さず、標準エラーに理由を 1 行 ($3) 出して rc 2 で終わるかを見る
check_reject() {
  local name="$1" input="$2" want_err="$3" out err rc
  out=$(format_ago "$input" 2>/dev/null)
  rc=$?
  err=$(format_ago "$input" 2>&1 >/dev/null)
  if [ "$rc" -eq 2 ] && [ -z "$out" ] && [ "$err" = "$want_err" ]; then
    pass=$((pass + 1))
    printf 'ok   %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL %s\n' "$name"
    printf '     want: rc 2 / 標準出力は空 / 標準エラー %s\n' "$want_err"
    printf '     got:  rc %s / 標準出力 %q / 標準エラー %q\n' "$rc" "$out" "$err"
  fi
}

not_int="format_ago: 整数ではない"
negative="format_ago: マイナスの数 (未来の時刻)"

# issue #40 の例
check "90 秒は 1 分前 (半端は切り捨てる)" "90" "1 分前"
check "7200 秒は 2 時間前" "7200" "2 時間前"

# 秒
check "0 秒は 0 秒前" "0" "0 秒前"
check "1 秒は 1 秒前" "1" "1 秒前"
check "59 秒までは秒で出す" "59" "59 秒前"

# 分
check "60 秒で初めて分になる" "60" "1 分前"
check "119 秒はまだ 1 分前" "119" "1 分前"
check "120 秒で 2 分前" "120" "2 分前"
check "3599 秒までは分で出す" "3599" "59 分前"

# 時間
check "3600 秒で初めて時間になる" "3600" "1 時間前"
check "7199 秒はまだ 1 時間前" "7199" "1 時間前"
check "86399 秒までは時間で出す" "86399" "23 時間前"

# 日
check "86400 秒で初めて日になる" "86400" "1 日前"
check "172799 秒はまだ 1 日前" "172799" "1 日前"
check "172800 秒で 2 日前" "172800" "2 日前"

# 数でない入力は弾く
check_reject "空は弾く" "" "$not_int"
check_reject "文字だけは弾く" "abc" "$not_int"
check_reject "数字の間に文字を含むと弾く" "12a4" "$not_int"
check_reject "小数は弾く" "1.5" "$not_int"
# 中のコマンドが走ると、標準エラーに「走った」が混ざって落ちる
check_reject "中のコマンドを走らせずに弾く" 'a[$(echo 走った >&2)]' "$not_int"
check_reject "+ の付いた数は弾く" "+123" "$not_int"
check_reject "前に空白があると弾く" " 12" "$not_int"
check_reject "後ろに空白があると弾く" "12 " "$not_int"
check_reject "全角の数字は弾く" "１２３" "$not_int"
check_reject "数字の間の - は弾く" "1-2" "$not_int"

# 先頭の 0 は外して読む ($(( )) に渡すと 8 進数として読まれて止まる)
check "先頭の 0 は外す" "0090" "1 分前"
check "0 だけが並んでいたら 0 秒前" "000" "0 秒前"
check "22 文字でも中身が 90 なら 1 分前" "0000000000000000000090" "1 分前"

# -0 は 0 として扱う (未来の時刻ではない)
check "-0 は 0 秒前" "-0" "0 秒前"
check "-000 も 0 秒前" "-000" "0 秒前"

# マイナスの数 (未来の時刻) は、数でない入力と文言を分けて弾く
check_reject "マイナスの整数は弾く" "-1" "$negative"
check_reject "issue の例のマイナスも弾く" "-90" "$negative"
check_reject "マイナスで先頭に 0 が付いても弾く" "-0090" "$negative"

# マイナスで整数でない物は「整数ではない」で弾く (整数かどうかを先に見る)
check_reject "マイナスの小数は整数ではない" "-1.5" "$not_int"
check_reject "- の後ろが文字なら整数ではない" "-abc" "$not_int"
check_reject "- だけは整数ではない" "-" "$not_int"
check_reject "- が 2 つは整数ではない" "--1" "$not_int"

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
