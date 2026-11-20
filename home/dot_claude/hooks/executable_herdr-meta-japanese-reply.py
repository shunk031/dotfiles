#!/usr/bin/env python3
"""Block non-Japanese final replies from the Meta Claude session."""

from __future__ import annotations

import json
import os
import re
import shlex
import subprocess
import sys
import unicodedata

BLOCK_REASON = "Reply to the user in Japanese; rewrite the whole reply in Japanese."
PANE_PATTERN = re.compile(r"^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$")
FENCE_OPEN = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
FENCE_CLOSE = re.compile(r"^ {0,3}(`+|~+)[ \t]*$")
INLINE_CODE = re.compile(r"(?<!`)(`+)(?!`)[\s\S]*?(?<!`)\1(?!`)")
URL = re.compile(
    r"\b(?:[A-Za-z][A-Za-z0-9+.-]*://|mailto:|www\.)[^\s<>]+", re.IGNORECASE
)
UNIX_PATH = re.compile(r"(?<![\w:])(?:~|\.{1,2})?/(?:[^\s<>\"'`]+)")
WINDOWS_PATH = re.compile(r"\b[A-Za-z]:\\(?:[^\\\s<>\"'`]+\\?)+")
RELATIVE_PATH = re.compile(
    r"(?<![\w./-])(?:"
    r"(?:\.\.?|~)/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_.-]+)*"
    r"|[A-Za-z0-9_.-]+/(?:[A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+"
    r"\.(?:py|sh|md|txt|json|jsonl|toml|yaml|yml|ini|cfg|conf|html|css|js|ts|tsx|jsx|go|rs|rb|java|c|cc|cpp|h|hpp)"
    r")(?![\w./-])",
    re.IGNORECASE,
)
FILE_NAME = re.compile(
    r"(?<![\w./-])[A-Za-z0-9_.-]+\.(?:py|sh|md|txt|json|jsonl|toml|yaml|yml|"
    r"ini|cfg|conf|html|css|js|ts|tsx|jsx|go|rs|rb|java|c|cc|cpp|h|hpp)(?![\w./-])",
    re.IGNORECASE,
)
COMMAND_LINE = re.compile(
    r"^\s*(?:(?:[-*+]\s+|\d+[.)]\s+))?(?:(?P<prompt>[$%❯➜])\s*)?"
    r"(?P<command>[^\s]+)(?P<arguments>(?:\s+.*)?)$"
)
COMMAND_SUBCOMMANDS = {
    "git": {
        "add", "branch", "checkout", "cherry-pick", "clean", "clone", "commit",
        "diff", "fetch", "init", "log", "merge", "mv", "pull", "push", "rebase",
        "remote", "reset", "restore", "revert", "rm", "show", "status", "switch",
        "tag", "worktree",
    },
    "gh": {"api", "auth", "browse", "issue", "pr", "repo", "run", "workflow"},
    "go": {"build", "env", "fmt", "generate", "get", "install", "list", "mod", "run", "test", "vet", "version"},
    "docker": {"build", "compose", "exec", "image", "images", "logs", "ps", "pull", "push", "rm", "run", "start", "stop"},
    "herdr": {"agent", "pane", "tab", "workspace"},
    "mise": {"activate", "exec", "install", "ls", "prune", "tool", "trust", "use", "x"},
    "npm": {"audit", "ci", "install", "link", "list", "outdated", "publish", "run", "test", "uninstall", "update", "version"},
    "op": {"document", "item", "read", "vault"},
    "pip": {"freeze", "install", "list", "show", "uninstall"},
    "pipx": {"install", "run", "uninstall", "upgrade"},
    "cargo": {"build", "check", "clean", "fmt", "install", "run", "test", "update"},
    "uv": {"add", "build", "cache", "export", "lock", "pip", "python", "remove", "run", "sync", "tool", "venv"},
    "brew": {"info", "install", "list", "search", "uninstall", "update", "upgrade"},
}
MAKE_TARGETS = {"all", "build", "check", "clean", "format", "install", "lint", "setup", "test"}
COMMAND_NAMES = {
    "awk", "bash", "brew", "cat", "cd", "cargo", "chown", "chmod", "command",
    "cp", "date", "docker", "echo", "env", "exec", "export", "find", "gcc", "gh",
    "git", "go", "grep", "herdr", "jq", "ls", "make", "mkdir", "mise", "mv", "node",
    "npm", "npx", "op", "pip", "pipx", "printf", "pwd", "pytest", "python", "rg",
    "rm", "rustc", "scp", "sed", "set", "sh", "source", "ssh", "sudo", "tar", "touch",
    "unzip", "uv", "wget", "zsh", "zip",
}
META_AGENT_LIST_TIMEOUT = 3


def remove_verbatim_markers(text: str) -> str:
    return re.sub(
        r"(?s)---BEGIN---.*?(?:---END---|\Z)",
        " ",
        text,
    )


def remove_fenced_code(text: str) -> str:
    visible: list[str] = []
    fence: tuple[str, int] | None = None
    for line in text.splitlines():
        if fence:
            closing = FENCE_CLOSE.fullmatch(line)
            if (
                closing
                and closing.group(1)[0] == fence[0]
                and len(closing.group(1)) >= fence[1]
            ):
                fence = None
            continue

        opening = FENCE_OPEN.match(line)
        if opening and (opening.group(1)[0] != "`" or "`" not in opening.group(2)):
            fence = (opening.group(1)[0], len(opening.group(1)))
            continue
        visible.append(line)
    return "\n".join(visible)


def is_path_argument(value: str) -> bool:
    return (
        value in {".", ".."}
        or value.startswith(("/", "./", "../", "~/", ".\\"))
        or "\\" in value
        or bool(FILE_NAME.fullmatch(value))
        or bool(RELATIVE_PATH.fullmatch(value))
        or bool(URL.fullmatch(value))
    )


def is_command_line(line: str) -> bool:
    match = COMMAND_LINE.fullmatch(line)
    if match is None:
        return False

    command = match.group("command")
    raw_arguments = (match.group("arguments") or "").strip()
    try:
        arguments = shlex.split(raw_arguments)
    except ValueError:
        return False

    if match.group("prompt") is not None:
        return True
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", command):
        return True
    assignments = []
    while arguments and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", arguments[0]):
        assignments.append(arguments.pop(0))
    if assignments:
        return True
    if arguments and arguments[0].startswith("--"):
        return True

    if command in COMMAND_SUBCOMMANDS:
        return bool(arguments and arguments[0] in COMMAND_SUBCOMMANDS[command])
    if command.startswith("herdr-"):
        return bool(arguments and arguments[0] in {"add", "list", "show", "status"})
    if command == "make":
        return bool(arguments and arguments[0] in MAKE_TARGETS)
    if command == "set":
        return bool(
            arguments
            and (
                arguments[0].startswith(("-", "+"))
                or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", arguments[0])
            )
        )
    if command == "export":
        return bool(
            arguments
            and (
                arguments[0] in {"-f", "-n"}
                or re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", arguments[0])
            )
        )
    if command == "source":
        return bool(arguments and is_path_argument(arguments[0]))
    if command == "find":
        return bool(
            len(arguments) > 1
            and is_path_argument(arguments[0])
            and arguments[1].startswith("-")
        )
    if command.startswith("python") or command == "node":
        return bool(
            arguments
            and (
                arguments[0].startswith("-")
                or is_path_argument(arguments[0])
            )
        )
    if command in {"date", "pwd"}:
        return not arguments or arguments[0].startswith(("-", "+"))
    if command == "ls":
        return not arguments or arguments[0].startswith("-") or is_path_argument(arguments[0])
    if command == "cd":
        return bool(arguments and is_path_argument(arguments[0]))
    if command == "cat":
        return bool(
            arguments
            and (
                arguments[0].startswith("-")
                or is_path_argument(arguments[0])
                or arguments[0].upper() in {"LICENSE", "MAKEFILE", "README"}
            )
        )
    if command == "echo":
        return any(character in raw_arguments for character in "'\"$|;&<>")
    if command in {"command", "exec", "sudo"}:
        return bool(
            arguments
            and (
                arguments[0].startswith("-")
                or arguments[0] in COMMAND_SUBCOMMANDS
                or arguments[0] in {"python", "python3", "bash", "sh", "zsh"}
            )
        )
    if command == "env":
        return bool(
            arguments
            and (
                arguments[0].startswith("-")
                or arguments[0] in COMMAND_NAMES
            )
        )

    if not arguments:
        return command in {"date", "ls", "pwd"} or is_path_argument(command)

    has_shell_syntax = (
        any(argument.startswith("-") for argument in arguments)
        or any(is_path_argument(argument) for argument in arguments)
        or any("=" in argument for argument in arguments)
        or any(character in raw_arguments for character in "'\"$|;&<>")
    )
    if command in {"mkdir", "rm", "cp", "mv", "chown", "ssh", "scp"}:
        return True
    if command == "chmod":
        return has_shell_syntax or bool(re.match(r"^\d{3,4}$", arguments[0]))
    if command == "touch":
        return has_shell_syntax
    if command == "pytest":
        return has_shell_syntax or arguments[0] in {"test", "tests"}
    if command in {"npx", "wget", "jq", "rustc", "gcc", "printf", "tar", "zip", "unzip"}:
        return has_shell_syntax

    command_is_executable = (
        command in COMMAND_NAMES
        or bool(re.fullmatch(r"python\d+(?:\.\d+)*", command))
        or bool(re.search(r"[./_\d-]", command))
    )
    return command_is_executable and has_shell_syntax


def visible_prose(message: str) -> str:
    text = remove_fenced_code(remove_verbatim_markers(message))
    text = INLINE_CODE.sub(" ", text)
    text = "\n".join(line for line in text.splitlines() if not is_command_line(line))
    text = URL.sub(" ", text)
    text = UNIX_PATH.sub(" ", text)
    text = WINDOWS_PATH.sub(" ", text)
    text = RELATIVE_PATH.sub(" ", text)
    text = FILE_NAME.sub(" ", text)
    return text


def is_japanese_letter(character: str) -> bool:
    if not character.isalpha():
        return False
    codepoint = ord(character)
    if (
        0x3040 <= codepoint <= 0x30FF
        or 0x31F0 <= codepoint <= 0x31FF
        or 0xFF66 <= codepoint <= 0xFF9D
    ):
        return True
    name = unicodedata.name(character, "")
    return name.startswith(
        ("HIRAGANA", "KATAKANA", "CJK UNIFIED IDEOGRAPH", "CJK COMPATIBILITY IDEOGRAPH")
    )


def should_block(message: str) -> bool:
    letters = [character for character in visible_prose(message) if character.isalpha()]
    if len(letters) < 40:
        return False
    japanese = sum(is_japanese_letter(character) for character in letters)
    return japanese * 10 < len(letters) * 3


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError("duplicate JSON key")
    return result


def reject_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant {value}")


def evaluate(payload: object) -> dict[str, str] | None:
    if not isinstance(payload, dict) or payload.get("hook_event_name") != "Stop":
        return None
    if payload.get("stop_hook_active") is True:
        return None
    message = payload.get("last_assistant_message")
    if isinstance(message, str) and should_block(message):
        return {"decision": "block", "reason": BLOCK_REASON}
    return None


def is_meta_session() -> bool:
    if os.environ.get("HERDR_ENV") != "1":
        return False
    pane_id = os.environ.get("HERDR_PANE_ID", "")
    if not PANE_PATTERN.fullmatch(pane_id):
        return False
    try:
        result = subprocess.run(
            ["herdr", "agent", "list"],
            capture_output=True,
            check=False,
            text=True,
            timeout=META_AGENT_LIST_TIMEOUT,
        )
        if result.returncode != 0:
            return False
        document = json.loads(
            result.stdout,
            object_pairs_hook=unique_object,
            parse_constant=reject_constant,
        )
        agents = document.get("result", {}).get("agents")
        if not isinstance(agents, list):
            return False
        pane_rows = [
            row for row in agents if isinstance(row, dict) and row.get("pane_id") == pane_id
        ]
        return len(pane_rows) == 1 and pane_rows[0].get("name") == "meta"
    except Exception:
        return False


def main() -> None:
    try:
        payload = json.loads(sys.stdin.read(), parse_constant=reject_constant)
        if (
            not isinstance(payload, dict)
            or payload.get("hook_event_name") != "Stop"
            or payload.get("stop_hook_active") is True
        ):
            return
        result = evaluate(payload) if is_meta_session() else None
        if result is not None:
            print(json.dumps(result, ensure_ascii=False, separators=(",", ":")))
    except Exception:
        return


if __name__ == "__main__":
    main()
