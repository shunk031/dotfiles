from __future__ import annotations

import importlib.util
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = REPO_ROOT / "scripts/agent_guidance_eval.py"


def load_module():
    spec = importlib.util.spec_from_file_location("agent_guidance_eval", SCRIPT_PATH)
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


def write_guidance(repo: Path) -> Path:
    guidance = repo / "home/dot_config/exact_agents/AGENTS.md"
    guidance.parent.mkdir(parents=True)
    guidance.write_text(
        "# AGENTS.md\n\nResearch before implementation.\n", encoding="utf-8"
    )
    return guidance


def write_guidance_eval(repo: Path) -> Path:
    eval_path = repo / "home/dot_config/exact_agents/AGENTS.evals.json"
    eval_path.write_text(
        json.dumps(
            {
                "version": 1,
                "guidance": "user-guidance",
                "evals": [
                    {
                        "id": "positive",
                        "prompt": "Acknowledge this correction neutrally.",
                        "should_trigger": True,
                        "assertions": ["The response is neutral."],
                    },
                    {
                        "id": "negative",
                        "prompt": "Answer this ordinary question directly.",
                        "should_trigger": False,
                        "assertions": ["The answer is direct."],
                    },
                ],
            }
        ),
        encoding="utf-8",
    )
    return eval_path


class AgentGuidanceEvalTest(unittest.TestCase):
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

    def test_staged_namespace_only_rename_is_not_a_behavioral_target(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        old_name = "workflow"
        new_name = "shunk031-workflow"
        skill = write_skill(repo, old_name)
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        renamed = skill.with_name(new_name)
        skill.rename(renamed)
        for path in renamed.rglob("*"):
            if path.is_file():
                path.write_text(
                    path.read_text(encoding="utf-8").replace(old_name, new_name),
                    encoding="utf-8",
                )
        run_git(repo, "add", "-A")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(
            [(target.kind, target.name) for target in targets],
            [("namespace-rename", new_name)],
        )
        self.assertEqual(self.module.validate_target(targets[0]), [])

    def test_namespace_rename_with_behavior_change_remains_evaluable(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        old_name = "workflow"
        new_name = "shunk031-workflow"
        skill = write_skill(repo, old_name)
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        renamed = skill.with_name(new_name)
        skill.rename(renamed)
        for path in renamed.rglob("*"):
            if path.is_file():
                path.write_text(
                    path.read_text(encoding="utf-8").replace(old_name, new_name),
                    encoding="utf-8",
                )
        skill_file = renamed / "SKILL.md"
        skill_file.write_text(
            skill_file.read_text(encoding="utf-8") + "\nChanged behavior.\n",
            encoding="utf-8",
        )
        run_git(repo, "add", "-A")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(
            [(target.kind, target.name) for target in targets], [("skill", new_name)]
        )

    def test_namespace_rename_allows_legacy_skill_without_evals(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        old_name = "legacy"
        new_name = "shunk031-legacy"
        skill = write_skill(repo, old_name, with_evals=False)
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        renamed = skill.with_name(new_name)
        skill.rename(renamed)
        skill_file = renamed / "SKILL.md"
        skill_file.write_text(
            skill_file.read_text(encoding="utf-8").replace(old_name, new_name),
            encoding="utf-8",
        )
        run_git(repo, "add", "-A")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(targets[0].kind, "namespace-rename")
        self.assertEqual(self.module.validate_target(targets[0]), [])

    def test_namespace_only_guidance_update_does_not_promote_rename(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        old_name = "research-before-implementation"
        new_name = "shunk031-research-before-implementation"
        guidance = write_guidance(repo)
        guidance.write_text(f"Use `{old_name}`.\n", encoding="utf-8")
        skill = write_skill(repo, old_name)
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        renamed = skill.with_name(new_name)
        skill.rename(renamed)
        for path in renamed.rglob("*"):
            if path.is_file():
                path.write_text(
                    path.read_text(encoding="utf-8").replace(old_name, new_name),
                    encoding="utf-8",
                )
        guidance.write_text(f"Use `{new_name}`.\n", encoding="utf-8")
        run_git(repo, "add", "-A")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(
            [(target.kind, target.name) for target in targets],
            [("namespace-rename", new_name)],
        )

    def test_staged_evaluation_wiring_change_is_not_a_behavior_target(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "wiring")
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        (skill / "SKILL.md").write_text(
            (skill / "SKILL.md").read_text(encoding="utf-8")
            + "\nRun guidance evaluation through prek.\n",
            encoding="utf-8",
        )
        run_git(repo, "add", ".")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(
            [(target.kind, target.name) for target in targets],
            [("evaluation-wiring", "wiring")],
        )
        self.assertEqual(self.module.validate_target(targets[0]), [])

    def test_discover_changed_targets_includes_staged_user_guidance(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        guidance = write_guidance(repo)
        write_guidance_eval(repo)
        write_skill(repo, "shunk031-research-before-implementation")
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")
        guidance.write_text(
            guidance.read_text(encoding="utf-8") + "Search GitHub too.\n",
            encoding="utf-8",
        )
        run_git(repo, "add", ".")

        targets = self.module.discover_changed_targets(repo, staged=True)

        self.assertEqual(
            [target.name for target in targets],
            ["user-guidance"],
        )
        self.assertEqual(targets[0].kind, "guidance")
        self.assertEqual(targets[0].eval_path.name, "AGENTS.evals.json")

    def test_staged_and_all_target_discovery_keep_guidance_separate_from_skills(
        self,
    ) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        guidance = write_guidance(repo)
        write_guidance_eval(repo)
        changed = write_skill(repo, "changed")
        write_skill(repo, "unchanged")
        run_git(repo, "add", ".")
        run_git(repo, "commit", "-qm", "initial")

        guidance.write_text(
            guidance.read_text(encoding="utf-8") + "New guidance.\n",
            encoding="utf-8",
        )
        (changed / "SKILL.md").write_text(
            (changed / "SKILL.md").read_text(encoding="utf-8") + "\nChanged.\n",
            encoding="utf-8",
        )
        run_git(repo, "add", ".")

        staged = self.module.discover_changed_targets(repo, staged=True)
        self.assertEqual(
            [(target.kind, target.name) for target in staged],
            [("guidance", "user-guidance"), ("skill", "changed")],
        )

        all_targets = self.module.discover_all_targets(repo)
        self.assertEqual(
            [(target.kind, target.name) for target in all_targets],
            [
                ("guidance", "user-guidance"),
                ("skill", "changed"),
                ("skill", "unchanged"),
            ],
        )

    def test_discover_all_targets_includes_evaluable_skills(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        write_skill(repo, "evaluable")

        targets = self.module.discover_all_targets(repo)

        self.assertEqual(
            [(target.kind, target.name) for target in targets],
            [("skill", "evaluable")],
        )

    def test_validate_guidance_target_accepts_first_class_eval_file(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        guidance = write_guidance(repo)
        eval_path = write_guidance_eval(repo)
        target = self.module.EvalTarget(
            name="user-guidance",
            kind="guidance",
            path=guidance,
            eval_path=eval_path,
        )

        self.assertEqual(self.module.validate_target(target), [])

    def test_parse_trace_detects_guidance_read(self) -> None:
        trace = json.dumps(
            {
                "type": "item.completed",
                "item": {
                    "type": "command_execution",
                    "command": "sed -n '1,200p' .agents/AGENTS.md",
                },
            }
        )

        parsed = self.module.parse_trace(trace, "user-guidance", "guidance")

        self.assertTrue(parsed.target_read)

    def test_guidance_target_is_active_without_an_observable_shell_read(self) -> None:
        target = self.module.EvalTarget(
            name="user-guidance",
            kind="guidance",
            path=Path("AGENTS.md"),
            eval_path=Path("AGENTS.evals.json"),
        )
        case = self.module.EvalCase(
            id="friendly",
            prompt="Reply naturally.",
            should_trigger=False,
            assertions=("The response is natural.",),
        )
        result = self.module.RunResult(
            case_id=case.id,
            trial=1,
            variant="candidate",
            output="natural",
            target_read=False,
        )

        self.assertTrue(self.module.target_read_passes(target, case, result))

    def test_run_guidance_case_copies_user_guidance_into_candidate(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        guidance = write_guidance(repo)
        eval_path = write_guidance_eval(repo)
        target = self.module.EvalTarget(
            name="user-guidance",
            kind="guidance",
            path=guidance,
            eval_path=eval_path,
        )
        case = self.module.EvalCase(
            id="guidance",
            prompt="Respond neutrally.",
            should_trigger=False,
            assertions=("The response is neutral.",),
        )

        def fake_invoke(run_repo, *args, **kwargs):
            self.assertEqual(
                (run_repo / ".agents/AGENTS.md").read_text(encoding="utf-8"),
                guidance.read_text(encoding="utf-8"),
            )
            return json.dumps(
                {"item": {"type": "agent_message", "text": "neutral"}}
            )

        with mock.patch.object(self.module, "invoke_codex", side_effect=fake_invoke):
            result = self.module.run_target_case(
                target,
                self.module.RunSpec(
                    case=case,
                    trial=1,
                    variant="candidate",
                ),
                timeout=10,
            )

        self.assertEqual(result.output, "neutral")

    def test_initialize_codex_home_copies_credentials_without_live_symlinks(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        source = repo / "source-codex-home"
        source.mkdir()
        (source / "config.toml").write_text("model = 'test'\n", encoding="utf-8")
        (source / "auth.json").write_text('{"token":"redacted"}\n', encoding="utf-8")
        destination = repo / "isolated-codex-home"

        with mock.patch.dict(os.environ, {"CODEX_HOME": str(source)}, clear=False):
            self.module.initialize_codex_home(destination)

        for name in ("config.toml", "auth.json"):
            copied = destination / name
            self.assertFalse(copied.is_symlink())
            self.assertEqual(
                copied.read_text(encoding="utf-8"),
                (source / name).read_text(encoding="utf-8"),
            )

    def test_prek_hooks_trigger_for_guidance_and_skills(self) -> None:
        config = (REPO_ROOT / ".pre-commit-config.yaml").read_text(encoding="utf-8")

        validate_files = (
            "files: ^home/dot_config/exact_agents/"
            "(AGENTS\\.md|AGENTS\\.evals\\.json|skills/)"
        )
        eval_files = (
            "files: ^home/dot_config/exact_agents/"
            "(AGENTS\\.md|AGENTS\\.evals\\.json|"
            "skills/[^/]+/(SKILL\\.md|evals/evals\\.json))$"
        )
        self.assertEqual(config.count(validate_files), 1)
        self.assertEqual(config.count(eval_files), 1)
        self.assertEqual(
            config.count(
                "entry: uv run --python 3.14.6 --no-project python "
                "scripts/agent_guidance_eval.py"
            ),
            2,
        )

        validate_start = config.index("id: agent-guidance-validate")
        eval_start = config.index("id: agent-guidance-eval")
        self.assertLess(
            config.index(validate_files, validate_start),
            eval_start,
        )
        self.assertGreater(config.index(eval_files, eval_start), eval_start)

    def test_validate_skill_accepts_required_action_sequence(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "research")
        eval_path = skill / "evals/evals.json"
        data = json.loads(eval_path.read_text(encoding="utf-8"))
        data["evals"][0]["required_actions"] = [
            "web_search",
            "github_search",
            "file_change",
        ]
        eval_path.write_text(json.dumps(data), encoding="utf-8")

        self.assertEqual(self.module.validate_skill(skill), [])

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

    def test_parse_trace_detects_target_read_and_last_message(self) -> None:
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

        self.assertTrue(parsed.target_read)
        self.assertEqual(parsed.output, "final answer")

    def test_parse_trace_records_research_before_file_change(self) -> None:
        trace = "\n".join(
            [
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {"type": "web_search", "query": "current mise docs"},
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {
                            "type": "web_search",
                            "query": "site:github.com mise macOS defaults",
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {"type": "file_change", "changes": []},
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {"type": "agent_message", "text": "implemented"},
                    }
                ),
            ]
        )

        parsed = self.module.parse_trace(trace, "demo")

        self.assertEqual(parsed.actions, ("web_search", "github_search", "file_change"))
        self.assertTrue(
            self.module.contains_ordered_actions(
                parsed.actions, ("web_search", "github_search", "file_change")
            )
        )

    def test_parse_trace_records_shell_research_before_file_change(self) -> None:
        trace = "\n".join(
            [
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {
                            "type": "command_execution",
                            "command": "curl -fsSL https://developers.openai.com/codex/codex-manual.md",
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {
                            "type": "command_execution",
                            "command": "curl -fsSL https://raw.githubusercontent.com/openai/codex/main/codex-rs/core/src/web_search.rs",
                        },
                    }
                ),
                json.dumps(
                    {
                        "type": "item.completed",
                        "item": {"type": "file_change", "changes": []},
                    }
                ),
            ]
        )

        parsed = self.module.parse_trace(trace, "demo")

        self.assertEqual(parsed.actions, ("web_search", "github_search", "file_change"))

    def test_parse_trace_recognizes_gh_code_search_as_github_research(self) -> None:
        trace = json.dumps(
            {
                "type": "item.completed",
                "item": {
                    "type": "command_execution",
                    "command": "gh search code 'defaults repo:mise-plugins/mise'",
                },
            }
        )

        parsed = self.module.parse_trace(trace, "demo")

        self.assertEqual(parsed.actions, ("github_search",))

    def test_temp_repo_and_codex_clear_git_local_environment(self) -> None:
        tempdir, outer_repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        foreign_repo = outer_repo / "foreign-repo"
        environment_dump = outer_repo / "codex-environment.json"
        fake_codex = outer_repo / "fake-codex"
        fake_codex.write_text(
            f"""#!{sys.executable}
import json
import os
from pathlib import Path

local_names = ("GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")
observed = {{name: os.environ.get(name) for name in local_names}}
observed["GIT_CONFIG_GLOBAL"] = os.environ.get("GIT_CONFIG_GLOBAL")
observed["AUTH_TOKEN"] = os.environ.get("AUTH_TOKEN")
observed["PATH"] = os.environ.get("PATH")
Path(os.environ["ENVIRONMENT_DUMP"]).write_text(
    json.dumps(observed), encoding="utf-8"
)
print(json.dumps({{"type": "item.completed", "item": {{"type": "agent_message", "text": "ok"}}}}))
""",
            encoding="utf-8",
        )
        fake_codex.chmod(0o755)

        original_cwd = Path.cwd()
        self.addCleanup(lambda: os.chdir(original_cwd))
        os.chdir(outer_repo)
        with mock.patch.dict(
            os.environ,
            {
                "GIT_DIR": str(outer_repo / ".git"),
                "GIT_WORK_TREE": str(outer_repo),
                "GIT_INDEX_FILE": str(outer_repo / ".git/index"),
                "GIT_CONFIG_GLOBAL": str(outer_repo / "global.gitconfig"),
                "AUTH_TOKEN": "secret",
                "PATH": "/usr/bin:/bin",
                "AGENT_GUIDANCE_EVAL_CODEX": str(fake_codex),
                "ENVIRONMENT_DUMP": str(environment_dump),
            },
            clear=False,
        ):
            self.module.initialize_temp_repo(foreign_repo)
            trace = self.module.invoke_codex(foreign_repo, "prompt", timeout=10)

        os.chdir(original_cwd)
        self.assertIn("item.completed", trace)
        self.assertTrue((foreign_repo / ".git").is_dir())
        self.assertEqual(
            Path(run_git(foreign_repo, "rev-parse", "--show-toplevel")).resolve(),
            foreign_repo.resolve(),
        )
        observed = json.loads(environment_dump.read_text(encoding="utf-8"))
        self.assertIsNone(observed["GIT_DIR"])
        self.assertIsNone(observed["GIT_WORK_TREE"])
        self.assertIsNone(observed["GIT_INDEX_FILE"])
        self.assertEqual(
            observed["GIT_CONFIG_GLOBAL"], str(outer_repo / "global.gitconfig")
        )
        self.assertEqual(observed["AUTH_TOKEN"], "secret")
        self.assertEqual(observed["PATH"], "/usr/bin:/bin")

    def test_codex_environment_drops_herdr_context(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        environment_dump = repo / "codex-environment.json"
        fake_codex = repo / "fake-codex"
        fake_codex.write_text(
            f"""#!{sys.executable}
import json
import os
from pathlib import Path

herdr_names = ("HERDR_ENV", "HERDR_WORKSPACE_ID", "HERDR_TAB_ID", "HERDR_PANE_ID")
observed = {{name: os.environ.get(name) for name in herdr_names}}
Path(os.environ["ENVIRONMENT_DUMP"]).write_text(
    json.dumps(observed), encoding="utf-8"
)
print(json.dumps({{"type": "item.completed", "item": {{"type": "agent_message", "text": "ok"}}}}))
""",
            encoding="utf-8",
        )
        fake_codex.chmod(0o755)

        with mock.patch.dict(
            os.environ,
            {
                "HERDR_ENV": "1",
                "HERDR_WORKSPACE_ID": "w1",
                "HERDR_TAB_ID": "w1:t1",
                "HERDR_PANE_ID": "w1:p1",
                "AGENT_GUIDANCE_EVAL_CODEX": str(fake_codex),
                "ENVIRONMENT_DUMP": str(environment_dump),
            },
            clear=False,
        ):
            trace = self.module.invoke_codex(repo, "prompt", timeout=10)

        self.assertIn("item.completed", trace)
        observed = json.loads(environment_dump.read_text(encoding="utf-8"))
        for name, value in observed.items():
            self.assertIsNone(value, name)

    def test_codex_home_copies_config_and_auth_without_mutating_source(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        source = repo / "source-codex-home"
        isolated = repo / "isolated-codex-home"
        source.mkdir()
        source_config = source / "config.toml"
        source_auth = source / "auth.json"
        config_bytes = (
            b'[projects."/tmp/agent-skill-eval-live/repo"]\ntrust_level = "trusted"\n'
        )
        auth_bytes = b'{"auth": "fixture"}\n'
        source_config.write_bytes(config_bytes)
        source_auth.write_bytes(auth_bytes)
        source_config.chmod(0o600)
        source_auth.chmod(0o600)

        with mock.patch.dict(os.environ, {"CODEX_HOME": str(source)}, clear=False):
            self.module.initialize_codex_home(isolated)

        target_config = isolated / "config.toml"
        target_auth = isolated / "auth.json"
        for target, expected, source_path in (
            (target_config, config_bytes, source_config),
            (target_auth, auth_bytes, source_auth),
        ):
            self.assertTrue(target.is_file())
            self.assertFalse(target.is_symlink())
            self.assertEqual(target.read_bytes(), expected)
            self.assertEqual(stat.S_IMODE(target.stat().st_mode), 0o600)
            self.assertEqual(source_path.read_bytes(), expected)
            self.assertEqual(stat.S_IMODE(source_path.stat().st_mode), 0o600)

        target_config.write_bytes(
            target_config.read_bytes() + b"\n[projects.\"/tmp/new\"]\n"
        )
        self.assertEqual(source_config.read_bytes(), config_bytes)

    def test_sandbox_override_replaces_requested_sandbox(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        with (
            mock.patch.object(
                self.module,
                "disabled_skill_override",
                return_value="",
            ),
            mock.patch.dict(
                os.environ,
                {"AGENT_GUIDANCE_EVAL_SANDBOX": "danger-full-access"},
                clear=False,
            ),
            mock.patch.object(
                self.module.subprocess, "run", return_value=completed
            ) as run,
        ):
            self.module.invoke_codex(Path("/tmp"), "prompt", 10, sandbox="read-only")

        command = run.call_args.args[0]
        sandbox_index = command.index("--sandbox")
        self.assertEqual(command[sandbox_index + 1], "danger-full-access")

    def test_invoke_disables_native_search_for_research(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        with (
            mock.patch.object(
                self.module,
                "disabled_skill_override",
                return_value="",
            ),
            mock.patch.object(
                self.module.subprocess, "run", return_value=completed
            ) as run,
        ):
            self.module.invoke_codex(Path("/tmp"), "prompt", 10, search=True)

        command = run.call_args.args[0]
        exec_index = command.index("exec")
        self.assertNotIn("--search", command)
        self.assertIn('web_search="disabled"', command)
        self.assertIn("sandbox_workspace_write.network_access=true", command)
        self.assertGreater(command.index('web_search="disabled"'), exec_index)
        self.assertGreater(
            command.index("sandbox_workspace_write.network_access=true"), exec_index
        )
        self.assertNotIn("supports_standalone_web_search", " ".join(command))
        self.assertTrue(
            all(
                index > exec_index
                for index, value in enumerate(command)
                if value == "-c"
            )
        )

    def test_invoke_places_skill_override_after_exec(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        with (
            mock.patch.object(
                self.module,
                "disabled_skill_override",
                return_value="skills.config=[]",
            ),
            mock.patch.object(self.module.subprocess, "run", return_value=completed) as run,
        ):
            self.module.invoke_codex(Path("/tmp"), "prompt", 10)

        command = run.call_args.args[0]
        exec_index = command.index("exec")
        self.assertGreater(command.index("skills.config=[]"), exec_index)

    def test_invoke_adds_model_and_reasoning_effort_to_exec(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        with mock.patch.object(
            self.module.subprocess, "run", return_value=completed
        ) as run:
            self.module.invoke_codex(
                Path("/tmp"),
                "prompt",
                10,
                model="gpt-5.6-luna",
                reasoning_effort="xhigh",
            )

        command = run.call_args.args[0]
        exec_index = command.index("exec")
        self.assertEqual(
            command[exec_index + 1 : exec_index + 5],
            ["--model", "gpt-5.6-luna", "-c", 'model_reasoning_effort="xhigh"'],
        )
        self.assertNotIn("sandbox_workspace_write.network_access=true", command)

    def test_workspace_write_uses_cd_as_primary_codex_workspace(self) -> None:
        completed = subprocess.CompletedProcess(
            args=[], returncode=0, stdout="", stderr=""
        )
        repo = Path("/tmp/agent-skill-eval/repo")
        with mock.patch.object(
            self.module.subprocess, "run", return_value=completed
        ) as run:
            self.module.invoke_codex(repo, "prompt", 10, sandbox="workspace-write")

        command = run.call_args.args[0]
        cd_index = command.index("--cd")
        self.assertEqual(command[cd_index + 1], str(repo))
        self.assertNotIn("--add-dir", command)

    def test_target_variants_receive_target_model_settings(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "research")
        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )
        seen: list[dict[str, object]] = []

        def fake_invoke(run_repo, prompt, timeout, **kwargs):
            seen.append(kwargs)
            return json.dumps(
                {"item": {"type": "agent_message", "text": "answer"}}
            )

        with mock.patch.object(self.module, "invoke_codex", side_effect=fake_invoke):
            for variant in ("candidate", "baseline"):
                self.module.run_target_case(
                    target,
                    self.module.RunSpec(
                        case=self.module.EvalCase(
                            id="research",
                            prompt="Answer.",
                            should_trigger=True,
                            assertions=("The answer is useful.",),
                        ),
                        trial=1,
                        variant=variant,
                    ),
                    timeout=10,
                    model="gpt-5.6-luna",
                    reasoning_effort="xhigh",
                )

        self.assertEqual(
            seen,
            [
                {
                    "sandbox": "workspace-write",
                    "search": False,
                    "codex_home": mock.ANY,
                    "model": "gpt-5.6-luna",
                    "reasoning_effort": "xhigh",
                },
                {
                    "sandbox": "workspace-write",
                    "search": False,
                    "codex_home": mock.ANY,
                    "model": "gpt-5.6-luna",
                    "reasoning_effort": "xhigh",
                },
            ],
        )

    def test_judge_receives_only_judge_model_settings(self) -> None:
        case = self.module.EvalCase(
            id="negative",
            prompt="Reply.",
            should_trigger=False,
            assertions=("The answer is useful.",),
        )
        result = self.module.RunResult(
            case_id=case.id,
            trial=1,
            variant="candidate",
            output="answer",
            target_read=False,
        )
        judge_output = json.dumps(
            {
                "cases": [
                    {
                        "id": case.id,
                        "trial": 1,
                        "A_assertions_pass": None,
                        "B_assertions_pass": None,
                        "only_assertions_pass": True,
                        "preferred": "only",
                        "reason": "fixture",
                    }
                ]
            }
        )
        trace = json.dumps(
            {
                "item": {
                    "type": "agent_message",
                    "text": judge_output,
                }
            }
        )

        def fake_invoke(*args, **kwargs):
            judge_home = kwargs["codex_home"]
            self.assertTrue(judge_home.is_dir())
            self.assertFalse((judge_home / "config.toml").is_symlink())
            self.assertFalse((judge_home / "auth.json").is_symlink())
            return trace

        with mock.patch.object(
            self.module, "invoke_codex", side_effect=fake_invoke
        ) as invoke:
            self.module.judge_results(
                [case],
                [result],
                timeout=10,
                model="gpt-5.6-sol",
                reasoning_effort="medium",
            )

        self.assertEqual(
            invoke.call_args.kwargs["model"],
            "gpt-5.6-sol",
        )
        self.assertEqual(invoke.call_args.kwargs["reasoning_effort"], "medium")

    def test_guidance_cases_use_only_judging_without_a_skill_baseline(self) -> None:
        case = self.module.EvalCase(
            id="correction",
            prompt="Respond neutrally.",
            should_trigger=True,
            assertions=("The response is neutral.",),
        )
        result = self.module.RunResult(
            case_id=case.id,
            trial=1,
            variant="candidate",
            output="neutral",
            target_read=False,
        )

        payload, mappings = self.module.build_judge_payload([case], [result])

        self.assertEqual(payload[0]["only"], "neutral")
        self.assertEqual(mappings, {(case.id, 1): {"only": "candidate"}})
        self.assertNotIn("A", payload[0])
        self.assertNotIn("B", payload[0])

    def test_main_propagates_model_settings_into_eval_config(self) -> None:
        target = self.module.EvalTarget(
            name="demo",
            kind="skill",
            path=Path("/tmp/demo"),
            eval_path=Path("/tmp/demo/evals/evals.json"),
        )
        with (
            mock.patch.object(self.module, "find_repo_root", return_value=Path("/tmp")),
            mock.patch.object(
                self.module, "selected_targets", return_value=[target]
            ),
            mock.patch.object(self.module, "validate_target", return_value=[]),
            mock.patch.object(
                self.module, "cache_for_repo", return_value=mock.sentinel.cache
            ),
            mock.patch.object(
                self.module, "evaluate_target", return_value=True
            ) as evaluate,
        ):
            status = self.module.main(
                [
                    "eval",
                    "--all",
                    "--model",
                    "gpt-5.6-test-target",
                    "--reasoning-effort",
                    "low",
                    "--judge-model",
                    "gpt-5.6-test-judge",
                    "--judge-reasoning-effort",
                    "high",
                    "--strict-all-trials",
                ]
            )

        self.assertEqual(status, 0)
        config = evaluate.call_args.args[1]
        self.assertEqual(config.model, "gpt-5.6-test-target")
        self.assertEqual(config.reasoning_effort, "low")
        self.assertEqual(config.judge_model, "gpt-5.6-test-judge")
        self.assertEqual(config.judge_reasoning_effort, "high")
        self.assertTrue(config.strict_all_trials)

    def test_main_uses_required_model_defaults_without_flags(self) -> None:
        defaults = self.module.EvalConfig()
        self.assertEqual(defaults.model, "gpt-5.6-luna")
        self.assertEqual(defaults.reasoning_effort, "xhigh")
        self.assertEqual(defaults.judge_model, "gpt-5.6-sol")
        self.assertEqual(defaults.judge_reasoning_effort, "medium")
        self.assertFalse(defaults.strict_all_trials)

        with mock.patch.object(self.module.sys, "version_info", (3, 10)):
            with self.assertRaisesRegex(SystemExit, "requires Python 3.11\\+"):
                self.module.require_supported_python()

        target = self.module.EvalTarget(
            name="demo",
            kind="skill",
            path=Path("/tmp/demo"),
            eval_path=Path("/tmp/demo/evals/evals.json"),
        )
        with (
            mock.patch.object(self.module, "find_repo_root", return_value=Path("/tmp")),
            mock.patch.object(
                self.module, "selected_targets", return_value=[target]
            ),
            mock.patch.object(self.module, "validate_target", return_value=[]),
            mock.patch.object(
                self.module, "cache_for_repo", return_value=mock.sentinel.cache
            ),
            mock.patch.object(
                self.module, "evaluate_target", return_value=True
            ) as evaluate,
        ):
            status = self.module.main(["eval", "--all"])

        self.assertEqual(status, 0)
        config = evaluate.call_args.args[1]
        self.assertEqual(config.model, "gpt-5.6-luna")
        self.assertEqual(config.reasoning_effort, "xhigh")
        self.assertEqual(config.judge_model, "gpt-5.6-sol")
        self.assertEqual(config.judge_reasoning_effort, "medium")

    def test_required_actions_rejects_implementation_before_research(self) -> None:
        case = self.module.EvalCase(
            id="research",
            prompt="Implement an example.",
            should_trigger=True,
            assertions=("The example works.",),
            required_actions=("web_search", "github_search", "file_change"),
        )
        result = self.module.RunResult(
            case_id="research",
            trial=1,
            variant="candidate",
            output="implemented",
            target_read=False,
            actions=("file_change", "web_search", "github_search"),
        )

        self.assertFalse(self.module.required_actions_pass([case], [result]))
        self.assertEqual(
            self.module.required_action_failures([case], [result]),
            [
                (
                    "research trial 1: required actions "
                    "('web_search', 'github_search', 'file_change'), observed "
                    "('file_change', 'web_search', 'github_search'); "
                    "output='implemented'"
                )
            ],
        )

    def test_run_research_skill_enables_search_and_workspace_writes(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "research")
        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )
        case = self.module.EvalCase(
            id="research",
            prompt="Implement an example.",
            should_trigger=True,
            assertions=("The example works.",),
            required_actions=("web_search", "github_search", "file_change"),
        )
        spec = self.module.RunSpec(case=case, trial=1, variant="candidate")

        def fake_invoke(
            run_repo,
            prompt,
            timeout,
            schema=None,
            *,
            sandbox="read-only",
            search=False,
            codex_home=None,
        ):
            self.assertTrue((run_repo / ".agents/skills/research/SKILL.md").is_file())
            self.assertEqual(sandbox, "workspace-write")
            self.assertTrue(search)
            self.assertIsNotNone(codex_home)
            return "\n".join(
                [
                    json.dumps(
                        {"item": {"type": "web_search", "query": "current docs"}}
                    ),
                    json.dumps(
                        {
                            "item": {
                                "type": "web_search",
                                "query": "site:github.com example",
                            }
                        }
                    ),
                    json.dumps({"item": {"type": "file_change"}}),
                    json.dumps(
                        {"item": {"type": "agent_message", "text": "implemented"}}
                    ),
                ]
            )

        with mock.patch.object(self.module, "invoke_codex", side_effect=fake_invoke):
            result = self.module.run_target_case(target, spec, timeout=10)

        self.assertEqual(result.actions, ("web_search", "github_search", "file_change"))

    def test_run_research_skill_baseline_has_no_candidate_skill(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "research")
        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )
        case = self.module.EvalCase(
            id="research",
            prompt="Implement an example.",
            should_trigger=True,
            assertions=("The example works.",),
        )
        spec = self.module.RunSpec(case=case, trial=1, variant="baseline")

        def fake_invoke(run_repo, *args, **kwargs):
            self.assertFalse((run_repo / ".agents/skills/research").exists())
            self.assertEqual(kwargs["sandbox"], "workspace-write")
            return json.dumps({"item": {"type": "agent_message", "text": "baseline"}})

        with mock.patch.object(self.module, "invoke_codex", side_effect=fake_invoke):
            self.module.run_target_case(target, spec, timeout=10)

    def test_cache_key_changes_with_trials_and_skill_content(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "cache")
        config = self.module.EvalConfig(trials=1, jobs=2, timeout=180)

        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )

        def cache_key(config, codex_identity):
            return self.module.target_cache_key(target, config, codex_identity)

        first = cache_key(config, codex_identity="codex 1")
        second = cache_key(
            self.module.EvalConfig(trials=3, jobs=2, timeout=180),
            codex_identity="codex 1",
        )
        (skill / "SKILL.md").write_text("changed", encoding="utf-8")
        third = cache_key(config, codex_identity="codex 1")

        self.assertNotEqual(first, second)
        self.assertNotEqual(first, third)

        configured = cache_key(
            self.module.EvalConfig(
                trials=1,
                jobs=2,
                timeout=180,
                model="gpt-5.6-luna",
                reasoning_effort="xhigh",
                judge_model="gpt-5.6-sol",
                judge_reasoning_effort="medium",
            ),
            codex_identity="codex 1",
        )
        different_model = cache_key(
            self.module.EvalConfig(
                trials=1,
                jobs=2,
                timeout=180,
                model="gpt-5.6-sol",
                reasoning_effort="xhigh",
                judge_model="gpt-5.6-sol",
                judge_reasoning_effort="medium",
            ),
            codex_identity="codex 1",
        )
        different_effort = cache_key(
            self.module.EvalConfig(
                trials=1,
                jobs=2,
                timeout=180,
                model="gpt-5.6-luna",
                reasoning_effort="high",
                judge_model="gpt-5.6-sol",
                judge_reasoning_effort="medium",
            ),
            codex_identity="codex 1",
        )
        self.assertNotEqual(configured, different_model)
        self.assertNotEqual(configured, different_effort)

        different_judge_model = cache_key(
            self.module.EvalConfig(
                trials=1,
                jobs=2,
                timeout=180,
                model="gpt-5.6-luna",
                reasoning_effort="xhigh",
                judge_model="gpt-5.6-luna",
                judge_reasoning_effort="medium",
            ),
            codex_identity="codex 1",
        )
        different_judge_effort = cache_key(
            self.module.EvalConfig(
                trials=1,
                jobs=2,
                timeout=180,
                model="gpt-5.6-luna",
                reasoning_effort="xhigh",
                judge_model="gpt-5.6-sol",
                judge_reasoning_effort="high",
            ),
            codex_identity="codex 1",
        )
        self.assertNotEqual(configured, different_judge_model)
        self.assertNotEqual(configured, different_judge_effort)

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

    def test_run_case_retries_an_empty_codex_response(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "demo")
        case = self.module.EvalCase(
            id="negative",
            prompt="Reply with a number.",
            should_trigger=False,
            assertions=("The answer is a number.",),
        )
        spec = self.module.RunSpec(case=case, trial=1, variant="candidate")
        valid_trace = json.dumps(
            {
                "type": "item.completed",
                "item": {"type": "agent_message", "text": "2"},
            }
        )

        acknowledgment_only = json.dumps(
            {
                "type": "item.completed",
                "item": {
                    "type": "agent_message",
                    "text": "🤖 I read ~/.agents/AGENTS.md.",
                },
            }
        )
        with mock.patch.object(
            self.module,
            "invoke_codex",
            side_effect=[acknowledgment_only, valid_trace],
        ) as invoke:
            result = self.module.run_case(skill, spec, timeout=10)

        self.assertEqual(result.output, "2")
        self.assertEqual(invoke.call_count, 2)

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

    def test_case_majority_is_per_case_and_not_global_n_of_trials(self) -> None:
        cases = [
            self.module.EvalCase(
                id=f"case-{index}",
                prompt="Reply.",
                should_trigger=False,
                assertions=("The answer is useful.",),
            )
            for index in range(8)
        ]
        trial_passes = {
            (case.id, trial): not (case.id == "case-7" and trial != 1)
            for case in cases
            for trial in range(1, 4)
        }

        self.assertFalse(
            self.module.aggregate_case_assertions(
                cases, trial_passes, trials=3, strict_all_trials=False
            )
        )
        self.assertTrue(
            self.module.case_assertions_pass([True, True, False], strict_all_trials=False)
        )
        self.assertFalse(
            self.module.case_assertions_pass([True, True, False], strict_all_trials=True)
        )

    def test_positive_case_triggers_tolerate_a_minority_miss(self) -> None:
        case = self.module.EvalCase(
            id="positive",
            prompt="Reply.",
            should_trigger=True,
            assertions=("The answer is useful.",),
        )
        majority = {(case.id, 1): True, (case.id, 2): True, (case.id, 3): False}
        minority = {(case.id, 1): True, (case.id, 2): False, (case.id, 3): False}

        self.assertTrue(
            self.module.aggregate_case_triggers(
                [case], majority, trials=3, strict_all_trials=False
            )
        )
        self.assertFalse(
            self.module.aggregate_case_triggers(
                [case], minority, trials=3, strict_all_trials=False
            )
        )

    def test_negative_control_triggers_stay_strict_under_majority_policy(self) -> None:
        control = self.module.EvalCase(
            id="negative",
            prompt="Reply.",
            should_trigger=False,
            assertions=("The answer is useful.",),
        )
        fired_once = {(control.id, 1): False, (control.id, 2): True, (control.id, 3): True}

        self.assertFalse(
            self.module.aggregate_case_triggers(
                [control], fired_once, trials=3, strict_all_trials=False
            )
        )
        self.assertTrue(
            self.module.aggregate_case_triggers(
                [control],
                {(control.id, trial): True for trial in range(1, 4)},
                trials=3,
                strict_all_trials=False,
            )
        )

    def test_strict_all_trials_restores_all_trials_trigger_behaviour(self) -> None:
        case = self.module.EvalCase(
            id="positive",
            prompt="Reply.",
            should_trigger=True,
            assertions=("The answer is useful.",),
        )
        majority = {(case.id, 1): True, (case.id, 2): True, (case.id, 3): False}

        self.assertFalse(
            self.module.aggregate_case_triggers(
                [case], majority, trials=3, strict_all_trials=True
            )
        )
        self.assertTrue(
            self.module.case_triggers_pass(
                [True, True, False], should_trigger=True, strict_all_trials=False
            )
        )
        self.assertFalse(
            self.module.case_triggers_pass(
                [True, True, False], should_trigger=False, strict_all_trials=False
            )
        )

    def test_comparison_requires_no_regression(self) -> None:
        self.assertTrue(self.module.comparison_passes(1, 1))
        self.assertTrue(self.module.comparison_passes(2, 0))
        self.assertTrue(self.module.comparison_passes(0, 0))
        self.assertFalse(self.module.comparison_passes(1, 2))

    def test_failure_evidence_preserves_normalized_blind_answers_and_judge(self) -> None:
        target = self.module.EvalTarget(
            name="demo",
            kind="skill",
            path=Path("/tmp/demo"),
            eval_path=Path("/tmp/demo/evals/evals.json"),
        )
        case = self.module.EvalCase(
            id="positive",
            prompt="Reply.",
            should_trigger=True,
            assertions=("The answer is useful.",),
        )
        results = [
            self.module.RunResult(
                case_id=case.id,
                trial=1,
                variant="candidate",
                output="candidate answer\n🤖 I read the skill.",
                target_read=True,
            ),
            self.module.RunResult(
                case_id=case.id,
                trial=1,
                variant="baseline",
                output="baseline answer\n🤖 I read the skill.",
                target_read=False,
            ),
        ]
        mapping = {(case.id, 1): {"A": "baseline", "B": "candidate"}}
        judged = [
            {
                "id": case.id,
                "trial": 1,
                "A_assertions_pass": False,
                "B_assertions_pass": False,
                "only_assertions_pass": None,
                "preferred": "tie",
                "reason": "contradictory fixture",
            }
        ]

        evidence = self.module.build_failure_evidence(
            target,
            results,
            mapping,
            judged,
            '{"cases": []}',
            {(case.id, 1)},
            policy="per-case majority",
            trigger_passes={(case.id, 1): True},
            trigger_ok=True,
        )

        self.assertEqual(evidence["cases"][0]["blind_mapping"], mapping[(case.id, 1)])
        self.assertEqual(
            evidence["cases"][0]["answers"],
            {
                "candidate": "candidate answer",
                "baseline": "baseline answer",
                "A": "baseline answer",
                "B": "candidate answer",
            },
        )
        self.assertEqual(evidence["cases"][0]["judge"], judged[0])
        self.assertEqual(evidence["judge_output"], '{"cases": []}')
        self.assertTrue(evidence["cases"][0]["trigger_passed"])
        self.assertTrue(evidence["cases"][0]["target_read"])
        self.assertNotIn("trigger_outcomes", evidence)

    def test_failure_evidence_names_trigger_only_failure_and_lists_all_cases(
        self,
    ) -> None:
        target = self.module.EvalTarget(
            name="demo",
            kind="guidance",
            path=Path("/tmp/demo"),
            eval_path=Path("/tmp/demo/evals/evals.json"),
        )
        passing = self.module.EvalCase(
            id="passing",
            prompt="Reply.",
            should_trigger=True,
            assertions=("The answer is useful.",),
        )
        failing = self.module.EvalCase(
            id="failing",
            prompt="Reply.",
            should_trigger=True,
            assertions=("The answer is useful.",),
        )
        results = [
            self.module.RunResult(
                case_id=passing.id,
                trial=1,
                variant="candidate",
                output="answer\n🤖 I read the skill.",
                target_read=True,
            ),
            self.module.RunResult(
                case_id=failing.id,
                trial=1,
                variant="candidate",
                output="answer without the receipt",
                target_read=False,
            ),
        ]
        judged = [
            {
                "id": passing.id,
                "trial": 1,
                "only_assertions_pass": True,
                "reason": "fine",
            },
            {
                "id": failing.id,
                "trial": 1,
                "only_assertions_pass": True,
                "reason": "fine",
            },
        ]
        trigger_passes = {(passing.id, 1): True, (failing.id, 1): False}

        evidence = self.module.build_failure_evidence(
            target,
            results,
            {},
            judged,
            '{"cases": []}',
            {(failing.id, 1)},
            policy="per-case majority",
            trigger_passes=trigger_passes,
            trigger_ok=False,
        )

        self.assertEqual(
            [(case["case_id"], case["trial"]) for case in evidence["cases"]],
            [(failing.id, 1)],
        )
        self.assertFalse(evidence["cases"][0]["trigger_passed"])
        self.assertFalse(evidence["cases"][0]["target_read"])
        self.assertEqual(
            evidence["trigger_outcomes"],
            [
                {
                    "case_id": failing.id,
                    "trial": 1,
                    "trigger_passed": False,
                    "target_read": False,
                },
                {
                    "case_id": passing.id,
                    "trial": 1,
                    "trigger_passed": True,
                    "target_read": True,
                },
            ],
        )

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
        previous = os.environ.get("AGENT_GUIDANCE_EVAL_CODEX")
        os.environ["AGENT_GUIDANCE_EVAL_CODEX"] = str(fake_codex)
        self.addCleanup(
            lambda: (
                os.environ.pop("AGENT_GUIDANCE_EVAL_CODEX", None)
                if previous is None
                else os.environ.__setitem__("AGENT_GUIDANCE_EVAL_CODEX", previous)
            )
        )
        cache = self.module.ResultCache(repo / ".git/eval-cache")
        config = self.module.EvalConfig(trials=1, jobs=2, timeout=10)

        passed = self.module.evaluate_skill(skill, config, cache)
        cached = self.module.evaluate_skill(skill, config, cache)

        self.assertTrue(passed)
        self.assertTrue(cached)

    def test_evaluate_target_uses_case_majority_and_strict_override(self) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "majority")
        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )

        def fake_run_target_case(target, spec, timeout, **kwargs):
            return self.module.RunResult(
                case_id=spec.case.id,
                trial=spec.trial,
                variant=spec.variant,
                output=f"{spec.variant}-{spec.case.id}-{spec.trial}",
                target_read=spec.case.should_trigger,
            )

        def fake_judge_results(cases, results, timeout, **kwargs):
            mappings = {}
            entries = []
            for case in cases:
                for trial in range(1, 4):
                    if case.should_trigger:
                        mappings[(case.id, trial)] = {
                            "A": "candidate",
                            "B": "baseline",
                        }
                        entries.append(
                            {
                                "id": case.id,
                                "trial": trial,
                                "A_assertions_pass": case.id != "positive"
                                or trial != 3,
                                "B_assertions_pass": False,
                                "only_assertions_pass": None,
                                "preferred": "A",
                                "reason": "fixture",
                            }
                        )
                    else:
                        mappings[(case.id, trial)] = {"only": "candidate"}
                        entries.append(
                            {
                                "id": case.id,
                                "trial": trial,
                                "A_assertions_pass": None,
                                "B_assertions_pass": None,
                                "only_assertions_pass": True,
                                "preferred": "only",
                                "reason": "fixture",
                            }
                        )
            return entries, mappings, '{"cases": []}'

        with (
            mock.patch.object(self.module, "codex_identity", return_value="codex"),
            mock.patch.object(
                self.module, "run_target_case", side_effect=fake_run_target_case
            ),
            mock.patch.object(
                self.module, "judge_results", side_effect=fake_judge_results
            ),
        ):
            majority_cache = self.module.ResultCache(repo / "majority-cache")
            majority = self.module.evaluate_target(
                target,
                self.module.EvalConfig(trials=3, jobs=2, timeout=10),
                majority_cache,
            )
            strict_cache = self.module.ResultCache(repo / "strict-cache")
            strict = self.module.evaluate_target(
                target,
                self.module.EvalConfig(
                    trials=3, jobs=2, timeout=10, strict_all_trials=True
                ),
                strict_cache,
            )

        self.assertTrue(majority)
        self.assertTrue(list((repo / "majority-cache").glob("*.evidence.json")))
        self.assertFalse(strict)

    def test_evaluate_target_preserves_evidence_for_duplicate_coverage_failure(
        self,
    ) -> None:
        tempdir, repo = self.make_repo()
        self.addCleanup(tempdir.cleanup)
        skill = write_skill(repo, "coverage")
        target = self.module.EvalTarget(
            name=skill.name,
            kind="skill",
            path=skill,
            eval_path=skill / "evals/evals.json",
        )
        judge_output = '{"cases": ["duplicate"]}'

        def fake_run_target_case(target, spec, timeout, **kwargs):
            return self.module.RunResult(
                case_id=spec.case.id,
                trial=spec.trial,
                variant=spec.variant,
                output=f"{spec.variant}-{spec.case.id}",
                target_read=spec.case.should_trigger,
            )

        def fake_judge_results(cases, results, timeout, **kwargs):
            mappings = {}
            entries = []
            for case in cases:
                if case.should_trigger:
                    mappings[(case.id, 1)] = {"A": "candidate", "B": "baseline"}
                    entries.append(
                        {
                            "id": case.id,
                            "trial": 1,
                            "A_assertions_pass": True,
                            "B_assertions_pass": False,
                            "only_assertions_pass": None,
                            "preferred": "A",
                            "reason": "fixture",
                        }
                    )
                else:
                    mappings[(case.id, 1)] = {"only": "candidate"}
                    entries.append(
                        {
                            "id": case.id,
                            "trial": 1,
                            "A_assertions_pass": None,
                            "B_assertions_pass": None,
                            "only_assertions_pass": True,
                            "preferred": "only",
                            "reason": "fixture",
                        }
                    )
            entries.append(dict(entries[0]))
            return entries, mappings, judge_output

        with (
            mock.patch.object(self.module, "codex_identity", return_value="codex"),
            mock.patch.object(
                self.module, "run_target_case", side_effect=fake_run_target_case
            ),
            mock.patch.object(
                self.module, "judge_results", side_effect=fake_judge_results
            ),
        ):
            cache = self.module.ResultCache(repo / "coverage-cache")
            passed = self.module.evaluate_target(
                target,
                self.module.EvalConfig(trials=1, jobs=2, timeout=10),
                cache,
            )

        evidence_files = list((repo / "coverage-cache").glob("*.evidence.json"))
        self.assertFalse(passed)
        self.assertEqual(len(evidence_files), 1)
        evidence = json.loads(evidence_files[0].read_text(encoding="utf-8"))
        self.assertFalse(evidence["cases"])
        self.assertEqual(evidence["judge_output"], judge_output)


if __name__ == "__main__":
    unittest.main()
