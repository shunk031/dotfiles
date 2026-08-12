#!/usr/bin/env bash

# @file home/dot_config/antigravity-cli/hooks/rtk-hook-gemini.sh
# @brief Rewrite Gemini CLI shell commands through RTK.
# @description
#   Delegates Gemini CLI hook input to the installed RTK binary.

set -Eeuo pipefail

exec rtk hook gemini
