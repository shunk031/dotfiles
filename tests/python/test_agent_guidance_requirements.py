from __future__ import annotations

import json
import re
import subprocess
import unittest
from collections import Counter, defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
CONTRACT_PATH = REPO_ROOT / "tests/fixtures/agent_guidance_requirements.json"

EXPECTED_THIN_ADAPTERS = {
    "local-bats-manager-adapter": {
        "rule_id": "local-bats-policy",
        "path": "home/dot_config/exact_agents/agents/gh-workflow-manager.md",
        "text": "Do not run local `bats`; rely on GitHub Actions for `bats` validation.",
        "occurrences": 1,
        "rationale": "The shared manager is outside this task's edit scope; retain its narrow workflow wording while root AGENTS.md remains canonical.",
    },
    "persistence-quality-shared-adapter": {
        "rule_id": "persistence-quality",
        "path": "home/dot_config/exact_agents/AGENTS.md",
        "text": "Persist only concise, generalizable prevention.",
        "occurrences": 1,
        "rationale": "The always-on file keeps a concise reminder while manage-agent-guidance owns the detailed persistence quality rules.",
    },
}

SEMANTIC_CLAUSE_KINDS = {"whole-line", "fragment", "example", "directive"}
GRAMMATICAL_CONTINUATION_PREFIXES = (
    "and",
    "but",
    "however",
    "instead",
    "or",
    "so",
    "then",
    "while",
    "yet",
)
SEMANTIC_INDICATOR_WORDS = {
    "accept",
    "add",
    "adjust",
    "align",
    "apply",
    "ask",
    "call",
    "change",
    "check",
    "choose",
    "classify",
    "commit",
    "complete",
    "confirm",
    "create",
    "delegate",
    "determine",
    "do",
    "edit",
    "ensure",
    "exclude",
    "explain",
    "expose",
    "fall",
    "fetch",
    "follow",
    "get",
    "include",
    "install",
    "keep",
    "let",
    "limit",
    "locate",
    "make",
    "manage",
    "merge",
    "move",
    "obtain",
    "pass",
    "persist",
    "prefer",
    "preserve",
    "present",
    "prioritize",
    "propose",
    "read",
    "record",
    "remove",
    "report",
    "require",
    "resolve",
    "review",
    "reuse",
    "reply",
    "run",
    "search",
    "skip",
    "specify",
    "state",
    "stop",
    "take",
    "treat",
    "use",
    "verify",
    "wait",
    "write",
    "before",
    "after",
    "when",
    "if",
    "only",
    "without",
    "rather",
    "instead",
    "not",
    "allow",
    "provide",
    "perform",
    "correct",
    "detect",
    "link",
    "prune",
    "publish",
    "post",
    "put",
    "reject",
    "restore",
    "subscribe",
    "symlink",
    "isolate",
    "continue",
    "start",
    "never",
    "support",
    "supporting",
}
MEANINGLESS_SOURCE_FRAGMENTS = {"for example", "skill", "or rule"}
KNOWN_EXAMPLE_FRAGMENTS = {
    (
        "shared-historical",
        24,
        "For example, when introducing a hook, write “When starting work in a new clone or worktree, install it before editing or committing,” rather than “Check it if it does not run.”",
    ),
    ("shared-historical", 56, "  - topic sentence"),
    ("shared-historical", 57, "    - support sentence"),
    ("shared-historical", 58, "    - support sentence"),
    ("shared-historical", 59, "    - conclusion sentence"),
}


class AgentGuidanceRequirementsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.contract = json.loads(CONTRACT_PATH.read_text(encoding="utf-8"))
        cls.sources = cls.contract["sources"]
        cls.requirements = cls.contract["requirements"]

    def _source_text(self, source: dict[str, object]) -> list[str]:
        result = subprocess.run(
            ["git", "show", f"{source['commit']}:{source['path']}"],
            cwd=REPO_ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
        return result.stdout.splitlines()

    def _guidance_paths(self) -> list[Path]:
        # Skill bodies are no longer here. They live in shunk031/skills and
        # shunk031/skills-private, which own their own gates, so scanning for
        # them would either find nothing or assert against a checkout this
        # repository does not control.
        exact_agents = REPO_ROOT / "home/dot_config/exact_agents"
        return [
            REPO_ROOT / "AGENTS.md",
            exact_agents / "AGENTS.md",
            exact_agents / "README.md",
            *sorted((exact_agents / "agents").glob("*.md")),
        ]

    def _assert_semantic_fragment(self, source_clause: str) -> None:
        normalized = " ".join(source_clause.split()).casefold()
        self.assertNotIn(normalized, MEANINGLESS_SOURCE_FRAGMENTS)
        clause_without_markup = re.sub(r"^(?:[-*>]\s*)+", "", normalized)
        continuation_prefixes = "|".join(GRAMMATICAL_CONTINUATION_PREFIXES)
        self.assertEqual(
            source_clause.count("`") % 2,
            0,
            f"source clause has unmatched Markdown code delimiters: {source_clause!r}",
        )
        self.assertIsNone(
            re.match(rf"(?:{continuation_prefixes})\b", clause_without_markup),
            f"source clause begins with a grammatical continuation: {source_clause!r}",
        )
        words = set(re.findall(r"[A-Za-z]+", normalized))
        has_indicator = bool(words & SEMANTIC_INDICATOR_WORDS)
        has_explicit_identifier = bool(
            re.search(
                r"`[^`]+`|(?:~?/[A-Za-z_.-]+)|\b[A-Z][A-Za-z0-9_.-]*\b",
                source_clause,
            )
        )
        self.assertTrue(
            has_indicator or has_explicit_identifier,
            f"source clause has no normative or identifying content: {source_clause!r}",
        )

    def test_contract_identifies_all_historical_sources(self) -> None:
        self.assertEqual(self.contract["version"], 2)
        source_ids = [source["id"] for source in self.sources]
        self.assertEqual(len(source_ids), len(set(source_ids)))
        self.assertEqual(
            {
                (source["id"], source["path"], source["commit"])
                for source in self.sources
            },
            {
                (
                    "shared-historical",
                    "home/dot_config/exact_agents/AGENTS.md",
                    "e69e348",
                ),
                ("root-historical", "AGENTS.md", "482135a"),
            },
        )
        for source in self.sources:
            self.assertNotIn("line_requirement_counts", source)

    def test_guidance_evaluation_wiring_has_one_truthful_consumer_map(self) -> None:
        # One harness, so one set of keys. The `guidance_`-prefixed duplicates
        # existed while the Python runner and Shuhari ran side by side; with the
        # Python runner gone the prefix distinguishes nothing.
        wiring = self.contract["evaluation_wiring"]
        self.assertEqual(wiring["runner"], "shuhari eval instructions")
        self.assertEqual(
            wiring["guidance_source"], "home/dot_config/exact_agents/AGENTS.md"
        )
        self.assertEqual(
            wiring["guidance_eval"], "home/dot_config/exact_agents/AGENTS.evals.json"
        )
        self.assertEqual(wiring["validate_hook"], "shuhari-validate-instructions")
        self.assertEqual(wiring["eval_hook"], "shuhari-eval-instructions")
        self.assertEqual(wiring["skip_variable"], "SKIP=shuhari-eval-instructions")

        # Both entries named paths in the skill tree, which moved to
        # shunk031/skills. Nothing in this repository is wiring-only now.
        self.assertEqual(wiring["wiring_only_paths"], [])

        for key in ("cache", "guidance_runner", "guidance_validate_hook"):
            self.assertNotIn(key, wiring)

        # The map has to agree with the files, not only with itself. Before this
        # it compared the fixture against literals in the same test, so a hook
        # renamed in `.pre-commit-config.yaml` or a `make` target renamed in the
        # Makefile would leave the contract green while nothing ran.
        # Compare whole lines. `assertIn` on `- id: <hook>` also matches
        # `- id: <hook>-renamed`, which is the rename this is meant to catch.
        prek = (REPO_ROOT / ".pre-commit-config.yaml").read_text(encoding="utf-8")
        hook_ids = {
            line.strip().removeprefix("- id: ")
            for line in prek.splitlines()
            if line.strip().startswith("- id: ")
        }
        self.assertIn(wiring["validate_hook"], hook_ids)
        self.assertIn(wiring["eval_hook"], hook_ids)
        self.assertNotIn("agent-guidance-", prek)

        # An id proves a hook is listed, not that it runs anything. Both
        # entries could be replaced with `true` and the ids would still be
        # there, so check what each one actually invokes.
        entries = [
            line.strip().removeprefix("entry: ")
            for line in prek.splitlines()
            if line.strip().startswith("entry: ")
        ]
        guidance_entries = [e for e in entries if wiring["runner"] in e]
        self.assertEqual(len(guidance_entries), 2, entries)
        for entry in guidance_entries:
            self.assertIn(wiring["guidance_source"], entry)
            self.assertIn(wiring["guidance_eval"], entry)
        self.assertTrue(
            any("--validate-only" in entry for entry in guidance_entries),
            guidance_entries,
        )

        makefile = (REPO_ROOT / "Makefile").read_text(encoding="utf-8")
        self.assertIn(wiring["runner"], makefile)

        for key in ("guidance_source", "guidance_eval"):
            self.assertTrue((REPO_ROOT / wiring[key]).is_file(), wiring[key])

    def test_each_historical_bullet_or_directive_has_semantic_requirements(
        self,
    ) -> None:
        requirements_by_source: dict[str, list[dict[str, object]]] = defaultdict(list)
        for requirement in self.requirements:
            requirements_by_source[requirement["source_id"]].append(requirement)

        identifiers = [item["id"] for item in self.requirements]
        self.assertEqual(len(identifiers), len(set(identifiers)))

        for source in self.sources:
            with self.subTest(source=source["id"]):
                source_lines = self._source_text(source)
                atomic_lines = {
                    number
                    for number, line in enumerate(source_lines, start=1)
                    if line.lstrip().startswith("- ")
                }
                directive_lines = source["directive_lines"]
                self.assertEqual(
                    len(directive_lines), len(set(directive_lines)), source["id"]
                )
                for number in directive_lines:
                    self.assertGreaterEqual(number, 1)
                    self.assertLessEqual(number, len(source_lines))
                atomic_lines.update(directive_lines)
                requirements = requirements_by_source[source["id"]]
                recorded_lines = Counter(item["source_line"] for item in requirements)
                self.assertEqual(set(recorded_lines), atomic_lines)
                self.assertTrue(all(count >= 1 for count in recorded_lines.values()))

                clause_keys = []

                for item in requirements:
                    with self.subTest(requirement=item["id"]):
                        source_line = item["source_line"]
                        source_clause = item.get("source_clause")
                        self.assertIsInstance(source_clause, str)
                        self.assertTrue(source_clause)
                        clause_kind = item.get("source_clause_kind")
                        self.assertIn(clause_kind, SEMANTIC_CLAUSE_KINDS)
                        self.assertIn(source_line, atomic_lines)
                        line = source_lines[source_line - 1]
                        occurrence = item.get("source_occurrence", 1)
                        self.assertIsInstance(occurrence, int)
                        self.assertGreaterEqual(occurrence, 1)
                        self.assertEqual(line.count(source_clause), occurrence)
                        if clause_kind in {"whole-line", "directive"}:
                            self.assertEqual(source_clause, line)
                        elif clause_kind == "example":
                            self.assertIn(
                                (source["id"], source_line, source_clause),
                                KNOWN_EXAMPLE_FRAGMENTS,
                            )
                        else:
                            self._assert_semantic_fragment(source_clause)
                        if recorded_lines[source_line] > 1:
                            self.assertNotEqual(clause_kind, "whole-line")
                        clause_keys.append(
                            (
                                source_line,
                                source_clause,
                                item.get("source_occurrence", 1),
                            )
                        )

                self.assertEqual(len(clause_keys), len(set(clause_keys)))

    def test_repeated_source_fragments_have_explicit_occurrence_anchors(self) -> None:
        support_requirements = [
            item
            for item in self.requirements
            if item["source_id"] == "shared-historical"
            and item["source_clause"] == "    - support sentence"
        ]
        self.assertEqual(
            {item["id"] for item in support_requirements},
            {
                "reporting-bullet-example-support-1",
                "reporting-bullet-example-support-2",
            },
        )
        self.assertEqual(
            {item["source_line"] for item in support_requirements}, {57, 58}
        )
        self.assertTrue(
            all(item.get("source_occurrence") == 1 for item in support_requirements)
        )

    def test_semantic_inventory_preserves_material_subclauses(self) -> None:
        by_line = defaultdict(set)
        for item in self.requirements:
            by_line[(item["source_id"], item["source_line"])].add(item["id"])

        self.assertEqual(
            by_line[("root-historical", 21)],
            {
                "root-development-make-setup",
                "root-development-skip-eval-clause-3",
                "root-development-static-validation-clause-4",
                "root-development-static-validation-clause-5",
            },
        )
        self.assertEqual(
            by_line[("root-historical", 13)],
            {
                "root-skill-pool-topology",
                "root-skill-pool-topology-clause-2",
                "root-skill-pool-topology-clause-3",
                "root-skill-pool-topology-clause-5",
                "root-skill-pool-topology-clause-6",
                "root-skill-pool-topology-clause-7",
                "root-skill-pool-topology-clause-8",
                "root-skill-pool-topology-clause-9",
            },
        )
        self.assertEqual(
            by_line[("root-historical", 36)],
            {
                "root-git-worktree-mechanics-1",
                "root-git-worktree-mechanics-2-clause-2",
                "root-git-worktree-mechanics-2-clause-3",
                "root-git-worktree-mechanics-2-clause-5",
                "root-git-worktree-mechanics-2-clause-7",
                "root-git-worktree-mechanics-2-clause-8",
                "root-git-worktree-mechanics-2-clause-10",
                "root-git-worktree-mechanics-2-clause-11",
                "root-git-worktree-mechanics-2-clause-12",
            },
        )
        self.assertEqual(
            by_line[("shared-historical", 47)],
            {"authority-implementation-1", "authority-implementation-denied-actions"},
        )
        self.assertEqual(
            by_line[("shared-historical", 48)],
            {"authority-pull-request", "authority-pull-request-no-merge"},
        )
        self.assertEqual(
            by_line[("shared-historical", 49)],
            {"authority-runtime-cleanup-1", "authority-runtime-cleanup-ask"},
        )
        self.assertEqual(
            by_line[("shared-historical", 136)],
            {"uncommitted-treatment", "uncommitted-treatment-no-revert"},
        )
        self.assertEqual(
            by_line[("shared-historical", 140)],
            {"uncommitted-recovery", "uncommitted-recovery-before-overwrite"},
        )
        self.assertEqual(
            {
                item["source_clause"]
                for item in self.requirements
                if item["source_id"] == "shared-historical"
                and item["source_line"] == 140
            },
            {
                "- Accidental operations: If you accidentally delete uncommitted changes, report it to the user immediately and attempt recovery from the preceding diff, editor history, shell output, stash, or subagent output.",
                "Do not perform additional overwrites before recovery.",
            },
        )
        self.assertEqual(
            next(
                item["source_clause"]
                for item in self.requirements
                if item["id"] == "root-development-static-validation-clause-5"
            ),
            "use `SKIP=agent-skill-eval` only when an emergency requires bypassing model evaluation, and never to bypass static validation.",
        )

    def test_repeated_destination_fragments_have_explicit_occurrence_counts(
        self,
    ) -> None:
        gwq_requirements = [
            item
            for item in self.requirements
            if item.get("required_text") == "gwq add -b <task-branch>"
        ]
        self.assertTrue(gwq_requirements)
        self.assertEqual(
            {item["destination_occurrences"] for item in gwq_requirements}, {2}
        )

        for item in gwq_requirements:
            # A relocated requirement's destination is a skill repository, which
            # this repository cannot read and does not gate. Its occurrence
            # count still travels with it, and the owning repository asserts it.
            if item["disposition"] == "relocated":
                continue
            destination = (REPO_ROOT / item["destination"]).read_text(encoding="utf-8")
            self.assertEqual(
                destination.count(item["required_text"]),
                item["destination_occurrences"],
            )

    def test_requirements_have_valid_dispositions(self) -> None:
        source_ids = {source["id"] for source in self.sources}
        for item in self.requirements:
            with self.subTest(requirement=item["id"]):
                self.assertIn(item["source_id"], source_ids)
                self.assertIsInstance(item["source_line"], int)
                self.assertIn(item["disposition"], {"mapped", "relocated", "removed"})

                if item["disposition"] == "relocated":
                    # The requirement still holds; it is enforced in the skill
                    # repository that now owns the body. Naming the repository
                    # and the skill keeps the trail without asserting against a
                    # checkout this repository does not control.
                    self.assertIsInstance(item.get("destination_repo"), str)
                    self.assertTrue(item["destination_repo"])
                    self.assertIsInstance(item.get("destination_skill"), str)
                    self.assertTrue(item["destination_skill"])
                    self.assertNotIn("destination", item)

                if item["disposition"] in {"mapped", "relocated"}:
                    # A relocated requirement keeps its rule and its required
                    # text: it still holds, and the skill repository that now
                    # owns the body enforces it there. Only `destination` goes,
                    # because the path it named is not in this repository.
                    self.assertIsInstance(item.get("rule_id"), str)
                    self.assertTrue(item["rule_id"])
                    required_text = item.get("required_text")
                    self.assertIsInstance(required_text, str)
                    self.assertTrue(required_text)
                    destination_occurrences = item.get("destination_occurrences")
                    self.assertIsInstance(destination_occurrences, int)
                    self.assertGreaterEqual(destination_occurrences, 1)
                    self.assertNotIn("rationale", item)

                if item["disposition"] == "mapped":
                    destination = item.get("destination")
                    self.assertIsInstance(destination, str)
                    self.assertTrue(destination)

                if item["disposition"] == "removed":
                    self.assertNotIn("destination", item)
                    self.assertNotIn("destination_repo", item)
                    self.assertNotIn("destination_skill", item)
                    self.assertNotIn("rule_id", item)
                    self.assertNotIn("required_text", item)
                    self.assertNotIn("destination_occurrences", item)
                    self.assertIsInstance(item.get("rationale"), str)
                    self.assertTrue(item["rationale"].strip())

    def test_only_approved_rules_are_removed(self) -> None:
        removed_ids = {
            item["id"] for item in self.requirements if item["disposition"] == "removed"
        }
        self.assertEqual(
            removed_ids,
            {
                # The Python evaluation runner this described is deleted, so
                # there is nothing left for CI to test with a fake `codex`.
                "root-test-fake-evaluation-clause-2",
                # These requirements were previously owned by a writing skill
                # that is being removed, so no active destination remains here.
                "writing-format-1",
                "writing-procedural-guidance-1",
                "writing-procedural-guidance-2-clause-2",
                "reporting-concision",
                "reporting-bullet-structure-1",
                "reporting-bullet-example",
                "reporting-bullet-example-support-1",
                "reporting-bullet-example-support-2",
                "reporting-bullet-example-conclusion",
                "reporting-avoid-flat-lists-1",
                "reporting-avoid-flat-lists-2-clause-2",
                "plan-applicability",
                "plan-required-items-1",
                "plan-required-paths",
                "plan-required-interfaces",
                "plan-required-file-changes",
                "plan-required-tests",
                "plan-required-assumptions",
                "plan-expected-granularity",
                "plan-code-specificity",
                "plan-complex-decisions",
                "plan-per-file-writing",
                "plan-incomplete",
                "plan-unknowns-1",
                "plan-unknowns-2-clause-2",
                "plan-assumptions-1",
                "plan-assumptions-2-clause-2",
                "coding-error-handling",
                "coding-final-deliverables",
                "authority-implementation-denied-actions",
                "root-mise-compatibility-floor",
                "root-mise-existing-version-no-downgrade",
                "root-mise-fresh-install",
                "root-mise-fresh-install-complete",
                "root-mise-fresh-install-floor",
                "root-mise-fresh-machine-version",
                "root-mise-renovate",
                "root-mise-renovate-no-floor-bump",
                "root-mise-workarounds",
                "uncommitted-improvements",
            },
        )

    def test_mise_removals_have_evidence_based_rationales(self) -> None:
        expected_evidence = {
            "root-mise-compatibility-floor": "comments next to `min_version` in `home/dot_mise/config.toml`",
            "root-mise-existing-version-no-downgrade": "`install/common/mise.sh` and its mise Bats tests",
            "root-mise-fresh-machine-version": "comments next to `min_version` in `home/dot_mise/config.toml`",
            "root-mise-renovate": "Renovate configuration and regression tests",
            "root-mise-renovate-no-floor-bump": "Renovate configuration and regression tests",
            "root-mise-fresh-install": "Ubuntu and macOS workflow path triggers",
            "root-mise-fresh-install-complete": "`install/common/mise.sh` and its mise Bats tests",
            "root-mise-fresh-install-floor": "`install/common/mise.sh` and its mise Bats tests",
            "root-mise-workarounds": "negative incident alternatives are semantically redundant",
        }
        removed = {
            item["id"]: item["rationale"]
            for item in self.requirements
            if item["disposition"] == "removed" and item["id"].startswith("root-mise-")
        }
        self.assertEqual(set(removed), set(expected_evidence))
        for requirement_id, evidence in expected_evidence.items():
            with self.subTest(requirement=requirement_id):
                self.assertIn(evidence.casefold(), removed[requirement_id].casefold())

    def test_mapped_requirements_exist_at_their_single_destination(self) -> None:
        for item in self.requirements:
            if item["disposition"] != "mapped":
                continue
            with self.subTest(requirement=item["id"]):
                relative = Path(item["destination"])
                self.assertFalse(relative.is_absolute())
                self.assertNotIn("..", relative.parts)
                destination = REPO_ROOT / relative
                self.assertTrue(destination.is_file(), destination)
                text = destination.read_text(encoding="utf-8")
                self.assertEqual(
                    text.count(item["required_text"]), item["destination_occurrences"]
                )

    def test_owner_text_has_one_path_per_normalized_rule(self) -> None:
        guidance_paths = self._guidance_paths()
        guidance_text = {
            path.relative_to(REPO_ROOT).as_posix(): path.read_text(encoding="utf-8")
            for path in guidance_paths
        }
        mapped_by_rule: dict[str, list[dict[str, object]]] = defaultdict(list)
        for item in self.requirements:
            if item["disposition"] == "mapped":
                mapped_by_rule[item["rule_id"]].append(item)

        for rule_id, items in mapped_by_rule.items():
            with self.subTest(rule=rule_id):
                destinations = {item["destination"] for item in items}
                self.assertEqual(len(destinations), 1)
                owner = next(iter(destinations))
                self.assertIn(owner, guidance_text)
                for item in items:
                    self.assertEqual(
                        guidance_text[owner].count(item["required_text"]),
                        item["destination_occurrences"],
                    )

    def test_exclusive_owner_rules_have_no_owner_phrase_outside_owner(self) -> None:
        guidance_text = {
            path.relative_to(REPO_ROOT).as_posix(): path.read_text(encoding="utf-8")
            for path in self._guidance_paths()
        }
        adapters = {
            (adapter["rule_id"], adapter["path"], adapter["text"]): adapter
            for adapter in self.contract["thin_adapters"]
        }
        # `persistence-quality` and `repository-skill-validation` were owned
        # entirely by skill bodies, which moved to shunk031/skills. Exclusivity
        # is a claim about where text may appear in this repository, and a rule
        # with no text here has nothing to be exclusive about.
        expected_rules = {
            "gwq-worktree-mechanics",
            "skill-pool-wiring",
        }
        self.assertEqual(set(self.contract["exclusive_owner_rule_ids"]), expected_rules)

        for rule_id in expected_rules:
            with self.subTest(rule=rule_id):
                items = [
                    item
                    for item in self.requirements
                    if item.get("rule_id") == rule_id
                    and item["disposition"] == "mapped"
                ]
                owner_paths = {item["destination"] for item in items}
                self.assertEqual(len(owner_paths), 1)
                owner = next(iter(owner_paths))
                for item in items:
                    phrase = item["required_text"]
                    for path, text in guidance_text.items():
                        occurrences = text.count(phrase)
                        if path == owner:
                            self.assertEqual(
                                occurrences, item["destination_occurrences"]
                            )
                        elif occurrences:
                            self.assertIn((rule_id, path, phrase), adapters)

    def test_expected_thin_adapters_are_complete_and_exclusive(self) -> None:
        guidance_paths = {
            path.relative_to(REPO_ROOT).as_posix(): path
            for path in self._guidance_paths()
        }
        adapters = self.contract["thin_adapters"]
        expected_ids = set(EXPECTED_THIN_ADAPTERS)
        self.assertEqual(set(self.contract["expected_adapter_ids"]), expected_ids)
        actual_ids = {adapter.get("id") for adapter in adapters}
        self.assertEqual(actual_ids, expected_ids)
        self.assertEqual(len(adapters), len(actual_ids))

        # A thin adapter may point at a rule this repository no longer owns.
        # That is what makes it thin: the owner is the skill body, which moved
        # to shunk031/skills, and the adapter here is the pointer to it.
        mapped_rules = {
            item["rule_id"]
            for item in self.requirements
            if item["disposition"] in {"mapped", "relocated"}
        }
        unique_adapters = {
            (adapter["rule_id"], adapter["path"], adapter["text"])
            for adapter in adapters
        }
        self.assertEqual(len(unique_adapters), len(adapters))

        for adapter in adapters:
            with self.subTest(adapter=adapter["id"]):
                self.assertEqual(
                    {
                        key: adapter[key]
                        for key in EXPECTED_THIN_ADAPTERS[adapter["id"]]
                    },
                    EXPECTED_THIN_ADAPTERS[adapter["id"]],
                )
                self.assertIn(adapter["rule_id"], mapped_rules)
                self.assertIn(adapter["path"], guidance_paths)
                self.assertIsInstance(adapter["text"], str)
                self.assertTrue(adapter["text"])
                self.assertIsInstance(adapter["rationale"], str)
                self.assertTrue(adapter["rationale"].strip())
                occurrences = adapter.get("occurrences")
                self.assertIsInstance(occurrences, int)
                self.assertGreaterEqual(occurrences, 1)
                for path, text in {
                    relative: file.read_text(encoding="utf-8")
                    for relative, file in guidance_paths.items()
                }.items():
                    expected = occurrences if path == adapter["path"] else 0
                    self.assertEqual(text.count(adapter["text"]), expected)

    def test_owner_and_adapter_text_have_exclusive_exact_occurrences(self) -> None:
        guidance_paths = {
            path.relative_to(REPO_ROOT).as_posix(): path.read_text(encoding="utf-8")
            for path in self._guidance_paths()
        }
        adapters = self.contract["thin_adapters"]
        adapter_texts = {
            (adapter["rule_id"], adapter["path"], adapter["text"])
            for adapter in adapters
        }
        mapped_by_rule: dict[str, list[dict[str, object]]] = defaultdict(list)
        for item in self.requirements:
            if item["disposition"] == "mapped":
                mapped_by_rule[item["rule_id"]].append(item)

        for rule_id, items in mapped_by_rule.items():
            owner = {item["destination"] for item in items}
            self.assertEqual(len(owner), 1)
            owner_path = next(iter(owner))
            for item in items:
                for path, text in guidance_paths.items():
                    occurrences = text.count(item["required_text"])
                    if path == owner_path:
                        self.assertEqual(occurrences, item["destination_occurrences"])
                    elif occurrences:
                        self.assertIn(
                            (rule_id, path, item["required_text"]), adapter_texts
                        )

        for adapter in adapters:
            with self.subTest(adapter=adapter["id"]):
                # As above: an adapter may point at a rule whose owner is now a
                # skill body in shunk031/skills. Its text still has to appear
                # exactly where the adapter says and nowhere else, which the
                # loop below checks either way.
                self.assertIn(
                    adapter["rule_id"],
                    {
                        item["rule_id"]
                        for item in self.requirements
                        if item["disposition"] in {"mapped", "relocated"}
                    },
                )
                for path, text in guidance_paths.items():
                    expected = adapter["occurrences"] if path == adapter["path"] else 0
                    self.assertEqual(text.count(adapter["text"]), expected)

    def test_guidance_reverse_scan_covers_every_guidance_file_here(self) -> None:
        # Four: the root AGENTS.md, the shared AGENTS.md and README.md, and one
        # per-agent adapter. It was twenty while sixteen skill bodies were also
        # in this repository.
        self.assertEqual(len(self._guidance_paths()), 4)

    def test_third_party_research_routes_to_exactly_one_skill(self) -> None:
        # What this repository owns is the routing rule: the guidance names the
        # skill once and delegates. The skill's own body — the order of its
        # stages and the wording of its reporting requirements — moved to
        # shunk031/skills, which gates it there. Asserting on it from here would
        # be asserting against a checkout this repository does not control.
        agents = (REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md").read_text(
            encoding="utf-8"
        )
        self.assertEqual(agents.count("`shunk031-research-before-implementation`"), 1)
        self.assertIn("Use the `shunk031-research-before-implementation` skill", agents)

    def test_work_safety_rejects_hook_bypass_and_targetless_validation(self) -> None:
        agents = (REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md").read_text(
            encoding="utf-8"
        )
        guardrail = "Never bypass repository hooks or validation with `--no-verify` or an equivalent."
        self.assertEqual(agents.count(guardrail), 1)
        self.assertIn(
            "If a hook fails, hangs, or reports no matching targets, stop and report it",
            agents,
        )

    def test_manage_agent_guidance_route_has_one_working_style_owner(self) -> None:
        agents = (REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md").read_text(
            encoding="utf-8"
        )
        route = (
            "Use the `shunk031-manage-agent-guidance` skill when adding, moving, or deleting persistent "
            "instructions, agent wrappers, or skills."
        )
        self.assertEqual(agents.count(route), 1)
        self_improvement = agents.split("## Self-Improvement", 1)[1].split(
            "## Work Safety", 1
        )[0]
        self.assertNotIn("manage-agent-guidance", self_improvement)

    def test_always_on_sections_have_one_owner(self) -> None:
        always_on_paths = [
            REPO_ROOT / "AGENTS.md",
            REPO_ROOT / "home/dot_config/exact_agents/AGENTS.md",
        ]
        section_owners: dict[str, list[Path]] = {}
        for path in always_on_paths:
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.startswith("## "):
                    section_owners.setdefault(line, []).append(path)

        duplicate_always_on = {
            section: paths
            for section, paths in section_owners.items()
            if len(paths) > 1
        }
        self.assertEqual(duplicate_always_on, {})

        # The second half of this test scanned `home/dot_config/exact_agents/
        # skills/*/SKILL.md` for the same duplicated sections. That tree moved to
        # shunk031/skills, so the glob matched nothing and the assertion passed
        # without checking anything. Skill bodies are gated in the repository
        # that owns them; asserting on them from here would assert against a
        # checkout this repository does not control.


if __name__ == "__main__":
    unittest.main()
