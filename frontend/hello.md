# hello の表示

契約 (contract/hello.md) から作ったモックを相手に、`message` を表示する。バックの実装を待たない。
- モックの形: `GET /hello` にステータス 200・`Content-Type: application/json` で `{ "message": "hello" }` を返す (`message` は空でない文字列)

(検証用のダミー。issue #5)
