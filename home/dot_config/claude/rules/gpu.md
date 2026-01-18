このルールを使用するときには、回答時に 🧩 の絵文字をつけてください。

## GPU 使用を伴う Python スクリプト実行について

`torch` を使ったスクリプトを実行する場合、大抵は GPU を使用します。
そのようなスクリプトを実行する場合は環境変数の `CUDA_VISIBLE_DEVICES` を指定して実行してください。
例えば 0 番目の GPU を指定して以下のように実行します。

```shell
CUDA_VISIBLE_DEVICES=0 uv run main.py
```

適宜 `nvidia-smi` コマンドなどを使って使用されていない GPU を探して `CUDA_VISIBLE_DEVICES` を実行するようにしてください。
