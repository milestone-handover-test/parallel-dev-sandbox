#!/usr/bin/env bash
# 使い方: この file を source してから format_message "<文字列>" を呼ぶと、整えた 1 行が標準出力に出る。
# バックから受け取った message (contract/hello.md) を、画面に出す前に表示用の 1 行に整える。
# いま実装しているのは「前後の空白を落とす」だけ (issue #36)。

format_message() {
  local s="$1"
  # 前後の空白 (スペース・タブ・改行) を落とす
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s\n' "$s"
}
