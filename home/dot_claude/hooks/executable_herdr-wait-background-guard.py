#!/usr/bin/env python3
import json
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

REASON = "Run `herdr agent wait <worker>` alone with run_in_background: true; a backgrounded wait inside a foreground call never notifies you."
META_REASON = "meta is reached via herdr-meta-patrol-queue add"
QUOTED = re.compile(r"'[^']*'|\"[^\"]*\"")
BACKGROUND = re.compile(r"(?<![&>])&(?![&>])")


def prompts_meta(command):
    try:
        tree = json.loads(subprocess.run(["shfmt", "-ln", "bash", "--to-json"], input=command, text=True, capture_output=True, check=True).stdout)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        return False
    pane_ids = {p.name.rsplit(".", 2)[0] for p in ((Path(os.environ["HERDR_META_PATROL_STATE_DIR"]) if os.environ.get("HERDR_META_PATROL_STATE_DIR") else Path.home() / ".local" / "state" / "herdr-meta-patrol") / "waiters").glob("*.pid")}
    def value(node): return "\0" if node.get("Type") in {"CmdSubst", "ParamExp", "ArithmExp", "ProcSubst"} else bytes(node["Value"], "utf8").decode("unicode_escape") if node.get("Dollar") else re.sub(r"\\(.)", r"\1", node["Value"]) if node.get("Type") == "Lit" else node.get("Value", "".join(value(part) for part in node.get("Parts", [])))
    def env_command(args):
        i = 1
        while i < len(args):
            arg = args[i]
            if arg == "--":
                i += 1
                break
            if arg == "-S": return env_command(["env", *shlex.split(args[i + 1]), *args[i + 2:]]) if i + 1 < len(args) else []
            if arg in {"-u", "--unset", "-C", "--chdir", "-P", "--path"}: i += 2
            elif arg.startswith(("--unset=", "--chdir=", "--path=")): i += 1
            elif arg.startswith("-") and arg != "-": i += 1
            else: break
        while i < len(args) and re.match(r"^[^=]+=", args[i]): i += 1
        return args[i:]
    def direct(args):
        args = [value(arg) for arg in args]
        while args and Path(args[0]).name in {"env", "command"}:
            prefix = Path(args.pop(0)).name
            if prefix == "command" and args[:1] in (["-v"], ["-V"]): return False
            if prefix == "command": args = args[1:] if args[:1] == ["--"] else args
            else: args = env_command(["env", *args])
        if args[:1] != ["herdr"]: return False
        args = args[1:]; args = args[2:] if args[:1] == ["--machine"] else args[1:] if args[:1] and args[0].startswith("--machine=") else args
        return args[:2] == ["agent", "prompt"] and len(args) > 2 and args[2] in {"meta", *pane_ids}
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
        if payload.get("tool_name") == "Bash" and isinstance(command, str) and prompts_meta(command): print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": META_REASON}}))
        elif payload.get("tool_name") == "Bash" and tool_input.get("run_in_background") is not True and isinstance(command, str) and "herdr agent wait" in command and BACKGROUND.search(QUOTED.sub("", command)):
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": REASON}}))
    except Exception:  # noqa: BLE001
        return


if __name__ == "__main__":
    main()
