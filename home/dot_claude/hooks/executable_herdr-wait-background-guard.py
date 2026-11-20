#!/usr/bin/env python3
import json
import re
import subprocess
import sys

REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
BACKGROUND = re.compile(r"(?<![&>])&(?![&>])")


def prompts_meta(command):
    try: tree = json.loads(subprocess.run(["shfmt", "-ln", "bash", "--to-json"], input=command, text=True, capture_output=True, check=True).stdout)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError): return False
    def value(node): return "\0" if node.get("Type") in {"CmdSubst", "ParamExp", "ArithmExp", "ProcSubst"} else bytes(node["Value"], "utf8").decode("unicode_escape") if node.get("Dollar") else re.sub(r"\\(.)", r"\1", node["Value"]) if node.get("Type") == "Lit" else node.get("Value", "".join(value(part) for part in node.get("Parts", [])))
    def is_meta(target):
        if target == "meta": return True
        try: return any(a.get("name") == "meta" and a.get("pane_id") == target for a in json.loads(subprocess.run(["herdr", "agent", "list"], text=True, capture_output=True, check=True).stdout)["result"]["agents"] if isinstance(a, dict))
        except (OSError, subprocess.SubprocessError, ValueError, KeyError, TypeError): return False
    def direct(args):
        args = [value(arg) for arg in args]
        wrapped = bool(args and args[0].rsplit("/", 1)[-1] in {"env", "command"})
        if not wrapped and (not args or args[0] != "herdr"): return False
        words = re.sub(r"['\"]", "", " ".join(args[1:] if wrapped else args)).replace("=", " ").split()
        return is_meta(match.group("target")) if (match := re.search(r"(?<!\S)herdr(?:\s+(?:--machine\s+\S+|--?\S+))*\s+agent(?:\s+(?:--machine\s+\S+|--?\S+))*\s+prompt(?:\s+(?:--machine\s+\S+|--?\S+))*\s+(?P<target>\S+)", " ".join(words))) else False
    def visit(node):
        if isinstance(node, dict):
            if node.get("Type") in {"FuncDecl", "TimeClause"}: return False
            if node.get("Type") == "CallExpr" and direct(node.get("Args", [])): return True
            return any(visit(item) for item in node.values())
        return any(visit(item) for item in node) if isinstance(node, list) else False
    return visit(tree)


def main():
    try:
        payload = json.load(sys.stdin)
        tool_input = payload.get("tool_input", {})
        command = tool_input.get("command", "")
        if payload.get("tool_name") == "Bash" and isinstance(command, str) and prompts_meta(command): print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "meta is reached via herdr-meta-patrol-queue add"}}))
        elif payload.get("tool_name") == "Bash" and tool_input.get("run_in_background") is not True and isinstance(command, str) and "herdr agent wait" in command and BACKGROUND.search(QUOTED.sub("", command)):
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": REASON}}))
    except Exception:  # noqa: BLE001
        return


if __name__ == "__main__":
    main()
