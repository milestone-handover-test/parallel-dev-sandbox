#!/usr/bin/env bash
# frontend/format-ago.sh の試験。`bash frontend/test-format-ago.sh` で全部流す。
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

printf '\n通った: %d / 落ちた: %d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
