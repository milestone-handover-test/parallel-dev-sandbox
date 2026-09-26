#!/usr/bin/env bash
# 使い方: この file を source してから format_message "<文字列>" を呼ぶと、整えた 1 行が標準出力に出る。
# バックから受け取った message (contract/hello.md) を、画面に出す前に表示用の 1 行に整える (issue #36)。
# 決まりは frontend/hello.md の「表示用に整える決まり」。

# 本体を ( ) で囲み、中で替えるロケールが呼んだ側に漏れないようにする
format_message() (
  s="$1"
  max=80
  # 空白とみなすのは ASCII の 6 つだけ (スペース・タブ・LF・CR・VT・FF)。
  # [:space:] は UTF-8 だと全角空白にも当たり、ロケールで結果が変わるので使わない
  ws=$' \t\n\r\v\f'

  # 文字数を「文字」で数えるため、バイトで数えるロケール (C など) の時だけ UTF-8 に替える
  probe='…'
  [ "${#probe}" -eq 1 ] || LC_ALL=C.UTF-8

  # 空白類を全部空白にしてから、続く空白を 1 つにまとめる
  s="${s//[$ws]/ }"
  while [[ $s == *"  "* ]]; do
    s="${s//  / }"
  done

  # 前後の空白を落とす (まとめた後なので、それぞれ高々 1 つ)
  s="${s# }"
  s="${s% }"

  # 長ければ先頭 (max - 1) 文字 + … で、合計 max 文字にする
  if [ "${#s}" -gt "$max" ]; then
    s="${s:0:$((max - 1))}…"
  fi

  printf '%s\n' "$s"
)
