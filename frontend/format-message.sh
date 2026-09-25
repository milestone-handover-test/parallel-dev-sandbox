#!/usr/bin/env bash
# バックから受け取った message (contract/hello.md) を、画面に出す前に表示用の 1 行に整える。
# 使い方: source してから format_message "<message>" を呼ぶ。整えた結果を標準出力に出す。
# いま実装しているのは「前後の空白を落とす」だけ (issue #36)。

format_message() {
  local s="$1"
  # 前後の空白 (スペース・タブ・改行) を落とす
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s\n' "$s"
}
