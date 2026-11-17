#!/usr/bin/env python3
"""Gate Meta's Claude Stop hook on patrol and worker lifecycle state."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time
import zlib


HERDR_TIMEOUT_SECONDS = 3
QUEUE_TIMEOUT_SECONDS = 3
PROCESS_TIMEOUT_SECONDS = 2
PANE_PATTERN = re.compile(r"^[A-Za-z0-9_-]+:[A-Za-z0-9_-]+$")
SESSION_PATTERN = re.compile(r"^[A-Za-z0-9_-]+$")
FINGERPRINT_PATTERN = re.compile(r"^[0-9]+$")
WORKER_STATUSES = {"working", "blocked", "idle", "done"}


class GateError(Exception):
    """A known post-identity condition that prevents reliable verification."""


def reject_constant(value: str) -> None:
    raise ValueError(f"invalid JSON constant {value}")


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key {key!r}")
        result[key] = value
    return result


def parse_json_document(text: str) -> object:
    """Parse exactly one strict JSON document, rejecting duplicate keys."""
    return json.loads(
        text,
        object_pairs_hook=unique_object,
        parse_constant=reject_constant,
    )


def emit(value: dict[str, object]) -> None:
    sys.stdout.write(json.dumps(value, separators=(",", ":"), ensure_ascii=False) + "\n")


def env_default(name: str, default: str) -> str:
    return os.environ.get(name) or default


def object_field(value: object, key: str) -> object:
    if not isinstance(value, dict):
        return None
    return value.get(key)


def run_command(arguments: list[str], timeout: int) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        arguments,
        capture_output=True,
        check=False,
        text=True,
        timeout=timeout,
    )


def identify_meta(pane_id: str) -> tuple[str, list[dict[str, object]]] | None:
    """Return the unique Meta terminal and agent rows, or fail open."""
    try:
        result = run_command(["herdr", "agent", "list"], HERDR_TIMEOUT_SECONDS)
        if result.returncode != 0:
            return None
        document = parse_json_document(result.stdout)
        agents = object_field(object_field(document, "result"), "agents")
        if not isinstance(agents, list):
            return None
        rows = [row for row in agents if isinstance(row, dict)]
        pane_rows = [row for row in rows if row.get("pane_id") == pane_id]
        if len(pane_rows) != 1 or pane_rows[0].get("name") != "meta":
            return None
        return pane_rows[0].get("terminal_id", ""), rows
    except Exception:
        return None


def add_error(errors: list[str], message: str, recovery: str) -> None:
    errors.append(f"gate cannot verify: {message}; recovery: {recovery}.")


def add_blocker(blockers: list[str], message: str, recovery: str) -> None:
    blockers.append(f"Meta must resolve: {message}; recovery: {recovery}.")


def reason_text(errors: list[str], blockers: list[str]) -> str:
    return " ".join([*errors, *blockers])


def is_regular_file(path: Path) -> bool:
    try:
        return not path.is_symlink() and stat.S_ISREG(path.lstat().st_mode)
    except FileNotFoundError:
        return False


def path_exists(path: Path) -> bool:
    return os.path.lexists(path)


def validate_queue_response(output: str) -> tuple[int, int]:
    response = parse_json_document(output)
    if not isinstance(response, dict) or set(response) != {
        "malformed_line_count",
        "unread_record_count",
    }:
        raise ValueError("strict queue response has an unexpected schema")
    malformed = response["malformed_line_count"]
    unread = response["unread_record_count"]
    if type(malformed) is not int or malformed < 0:
        raise ValueError("malformed_line_count must be a non-negative integer")
    if type(unread) is not int or unread < 0:
        raise ValueError("unread_record_count must be a non-negative integer")
    return malformed, unread


def queue_counts(queue_command: str) -> tuple[int, int]:
    try:
        result = run_command([queue_command, "read", "--strict"], QUEUE_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired as error:
        raise GateError("queue unverifiable: strict reader timed out") from error
    except Exception as error:
        raise GateError(f"queue unverifiable: strict reader failed: {error}") from error
    if result.returncode != 0:
        diagnostic = (result.stdout + result.stderr).strip()
        if not diagnostic:
            diagnostic = "strict reader failed without a diagnostic"
        if not diagnostic.startswith("queue unverifiable:"):
            diagnostic = f"queue unverifiable: strict reader failed: {diagnostic}"
        raise GateError(diagnostic)
    try:
        return validate_queue_response(result.stdout)
    except Exception as error:
        raise GateError(
            "the patrol queue returned an unparsable or malformed strict response"
        ) from error


def inspect_waiter(waiters_dir: Path, pane_id: str, blockers: list[str]) -> None:
    recovery = f"start 'herdr-meta-patrol-queue wait' as a background command in this session"
    if not PANE_PATTERN.fullmatch(pane_id):
        return
    if (
        waiters_dir.is_symlink()
        or not waiters_dir.is_dir()
        or not os.access(waiters_dir, os.R_OK | os.X_OK)
    ):
        raise GateError(
            f"the queue waiter directory is missing, unreadable, or malformed '{waiters_dir}'"
        )
    markers = sorted(waiters_dir.glob(f"{pane_id}.*.pid"))
    if not markers:
        add_blocker(blockers, "no queue waiter marker exists for this Meta pane", recovery)
        return
    found = False
    for marker in markers:
        if marker.is_symlink() or not is_regular_file(marker) or not os.access(marker, os.R_OK):
            raise GateError(
                f"waiter marker '{marker}' is not a readable regular file"
            )
        try:
            pid_text = marker.read_text(encoding="utf-8").strip()
        except OSError as error:
            raise GateError(f"waiter marker '{marker}' could not be read") from error
        if not re.fullmatch(r"[0-9]+", pid_text) or int(pid_text) <= 0:
            raise GateError(f"waiter marker '{marker}' has an invalid PID")
        pid = int(pid_text)
        try:
            os.kill(pid, 0)
        except OSError as error:
            raise GateError(f"waiter PID {pid} is not running") from error
        try:
            process = run_command(
                ["ps", "-ww", "-o", "command=", "-p", str(pid)],
                PROCESS_TIMEOUT_SECONDS,
            )
        except Exception as error:
            raise GateError(f"waiter PID {pid} could not be inspected") from error
        command = process.stdout.strip()
        if process.returncode != 0 or not command:
            raise GateError(f"waiter PID {pid} could not be inspected")
        if "herdr-meta-patrol-queue" in command and re.search(
            r"\swait(?:\s|$)", command
        ):
            found = True
        else:
            raise GateError(f"waiter PID {pid} is not running the queue wait command")
    if not found:
        add_blocker(blockers, "no live queue waiter exists for this Meta pane", recovery)


def read_lifecycle_records(
    state_dir: Path,
    owner_pane: str,
    owner_terminal: str,
    lifecycle_helper: Path,
) -> list[tuple[str, str, str, str]]:
    parent = state_dir.parent
    if (
        parent.is_symlink()
        or not parent.is_dir()
        or not os.access(parent, os.R_OK | os.X_OK)
    ):
        raise GateError(
            f"the worker lifecycle parent '{parent}' is missing or inaccessible; "
            f"recovery: restore it, then run '{lifecycle_helper} audit'"
        )
    if (
        state_dir.is_symlink()
        or not state_dir.is_dir()
        or not os.access(state_dir, os.R_OK | os.X_OK)
    ):
        raise GateError(
            f"the worker lifecycle registry directory '{state_dir}' is missing or malformed; "
            f"recovery: restore it, then run '{lifecycle_helper} audit'"
        )
    records_file = state_dir / "workers.tsv"
    if (
        records_file.is_symlink()
        or not is_regular_file(records_file)
        or not os.access(records_file, os.R_OK)
    ):
        raise GateError(
            f"the worker lifecycle registry '{records_file}' is missing or not a readable regular file; "
            f"recovery: restore the registry and run '{lifecycle_helper} audit'"
        )
    try:
        lines = records_file.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeError) as error:
        raise GateError(
            f"the worker lifecycle registry '{records_file}' could not be read; "
            f"recovery: repair it and run '{lifecycle_helper} audit'"
        ) from error
    pending: list[tuple[str, str, str, str]] = []
    for line in lines:
        fields = line.split("\t")
        if len(fields) != 9 or any(not field for field in fields):
            raise GateError(
                f"the worker lifecycle registry is unparsable or contains unexpected statuses; "
                f"recovery: repair '{records_file}', then run '{lifecycle_helper} audit'"
            )
        if fields[8] not in {"started", "collected"}:
            raise GateError(
                f"the worker lifecycle registry is unparsable or contains unexpected statuses; "
                f"recovery: repair '{records_file}', then run '{lifecycle_helper} audit'"
            )
        if fields[0] == "meta" and fields[1] == owner_pane and fields[2] == owner_terminal and fields[8] == "started":
            pending.append((fields[4], fields[5], fields[6], fields[7]))
    return pending


def check_workers(
    workers: list[tuple[str, str, str, str]],
    agents: list[dict[str, object]],
    lifecycle_helper: Path,
    blockers: list[str],
) -> None:
    for name, terminal, tab, pane in workers:
        matches = [
            row
            for row in agents
            if row.get("name") == name
            and row.get("terminal_id") == terminal
            and row.get("tab_id") == tab
            and row.get("pane_id") == pane
        ]
        if len(matches) != 1:
            raise GateError(f"worker '{name}' has no unique live Herdr match")
        status = matches[0].get("agent_status")
        if not isinstance(status, str):
            raise GateError(f"worker '{name}' has no readable Herdr status")
        if status not in WORKER_STATUSES:
            raise GateError(
                f"worker '{name}' has unexpected status '{status}'; "
                f"recovery: run 'herdr agent list' and '{lifecycle_helper} audit'"
            )
        add_blocker(
            blockers,
            f"worker '{name}' has an uncollected started lifecycle record (status {status})",
            f"inspect its transcript and result, then collect it with '{lifecycle_helper} collect {name}' when safe",
        )


def make_session_key(session_id: str, pane_id: str, valid_session: bool) -> str:
    if valid_session:
        identity = session_id
        prefix = ""
    else:
        identity = pane_id
        prefix = "pane-"
    return prefix + hashlib.sha256(identity.encode("utf-8")).hexdigest()


def prepare_state_dir(directory: Path) -> bool:
    try:
        if directory.is_symlink():
            return False
        directory.mkdir(parents=True, exist_ok=True)
        if directory.is_symlink() or not directory.is_dir():
            return False
        if not os.access(directory, os.R_OK | os.W_OK | os.X_OK):
            return False
        directory.chmod(0o700)
        return True
    except OSError:
        return False


def validate_retry_state(document: object, path: Path) -> tuple[str, int]:
    if not isinstance(document, dict) or set(document) != {
        "reason_fingerprint",
        "consecutive_blocks",
    }:
        raise GateError(
            f"retry state '{path}' is unparsable or malformed; "
            f"recovery: repair or remove '{path}', then retry the Stop hook"
        )
    fingerprint = document["reason_fingerprint"]
    count = document["consecutive_blocks"]
    if not isinstance(fingerprint, str) or not FINGERPRINT_PATTERN.fullmatch(fingerprint):
        raise GateError(
            f"retry state '{path}' is unparsable or malformed; "
            f"recovery: repair or remove '{path}', then retry the Stop hook"
        )
    if type(count) is not int or not 1 <= count <= 3:
        raise GateError(
            f"retry state '{path}' is unparsable or malformed; "
            f"recovery: repair or remove '{path}', then retry the Stop hook"
        )
    return fingerprint, count


def read_retry_state(path: Path, active: bool) -> tuple[str, int] | None:
    if path.is_symlink() or (path_exists(path) and not is_regular_file(path)):
        raise GateError(
            f"retry state '{path}' is not a readable regular file; "
            f"recovery: remove or repair '{path}', then retry the Stop hook"
        )
    if not path_exists(path):
        if active:
            raise GateError(
                "retry state is missing for an active Stop retry; "
                "recovery: start a fresh Claude turn after checking the patrol state"
            )
        return None
    if not os.access(path, os.R_OK):
        raise GateError(
            f"retry state '{path}' could not be read; recovery: repair '{path}'"
        )
    try:
        document = parse_json_document(path.read_text(encoding="utf-8"))
    except Exception as error:
        raise GateError(
            f"retry state '{path}' is unparsable or malformed; "
            f"recovery: repair or remove '{path}', then retry the Stop hook"
        ) from error
    return validate_retry_state(document, path)


def write_retry_state(directory: Path, session_key: str, fingerprint: str, count: int) -> Path:
    destination = directory / f"{session_key}.json"
    if destination.is_symlink() or (path_exists(destination) and not is_regular_file(destination)):
        raise OSError(f"retry state '{destination}' is not a regular file")
    payload = json.dumps(
        {"reason_fingerprint": fingerprint, "consecutive_blocks": count},
        separators=(",", ":"),
    ) + "\n"
    descriptor, temporary_name = tempfile.mkstemp(prefix=f"{session_key}.", suffix=".tmp", dir=directory)
    temporary = Path(temporary_name)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        if temporary.is_symlink() or not is_regular_file(temporary):
            raise OSError(f"temporary retry state '{temporary}' is not a regular file")
        os.replace(temporary, destination)
        if destination.is_symlink() or not is_regular_file(destination):
            raise OSError(f"retry state '{destination}' could not be verified")
    finally:
        try:
            temporary.unlink(missing_ok=True)
        except OSError:
            pass
    return destination


def audit_and_allow(log_file: Path, session_key: str, fingerprint: str) -> None:
    message = (
        "The Meta turn gate allowed this turn to end after blocking the same unresolved "
        "condition three times; inspect the patrol state before the next turn."
    )
    record = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "session_key": session_key,
        "reason_fingerprint": fingerprint,
        "consecutive_blocks": 3,
        "action": "allow",
    }
    try:
        if log_file.is_symlink() or (path_exists(log_file) and not is_regular_file(log_file)):
            raise OSError("audit path is not a regular file")
        with log_file.open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(record, separators=(",", ":")) + "\n")
            stream.flush()
            os.fsync(stream.fileno())
    except Exception:
        message = (
            "The Meta turn gate allowed this turn to end after three blocks; "
            f"audit log write failed: {log_file}. Inspect the patrol state before the next turn."
        )
    emit({"systemMessage": message})


def evaluate_after_identity(
    input_text: str,
    pane_id: str,
    owner_terminal: object,
    agents: list[dict[str, object]],
) -> None:
    errors: list[str] = []
    blockers: list[str] = []
    if not PANE_PATTERN.fullmatch(pane_id):
        add_error(
            errors,
            "the Meta pane ID has an invalid format",
            "run 'herdr agent list' and reconcile Meta's pane ownership",
        )

    payload: object
    try:
        payload = parse_json_document(input_text)
    except Exception:
        payload = None
    active = False
    active_valid = False
    session_id = ""
    session_valid = False
    if not isinstance(payload, dict):
        add_error(
            errors,
            "the Claude Stop payload is not a JSON object",
            "resume the Claude session and retry the Stop hook",
        )
        add_error(
            errors,
            "stop_hook_active is missing or invalid",
            "resume the Claude session and retry the Stop hook",
        )
        add_error(
            errors,
            "session_id is missing or is not a string",
            "resume the Claude session and retry the Stop hook",
        )
    else:
        active_value = payload.get("stop_hook_active")
        if type(active_value) is bool:
            active = active_value
            active_valid = True
        else:
            add_error(
                errors,
                "stop_hook_active is missing or invalid",
                "resume the Claude session and retry the Stop hook",
            )
        session_value = payload.get("session_id")
        if not isinstance(session_value, str):
            add_error(
                errors,
                "session_id is missing or is not a string",
                "resume the Claude session and retry the Stop hook",
            )
        elif not session_value:
            add_error(
                errors,
                "session_id is empty or could not be read",
                "resume the Claude session and retry the Stop hook",
            )
        elif not SESSION_PATTERN.fullmatch(session_value):
            add_error(
                errors,
                "session_id has an invalid format",
                "resume the Claude session and retry the Stop hook",
            )
        else:
            session_id = session_value
            session_valid = True

    if not isinstance(owner_terminal, str) or not owner_terminal:
        add_error(
            errors,
            "Meta has a missing, empty, or non-string terminal_id in the Herdr agent list",
            "run 'herdr agent list' and reconcile Meta's pane ownership",
        )
        terminal_id = ""
    else:
        terminal_id = owner_terminal

    home = Path(os.environ.get("HOME", str(Path.home())))
    queue_command = env_default(
        "HERDR_META_PATROL_QUEUE_COMMAND", "herdr-meta-patrol-queue"
    )
    try:
        malformed_count, unread_count = queue_counts(queue_command)
        if malformed_count > 0:
            add_error(
                errors,
                f"queue unverifiable: queue.jsonl contains {malformed_count} malformed or invalid record(s)",
                "run 'herdr-meta-patrol-queue read --strict' and repair the reported queue.jsonl lines before acknowledging records",
            )
        if unread_count > 0:
            add_blocker(
                blockers,
                "the patrol queue has unread records",
                "run 'herdr-meta-patrol-queue read', handle each record, then acknowledge the highest handled sequence",
            )
    except GateError as error:
        add_error(
            errors,
            str(error),
            "run 'herdr-meta-patrol-queue read --strict' and repair the reported queue state",
        )

    queue_state_dir = Path(
        env_default(
            "HERDR_META_PATROL_STATE_DIR",
            str(home / ".local" / "state" / "herdr-meta-patrol"),
        )
    )
    waiters_dir = queue_state_dir / "waiters"
    try:
        inspect_waiter(waiters_dir, pane_id, blockers)
    except GateError as error:
        add_error(
            errors,
            str(error),
            f"create '{waiters_dir}' and start 'herdr-meta-patrol-queue wait' in this pane",
        )

    lifecycle_helper = (
        home
        / ".agents"
        / "skills"
        / "shunk031-herdr-orchestrate-workers"
        / "scripts"
        / "herdr-worker-lifecycle.sh"
    )
    lifecycle_state = Path(
        env_default(
            "HERDR_WORKER_LIFECYCLE_STATE_DIR",
            str(
                Path(
                    env_default("XDG_STATE_HOME", str(home / ".local" / "state"))
                )
                / "herdr-worker-lifecycle"
            ),
        )
    )
    try:
        pending = read_lifecycle_records(
            lifecycle_state, pane_id, terminal_id, lifecycle_helper
        )
        check_workers(pending, agents, lifecycle_helper, blockers)
    except GateError as error:
        message = str(error)
        if "; recovery:" in message:
            base, recovery = message.split("; recovery:", 1)
            add_error(errors, base, recovery.strip().rstrip("."))
        else:
            add_error(
                errors,
                message,
                f"run 'herdr agent list' and '{lifecycle_helper} audit'",
            )

    reason = reason_text(errors, blockers)
    try:
        session_key = make_session_key(session_id, pane_id, session_valid)
    except Exception as error:
        raise GateError(
            "the retry session key could not be generated with SHA-256; "
            "recovery: repair the Python runtime and retry the Stop hook"
        ) from error
    fingerprint = str(zlib.crc32(reason.encode("utf-8")) & 0xFFFFFFFF)
    if not FINGERPRINT_PATTERN.fullmatch(fingerprint):
        raise GateError(
            "the retry reason fingerprint is empty or invalid; "
            "recovery: retry the Claude Stop hook"
        )

    try:
        uid = os.getuid()
        primary_dir = queue_state_dir / "stop-gate"
        fallback_dir = Path(env_default("TMPDIR", "/tmp")) / f"herdr-meta-turn-gate-{uid}"
        if prepare_state_dir(primary_dir):
            state_dir = primary_dir
        elif prepare_state_dir(fallback_dir):
            state_dir = fallback_dir
        else:
            raise GateError(
                f"retry state cannot be created in '{primary_dir}' or '{fallback_dir}'; "
                f"recovery: create a writable retry state directory with 'mkdir -p {primary_dir}'"
            )

        fallback_state = fallback_dir / f"{session_key}.json"
        if state_dir == primary_dir and path_exists(fallback_state):
            if not prepare_state_dir(fallback_dir):
                raise GateError(
                    f"the existing fallback retry state cannot be accessed; recovery: repair '{fallback_dir}'"
                )
            state_dir = fallback_dir
        state_file = state_dir / f"{session_key}.json"
        log_file = state_dir / "audit.log"
        saved = read_retry_state(state_file, active if active_valid else False)
    except GateError:
        raise
    except Exception as error:
        raise GateError(
            f"retry state could not be inspected: {error}; recovery: repair the retry state directory and retry the Stop hook"
        ) from error

    if not errors and not blockers:
        return

    block_count = 1
    if active and saved is not None and saved[0] == fingerprint:
        if saved[1] < 3:
            block_count = saved[1] + 1
        else:
            audit_and_allow(log_file, session_key, fingerprint)
            try:
                state_file.unlink(missing_ok=True)
            except OSError:
                pass
            return

    try:
        write_retry_state(state_dir, session_key, fingerprint, block_count)
    except Exception as primary_error:
        if state_dir != fallback_dir and prepare_state_dir(fallback_dir):
            fallback_state = fallback_dir / f"{session_key}.json"
            try:
                if fallback_state.is_symlink() or (
                    path_exists(fallback_state) and not is_regular_file(fallback_state)
                ):
                    raise OSError(f"fallback retry state '{fallback_state}' is not a regular file")
                state_file = write_retry_state(
                    fallback_dir, session_key, fingerprint, block_count
                )
                log_file = fallback_dir / "audit.log"
            except Exception as fallback_error:
                raise GateError(
                    f"retry state could not be written in either location: {primary_error}; {fallback_error}; "
                    "recovery: make the primary or temporary retry state directory writable"
                ) from fallback_error
        else:
            raise GateError(
                f"retry state could not be written in '{state_dir}' or '{fallback_dir}': {primary_error}; "
                "recovery: make one of those directories writable"
            ) from primary_error
    emit({"decision": "block", "reason": reason})


def main() -> None:
    pane_id = os.environ.get("HERDR_PANE_ID", "")
    raw_input = ""
    try:
        raw_input = sys.stdin.read()
    except Exception:
        pass
    if os.environ.get("HERDR_ENV") != "1" or not pane_id:
        return
    identity = identify_meta(pane_id)
    if identity is None:
        return
    owner_terminal, agents = identity
    try:
        evaluate_after_identity(raw_input, pane_id, owner_terminal, agents)
    except GateError as error:
        reason = str(error)
        if not reason.startswith("gate cannot verify:"):
            reason = f"gate cannot verify: {reason}"
        if not reason.endswith("."):
            reason += "."
        emit({"decision": "block", "reason": reason})
    except Exception as error:
        emit(
            {
                "decision": "block",
                "reason": (
                    "gate cannot verify: unexpected check failure "
                    f"({type(error).__name__}: {error}); recovery: repair the reported gate input "
                    "and retry the Claude Stop hook."
                ),
            }
        )


if __name__ == "__main__":
    main()
