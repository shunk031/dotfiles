from __future__ import annotations

import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts/agent_skill_eval.py"


def load_module():
    spec = importlib.util.spec_from_file_location("agent_skill_eval", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load module from {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def run_git(repo: Path, *args: str) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        check=True,
        text=True,
        capture_output=True,
    ).stdout.strip()


def write_skill(repo: Path, name: str, *, with_evals: bool = True) -> Path:
    skill = repo / "home/dot_config/exact_agents/skills" / name
    skill.mkdir(parents=True)
    (skill / "SKILL.md").write_text(
        f"---\nname: {name}\ndescription: Use when testing {name}.\n---\n\n# {name}\n",
        encoding="utf-8",
    )
    if with_evals:
        (skill / "evals").mkdir()
        (skill / "evals/evals.json").write_text(
            json.dumps(
                {
                    "version": 1,
                    "skill": name,
                    "evals": [
                        {
                            "id": "positive",
                            "prompt": "Do the relevant task.",
                            "should_trigger": True,
                            "assertions": ["The answer is useful."],
                        },
                        {
                            "id": "negative",
                            "prompt": "Reply with a number.",
                            "should_trigger": False,
                            "assertions": ["The answer is a number."],
                        },
                    ],
                }
            ),
            encoding="utf-8",
        )
    return skill


class AgentSkillEvalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.module = load_module()

    def make_repo(self) -> tuple[tempfile.TemporaryDirectory[str], Path]:
        tempdir = tempfile.TemporaryDirectory()
        repo = Path(tempdir.name)
        run_git(repo, "init", "-q")
        run_git(repo, "config", "user.email", "test@example.com")
        run_git(repo, "config", "user.name", "Test")
        return tempdir, repo

    def test_discover_changed_skills_returns_staged_additions_and_updates(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        unchanged = write_skill(repo, "unchanged")
        changed = write_skill(repo, "changed")
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        (changed / "SKILL.md").write_text(
            (changed / "SKILL.md").read_text(encoding="utf-8") + "\nUpdated.\n",
            encoding="utf-8",
        )
        write_skill(repo, "added")
        run_git(repo, "add", ".")

        discovered = self.module.discover_changed_skills(repo, staged=True)

        self.assertEqual([path.name for path in discovered], ["added", "changed"])
        self.assertNotIn(unchanged, discovered)

    def test_discover_changed_skills_ignores_deleted_skills(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "deleted")
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")
        for path in sorted(skill.rglob("*"), reverse=True):
            if path.is_file():
                path.unlink()
            else:
                path.rmdir()
        skill.rmdir()
        run_git(repo, "add", "-u")

        self.assertEqual(self.module.discover_changed_skills(repo, staged=True), [])

    def test_validate_skill_requires_eval_file(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "missing-evals", with_evals=False)

        errors = self.module.validate_skill(skill)

        self.assertTrue(any("evals/evals.json" in error for error in errors))

    def test_discover_all_skills_includes_only_skills_with_evals(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        write_skill(repo, "evaluable")
        write_skill(repo, "legacy", with_evals=False)

        discovered = self.module.discover_all_skills(repo)

        self.assertEqual([path.name for path in discovered], ["evaluable"])

    def test_validate_skill_rejects_invalid_eval_schema(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "invalid")
        (skill / "evals/evals.json").write_text(
            '{"version": 1, "skill": "wrong", "evals": []}', encoding="utf-8"
        )

        errors = self.module.validate_skill(skill)

        self.assertTrue(any("skill" in error for error in errors))
        self.assertTrue(any("positive" in error for error in errors))
        self.assertTrue(any("negative" in error for error in errors))

    def test_parse_trace_detects_skill_read_and_last_message(self) -> None:
        trace = "\n".join(
            [
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {
                            "type": "command_execution",
                            "command": "sed -n '1,200p' .agents/skills/demo/SKILL.md",
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {"type": "agent_message", "text": "final answer"},
                    }
                ),
            ]
        )

        parsed = self.module.parse_trace(trace, "demo")

        self.assertTrue(parsed.skill_read)
        self.assertEqual(parsed.output, "final answer")

    def test_cache_key_changes_with_trials_and_skill_content(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "cache")
        config = self.module.EvalConfig(trials=1, jobs=2, timeout=180)

        first = self.module.cache_key(skill, config, codex_identity="codex 1")
        second = self.module.cache_key(
            skill,
            self.module.EvalConfig(trials=3, jobs=2, timeout=180),
            codex_identity="codex 1",
        )
        (skill / "SKILL.md").write_text("changed", encoding="utf-8")
        third = self.module.cache_key(skill, config, codex_identity="codex 1")

        self.assertNotEqual(first, second)
        self.assertNotEqual(first, third)

    def test_success_cache_round_trip_and_failures_are_not_cached(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        cache = self.module.ResultCache(repo / ".git/eval-cache")

        cache.store("success", {"passed": True})
        cache.store("failure", {"passed": False})

        self.assertEqual(cache.load("success"), {"passed": True})
        self.assertIsNone(cache.load("failure"))

    def test_retry_transient_failure_once(self) -> None:
        attempts = 0

        def operation():
            nonlocal attempts
            attempts += 1
            if attempts == 1:
                raise self.module.TransientCodexError("429")
            return "ok"

        result = self.module.retry_transient(operation, retries=1)

        self.assertEqual(result, "ok")
        self.assertEqual(attempts, 2)

    def test_blind_labels_are_deterministic_for_seed(self) -> None:
        first = self.module.blind_labels("case", 1)
        second = self.module.blind_labels("case", 1)

        self.assertEqual(first, second)
        self.assertEqual(set(first), {"candidate", "baseline"})

    def test_normalize_artifact_removes_only_guidance_read_notices(self) -> None:
        output = (
            "🤖 I read ~/.agents/AGENTS-private.md.\n\n"
            "Here is the requested result.\n"
            "I read the input carefully."
        )

        normalized = self.module.normalize_artifact(output)

        self.assertEqual(
            normalized, "Here is the requested result.\nI read the input carefully."
        )

    def test_comparison_requires_a_win_without_overall_regression(self) -> None:
        self.assertTrue(self.module.comparison_passes(1, 1))
        self.assertTrue(self.module.comparison_passes(2, 0))
        self.assertFalse(self.module.comparison_passes(0, 0))
        self.assertFalse(self.module.comparison_passes(1, 2))

    def test_evaluate_skill_uses_fake_codex_and_caches_success(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "demo")
        fake_codex = repo / "fake-codex"
        fake_codex.write_text(
            """#!/usr/bin/env python3
import json
import sys
from pathlib import Path

if "--version" in sys.argv:
    print("codex-test 1.0")
    raise SystemExit

prompt = sys.stdin.read()
cwd = Path(sys.argv[sys.argv.index("--cd") + 1])

def emit(item):
    print(json.dumps({"type": "item.completed", "item": item}))

if "--output-schema" in sys.argv:
    payload = json.loads(prompt.split("\\n\\n", 1)[1])
    cases = []
    for item in payload:
        preferred = "only"
        if "A" in item:
            preferred = "A" if item["A"].startswith("candidate") else "B"
        cases.append({
            "id": item["id"],
            "trial": item["trial"],
            "A_assertions_pass": True if "A" in item else None,
            "B_assertions_pass": True if "B" in item else None,
            "only_assertions_pass": True if "only" in item else None,
            "preferred": preferred,
            "reason": "fixture",
        })
    emit({"type": "agent_message", "text": json.dumps({"cases": cases})})
    raise SystemExit

skills = list((cwd / ".agents/skills").glob("*"))
candidate = bool(skills)
negative = "number" in prompt
if candidate and not negative:
    emit({
        "type": "command_execution",
        "command": f"sed -n '1,120p' {skills[0] / 'SKILL.md'}",
    })
output = "2" if negative else ("candidate useful answer" if candidate else "baseline answer")
emit({"type": "agent_message", "text": output})
""",
            encoding="utf-8",
        )
        fake_codex.chmod(0o755)
        previous = os.environ.get("AGENT_SKILL_EVAL_CODEX")
        os.environ["AGENT_SKILL_EVAL_CODEX"] = str(fake_codex)
        self.addCleanup(
            lambda: (
                os.environ.pop("AGENT_SKILL_EVAL_CODEX", None)
                if previous is None
                else os.environ.__setitem__("AGENT_SKILL_EVAL_CODEX", previous)
            )
        )
        cache = self.module.ResultCache(repo / ".git/eval-cache")
        config = self.module.EvalConfig(trials=1, jobs=2, timeout=10)

        passed = self.module.evaluate_skill(skill, config, cache)
        cached = self.module.evaluate_skill(skill, config, cache)

        self.assertTrue(passed)
        self.assertTrue(cached)


if __name__ == "__main__":
    unittest.main()
