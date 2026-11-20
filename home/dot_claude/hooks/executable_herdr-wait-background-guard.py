#!/usr/bin/env python3
import json
import re
import sys

REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
BACKGROUND = re.compile(r"(?<![&>])&(?![&>])")


def main():
    try:
        payload = json.load(sys.stdin)
        tool_input = payload.get("tool_input", {})
        command = tool_input.get("command", "")
        if (payload.get("tool_name") == "Bash" and tool_input.get("run_in_background") is not True
                and isinstance(command, str) and "herdr agent wait" in command
                and BACKGROUND.search(QUOTED.sub("", command))):
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": REASON}}))
    except Exception:  # noqa: BLE001
        return


if __name__ == "__main__":
    main()
