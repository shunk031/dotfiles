#!/usr/bin/env bash

# @file home/dot_local/bin/server/cache.sh
# @brief Export Hugging Face cache locations for server environments.
# @description
#   Sets the dataset and model cache directories under the user's home cache
#   directory for Hugging Face tooling.

# for huggingface datasets
export HF_DATASETS_CACHE="${HOME%/}/.cache/huggingface/datasets"
export TRANSFORMERS_CACHE="${HOME%/}/.cache/huggingface/hub"
