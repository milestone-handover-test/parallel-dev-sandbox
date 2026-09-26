# hello の表示

契約 (contract/hello.md) から作ったモックを相手に、`message` を表示する。バックの実装を待たない。
- モックの形: `GET /hello` にステータス 200・`Content-Type: application/json` で `{ "message": "hello" }` を返す (`message` は空でない文字列)

## 表示用に整える決まり

受け取った `message` は、画面に出す前に `format_message` (`frontend/format-message.sh`) で 1 行に整える。上から順に当てる。

1. 空白類 (スペース・タブ・改行 LF / CR・VT・FF) が続く所は、何個でも空白 1 つにまとめる。Windows の改行 (`\r\n`) も空白 1 つになる
2. 前後の空白を落とす
3. 80 文字を超えたら、先頭 79 文字の後ろに `…` を付けて、合計 80 文字にする。80 文字ちょうどまでは切らない

- 空白とみなすのは上の ASCII の 6 つだけ。全角空白 (`　`) は文字として残す
- 文字数はバイトではなく文字で数える。呼ぶ側のロケールが `C` でも、関数の中だけ `C.UTF-8` に替えて数える (呼んだ側のロケールは変わらない)
- 確かめ方: `bash frontend/test-format-message.sh` (全部通れば rc 0)

(検証用のダミー。issue #5)
