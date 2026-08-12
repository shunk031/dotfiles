# RTK - Rust Token Killer (Codex CLI)

Usage: Token-optimized CLI proxy for shell commands.

## Rule

Always prefix shell commands with `rtk`.

Examples:

    rtk git status
    rtk cargo test
    rtk npm run build
    rtk pytest -q

## Meta Commands

    rtk gain            # Token savings analytics
    rtk gain --history  # Recent command usage with savings
    rtk proxy <cmd>     # Run raw command without filtering

## Verification

    rtk --version
    rtk gain
    which rtk
