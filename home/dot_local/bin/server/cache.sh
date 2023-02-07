#!/usr/bin/env bash

# for huggingface datasets
export HF_DATASETS_CACHE="${HOME%/}/.cache/huggingface/datasets"
export TRANSFORMERS_CACHE="${HOME%/}/.cache/huggingface/hub"
