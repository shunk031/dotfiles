---
paths: **/*.py
---

When using this rule, include the 🧩 emoji in your response.

## Running Python Scripts That Use a GPU

Scripts that use `torch` usually use a GPU.
When running such scripts, specify the `CUDA_VISIBLE_DEVICES` environment variable.
For example, select GPU 0 as follows:

```shell
CUDA_VISIBLE_DEVICES=0 uv run main.py
```

Use `nvidia-smi` or a similar command to find an unused GPU and set `CUDA_VISIBLE_DEVICES` accordingly.
