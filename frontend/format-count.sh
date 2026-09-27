#!/usr/bin/env bash
# 使い方: この file を source してから format_count "<件数>" を呼ぶと、整えた文字列が標準出力に出る。
# 画面に件数 (例: いいねの数) を出す前に、3 桁ごとにカンマを入れた表示用の文字列に整える (issue #38)。
# 整数でない入力は標準出力に何も出さず、標準エラーに「format_count: 整数ではない」を出して rc 2 で終わる。
# 決まりは frontend/count.md の「表示用に整える決まり」。

# 本体を ( ) で囲み、中の変数が呼んだ側に漏れないようにする
format_count() (
  s="$1"
  out=""

  # 符号と数字に分ける
  sign=""
  digits="$s"
  if [ "${s:0:1}" = "-" ]; then
    sign="-"
    digits="${s:1}"
  fi

  # 受け付けるのは「先頭に - が 0 か 1 個 + 半角の数字 1 個以上」だけ。
  # [0-9] は範囲の解釈がロケールで変わりうるので、数字を 10 個並べて書く
  case "$digits" in
    "" | *[!0123456789]*)
      printf '%s\n' "format_count: 整数ではない" >&2
      exit 2
      ;;
  esac

  # 先頭の 0 を外す (0,007 にしないため)。0 だけが並んでいた時は 0 を残す
  digits="${digits#"${digits%%[!0]*}"}"
  if [ -z "$digits" ]; then
    digits=0
  fi

  # -0 は 0 にする
  if [ "$digits" = 0 ]; then
    sign=""
  fi

  # 数として足し算・割り算をせず、文字列のまま右から 3 桁ずつ切り出して、間にカンマを挟む
  while [ "${#digits}" -gt 3 ]; do
    out=",${digits: -3}$out"
    digits="${digits:0:${#digits}-3}"
  done

  printf '%s\n' "$sign$digits$out"
)
