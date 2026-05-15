#!/usr/bin/env python3
"""
Audit worklog learn metadata and index consistency.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

SECTION_HEADINGS = {
    "Active": "active",
    "Needs Review": "needs_review",
    "Superseded": "superseded",
    "Archived": "archived",
}
SECTION_ORDER = ["active", "needs_review", "superseded", "archived"]
VALID_FRESHNESS = {"stable", "drift_prone"}
INDEX_ENTRY_RE = re.compile(
    r"^- \[(?P<title>.+?)\]\((?P<filename>[^)]+)\)\s+\[(?P<freshness>stable|drift_prone)\]\s+—\s+(?P<summary>.+)$"
)
FRONTMATTER_KEY_RE = re.compile(r"^([A-Za-z0-9_]+):(?:\s*(.*))?$")
LIST_ITEM_RE = re.compile(r"^\s*-\s+(.*)$")


@dataclass(frozen=True)
class IndexEntry:
    section: str
    title: str
    filename: str
    freshness: str
    line_no: int


@dataclass(frozen=True)
class LearnFile:
    path: Path
    frontmatter: dict[str, object]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit worklog learn metadata.")
    parser.add_argument("command", choices=("summary", "check"))
    parser.add_argument(
        "--learn-root",
        default=".agents/worklog/codex/learn",
        help="Path to the learn directory (default: .agents/worklog/codex/learn)",
    )
    parser.add_argument(
        "--now",
        help="Override current time with an ISO-8601 timestamp for deterministic checks",
    )
    return parser.parse_args()


def parse_scalar(raw_value: str) -> object:
    value = raw_value.strip()
    if not value:
        return ""
    if value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    lowered = value.lower()
    if lowered == "true":
        return True
    if lowered == "false":
        return False
    if lowered in {"null", "~"}:
        return None
    if value.startswith("[") and value.endswith("]"):
        inner = value[1:-1].strip()
        if not inner:
            return []
        return [parse_scalar(part.strip()) for part in inner.split(",") if part.strip()]
    return value


def parse_frontmatter(path: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return {}

    lines = text.splitlines()
    try:
        end_index = lines[1:].index("---") + 1
    except ValueError:
        return {}

    data: dict[str, object] = {}
    current_key: str | None = None
    for line in lines[1:end_index]:
        if not line.strip():
            continue

        if current_key is not None:
            list_match = LIST_ITEM_RE.match(line)
            if list_match:
                current_value = data.setdefault(current_key, [])
                if isinstance(current_value, list):
                    current_value.append(parse_scalar(list_match.group(1)))
                    continue
            current_key = None

        key_match = FRONTMATTER_KEY_RE.match(line)
        if not key_match:
            continue

        key = key_match.group(1)
        raw_value = key_match.group(2)
        if raw_value is None or raw_value == "":
            data[key] = []
            current_key = key
            continue

        data[key] = parse_scalar(raw_value)

    return data


def normalize_status(value: object) -> str | None:
    if value is None or value == "":
        return None
    normalized = str(value).strip().lower().replace("-", "_").replace(" ", "_")
    if normalized in SECTION_ORDER:
        return normalized
    return normalized


def normalize_freshness(value: object) -> str | None:
    if value is None or value == "":
        return None
    normalized = str(value).strip().lower().replace("-", "_")
    if normalized in VALID_FRESHNESS:
        return normalized
    return normalized


def as_list(value: object) -> list[str]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    return [str(value).strip()]


def parse_timestamp(raw_value: object) -> datetime | None:
    if raw_value is None or raw_value == "":
        return None
    candidate = str(raw_value).strip()
    if candidate.endswith("Z"):
        candidate = candidate[:-1] + "+00:00"
    try:
        parsed = datetime.fromisoformat(candidate)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def current_time(raw_now: str | None) -> datetime:
    parsed = parse_timestamp(raw_now)
    if parsed is not None:
        return parsed
    return datetime.now(timezone.utc)


def parse_index(index_path: Path) -> tuple[dict[str, list[IndexEntry]], list[str]]:
    sections = {section: [] for section in SECTION_ORDER}
    errors: list[str] = []

    if not index_path.exists():
        return sections, [f"missing learn index: {index_path}"]

    current_section: str | None = None
    seen_sections: list[str] = []

    for line_no, raw_line in enumerate(index_path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("## "):
            heading = line[3:].strip()
            current_section = SECTION_HEADINGS.get(heading)
            if current_section is None:
                errors.append(f"unexpected section heading on line {line_no}: {heading}")
                continue
            seen_sections.append(current_section)
            continue
        if not line.startswith("- "):
            continue
        if current_section is None:
            errors.append(f"index entry outside managed sections on line {line_no}")
            continue
        match = INDEX_ENTRY_RE.match(line)
        if not match:
            errors.append(f"invalid index entry on line {line_no}: {line}")
            continue
        sections[current_section].append(
            IndexEntry(
                section=current_section,
                title=match.group("title"),
                filename=match.group("filename"),
                freshness=match.group("freshness"),
                line_no=line_no,
            )
        )

    if seen_sections != SECTION_ORDER:
        errors.append(
            "index sections must appear exactly as: Active, Needs Review, Superseded, Archived"
        )

    for section in SECTION_ORDER:
        if section not in seen_sections:
            errors.append(f"missing section: {section}")

    return sections, errors


def load_learn_files(learn_root: Path) -> dict[str, LearnFile]:
    learn_files: dict[str, LearnFile] = {}
    if not learn_root.exists():
        return learn_files
    for path in sorted(learn_root.glob("*.md")):
        if path.name == "learn_index.md":
            continue
        learn_files[path.name] = LearnFile(path=path, frontmatter=parse_frontmatter(path))
    return learn_files


def add_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def format_missing_metadata(filename: str, missing: list[str]) -> str:
    return f"{filename} -> missing {', '.join(missing)}"


def build_report(learn_root: Path, now: datetime) -> dict[str, object]:
    index_sections, index_errors = parse_index(learn_root / "learn_index.md")
    learn_files = load_learn_files(learn_root)
    section_by_filename: dict[str, str] = {}
    freshness_by_filename: dict[str, str] = {}
    index_file_mismatches: list[str] = []
    active_legacy_missing: list[str] = []
    expired_review_after: list[str] = []
    broken_supersession_links: list[str] = []
    active_review_gaps: list[str] = []

    for section in SECTION_ORDER:
        for entry in index_sections[section]:
            if entry.filename in section_by_filename:
                add_unique(
                    index_file_mismatches,
                    f"duplicate index entry: {entry.filename}",
                )
                continue
            section_by_filename[entry.filename] = section
            freshness_by_filename[entry.filename] = entry.freshness

    for filename, section in section_by_filename.items():
        learn = learn_files.get(filename)
        if learn is None:
            add_unique(index_file_mismatches, f"indexed file missing: {filename}")
            continue

        status = normalize_status(learn.frontmatter.get("status"))
        freshness = normalize_freshness(learn.frontmatter.get("freshness"))
        marker_freshness = freshness_by_filename[filename]

        if status is not None and status != section:
            add_unique(
                index_file_mismatches,
                f"section/status mismatch: {filename} (index={section} file={status})",
            )
        if freshness is not None and freshness != marker_freshness:
            add_unique(
                index_file_mismatches,
                f"freshness marker mismatch: {filename} (index={marker_freshness} file={freshness})",
            )

        if section == "active":
            missing_keys = [
                key
                for key in ("status", "freshness", "last_validated_at")
                if learn.frontmatter.get(key) in (None, "", [])
            ]
            if missing_keys:
                add_unique(
                    active_legacy_missing,
                    format_missing_metadata(filename, missing_keys),
                )

        effective_freshness = freshness or marker_freshness
        if effective_freshness != "drift_prone":
            continue

        review_after = parse_timestamp(learn.frontmatter.get("review_after"))
        if review_after is None:
            if section == "active":
                add_unique(
                    active_review_gaps,
                    f"{filename} -> missing review_after",
                )
            continue

        if review_after <= now:
            add_unique(
                expired_review_after,
                f"{filename} (status={section} review_after={learn.frontmatter.get('review_after')})",
            )

    for filename in sorted(learn_files):
        if filename not in section_by_filename:
            add_unique(index_file_mismatches, f"unindexed learn file: {filename}")

    for filename, learn in learn_files.items():
        status = normalize_status(learn.frontmatter.get("status"))

        superseded_by = learn.frontmatter.get("superseded_by")
        if status == "superseded":
            if superseded_by in (None, "", []):
                add_unique(
                    broken_supersession_links,
                    f"{filename} -> missing superseded_by",
                )
            else:
                replacement = str(superseded_by).strip()
                replacement_learn = learn_files.get(replacement)
                if replacement_learn is None:
                    add_unique(
                        broken_supersession_links,
                        f"{filename} -> superseded_by target missing: {replacement}",
                    )
                else:
                    replacement_supersedes = as_list(
                        replacement_learn.frontmatter.get("supersedes")
                    )
                    if filename not in replacement_supersedes:
                        add_unique(
                            broken_supersession_links,
                            f"{filename} -> replacement missing reciprocal supersedes: {replacement}",
                        )

        for target in as_list(learn.frontmatter.get("supersedes")):
            if target not in learn_files:
                add_unique(
                    broken_supersession_links,
                    f"{filename} -> supersedes target missing: {target}",
                )

    status_counts = {
        section: len(index_sections[section])
        for section in SECTION_ORDER
    }

    expired_active_review_after = [
        entry for entry in expired_review_after if "(status=active " in entry
    ]

    startup_breakers = []
    startup_breakers.extend(f"index error: {item}" for item in index_errors)
    startup_breakers.extend(
        f"active entry missing metadata: {item}" for item in active_legacy_missing
    )
    startup_breakers.extend(
        f"active drift_prone entry missing review_after: {item}" for item in active_review_gaps
    )
    startup_breakers.extend(
        f"expired active review_after: {item}" for item in expired_active_review_after
    )
    startup_breakers.extend(
        f"broken supersession link: {item}" for item in broken_supersession_links
    )
    startup_breakers.extend(
        f"index/file mismatch: {item}" for item in index_file_mismatches
    )

    return {
        "status_counts": status_counts,
        "index_errors": index_errors,
        "active_legacy_missing": active_legacy_missing,
        "active_review_gaps": active_review_gaps,
        "expired_review_after": expired_review_after,
        "broken_supersession_links": broken_supersession_links,
        "index_file_mismatches": index_file_mismatches,
        "startup_breakers": startup_breakers,
    }


def print_group(title: str, items: list[str]) -> None:
    print(title)
    if items:
        for item in items:
            print(f"- {item}")
    else:
        print("- none")
    print()


def print_summary(report: dict[str, object]) -> None:
    status_counts = report["status_counts"]
    print("Status counts")
    for section in SECTION_ORDER:
        print(f"- {section}: {status_counts[section]}")
    print()
    print_group("Expired review_after", report["expired_review_after"])
    print_group("Active legacy metadata missing", report["active_legacy_missing"])
    print_group("Broken supersession links", report["broken_supersession_links"])

    mismatches = []
    mismatches.extend(report["index_errors"])
    mismatches.extend(report["active_review_gaps"])
    mismatches.extend(report["index_file_mismatches"])
    print_group("Index/file mismatches", mismatches)


def run_check(report: dict[str, object]) -> int:
    failures: list[str] = report["startup_breakers"]
    if not failures:
        print("OK: no startup-breaking worklog learn issues found.")
        return 0

    print("FAIL: startup-breaking worklog learn issues found.")
    for failure in failures:
        print(f"- {failure}")
    return 1


def main() -> int:
    args = parse_args()
    learn_root = Path(args.learn_root).resolve()
    report = build_report(learn_root, current_time(args.now))
    if args.command == "summary":
        print_summary(report)
        return 0
    return run_check(report)


if __name__ == "__main__":
    sys.exit(main())
