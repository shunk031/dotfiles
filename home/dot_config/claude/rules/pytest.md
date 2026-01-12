---
paths: tests/**/*.py
---

このルールを使用するときには、回答時に 🐍 の絵文字をつけてください。

## GPU を使用したテスト

- GPU を使用したテストを書く場合、CPU を主に利用する CI 環境では以下のような コードスニペットを使用して、GPU が利用可能な場合にのみテストを実行してください。

```python
import pytest
import torch

@pytest.mark.skipif(
    not torch.cuda.is_available(),
    reason="No GPUs available for testing.",
)
def test_gpu_functionality():
    # GPU を使用したテストコード
    ...
```
