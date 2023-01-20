#!/usr/bin/env bash

# set -Eeuox pipefail

# for huggingface datasets
export HF_DATASETS_CACHE="${HOME%/}/.cache/huggingface/datasets"
export TRANSFORMERS_CACHE="${HOME%/}/.cache/huggingface/hub"
