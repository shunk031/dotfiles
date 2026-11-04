"""Regression tests for deterministic modes and source-safe adapters."""

import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[2]
HOME_SOURCE = REPO_ROOT / "home"
CHEZMOI = shutil.which("chezmoi")


class ChezmoiApplySafetyTest(unittest.TestCase):
    def test_home_symlink_templates_do_not_target_the_public_source(self):
        offenders = []
        for template in sorted(HOME_SOURCE.rglob("symlink_*.tmpl")):
            content = template.read_text()
            if ".chezmoi.sourceDir" in content or ".local/share/chezmoi/home/" in content:
                offenders.append(str(template.relative_to(REPO_ROOT)))

        self.assertEqual(offenders, [])

    @unittest.skipUnless(CHEZMOI and os.name == "posix", "requires POSIX chezmoi")
    def test_apply_uses_configured_modes_with_caller_umask_077(self):
        with tempfile.TemporaryDirectory(prefix="chezmoi-mode-test-") as temp:
            root = Path(temp)
            home = root / "home"
            home.mkdir()
            env = {
                key: value
                for key, value in os.environ.items()
                if not key.startswith("HERDR_")
            }
            env.update(CI="true", HOME=str(home))
            config = root / "chezmoi.yaml"
            rendered_config = subprocess.run(
                [
                    CHEZMOI,
                    "--source",
                    str(HOME_SOURCE),
                    "--config",
                    "/dev/null",
                    "--config-format",
                    "toml",
                    "execute-template",
                    "--init",
                    "--promptString",
                    "Email address=test@example.com",
                    "--promptString",
                    "System (client or server)=client",
                    "--file",
                    str(HOME_SOURCE / ".chezmoi.yaml.tmpl"),
                ],
                env=env,
                capture_output=True,
                text=True,
                check=True,
            )
            config.write_text(rendered_config.stdout)

            sources = {
                "public": root / "public-source",
                "private": root / "private-source",
                "executable": root / "executable-source",
            }
            files = {
                "public": (sources["public"] / "dot_public" / "public_file", "public\n"),
                "private": (sources["private"] / "private_dot_private" / "private_secret", "private\n"),
                "executable": (sources["executable"] / "bin" / "executable_tool", "#!/bin/sh\n"),
            }
            for path, content in files.values():
                path.parent.mkdir(parents=True)
                path.write_text(content)

            previous_targets = {
                home / ".public" / "public_file": ("public\n", 0o600),
                home / ".private" / "secret": ("private\n", 0o600),
                home / "bin" / "tool": ("#!/bin/sh\n", 0o700),
            }
            for path, (content, mode) in previous_targets.items():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
                path.chmod(mode)
            for directory in (home / ".public", home / ".private", home / "bin"):
                directory.chmod(0o700)

            for name, source in sources.items():
                result = subprocess.run(
                    [
                        CHEZMOI,
                        "--source",
                        str(source),
                        "--destination",
                        str(home),
                        "--config",
                        str(config),
                        "--config-format",
                        "yaml",
                        "--cache",
                        str(root / f"cache-{name}"),
                        "--persistent-state",
                        str(root / f"state-{name}"),
                        "--refresh-externals=never",
                        "apply",
                        "--force",
                        "--exclude=externals,scripts",
                    ],
                    env=env,
                    capture_output=True,
                    text=True,
                    preexec_fn=lambda: os.umask(0o077),
                )
                self.assertEqual(result.returncode, 0, result.stderr)

            actual_modes = {
                "public file": stat.S_IMODE((home / ".public" / "public_file").stat().st_mode),
                "public directory": stat.S_IMODE((home / ".public").stat().st_mode),
                "private file": stat.S_IMODE((home / ".private" / "secret").stat().st_mode),
                "private directory": stat.S_IMODE((home / ".private").stat().st_mode),
                "executable": stat.S_IMODE((home / "bin" / "tool").stat().st_mode),
            }
            self.assertEqual(
                actual_modes,
                {
                    "public file": 0o644,
                    "public directory": 0o755,
                    "private file": 0o600,
                    "private directory": 0o700,
                    "executable": 0o755,
                },
            )

    @unittest.skipUnless(CHEZMOI and os.name == "posix", "requires POSIX chezmoi")
    def test_runtime_files_migrate_from_all_source_linked_agent_directories(self):
        legacy_directories = (
            ("private_dot_config/claude/agents", ".claude/agents", "dot_claude/agents"),
            ("private_dot_config/claude/commands", ".claude/commands", "dot_claude/commands"),
            ("private_dot_config/claude/rules", ".claude/rules", "dot_claude/rules"),
            ("private_dot_config/exact_agents/agents", ".agents/agents", "exact_dot_agents/agents"),
            ("private_dot_config/codex/agents", ".codex/agents", "private_dot_codex/agents"),
        )
        with tempfile.TemporaryDirectory(prefix="chezmoi-agent-migration-test-") as temp:
            root = Path(temp)
            repo = root / "repo"
            source = repo / "home"
            destination = root / "destination"
            destination.mkdir()

            for source_relative, _, adapter_relative in legacy_directories:
                shutil.copytree(HOME_SOURCE / source_relative, source / source_relative)
                shutil.copytree(HOME_SOURCE / adapter_relative, source / adapter_relative)
            guard = "run_before_00-check-agent-directory-migration.sh.tmpl"
            guard_source = HOME_SOURCE / ".chezmoiscripts" / "common" / guard
            if guard_source.exists():
                guard_target = source / ".chezmoiscripts" / "common" / guard
                guard_target.parent.mkdir(parents=True)
                shutil.copy2(guard_source, guard_target)
            helper = "migrate_agent_directories.sh"
            helper_source = REPO_ROOT / "install" / "common" / helper
            if helper_source.exists():
                helper_target = repo / "install" / "common" / helper
                helper_target.parent.mkdir(parents=True)
                shutil.copy2(helper_source, helper_target)
            (source / ".chezmoiignore").write_text(".config\n")
            (repo / ".gitignore").write_text(
                "home/private_dot_config/claude/agents/ignored-runtime.md\n"
            )
            subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
            subprocess.run(["git", "add", "."], cwd=repo, check=True)

            runtime_files = []
            for index, (source_relative, target_relative, _) in enumerate(legacy_directories):
                legacy = source / source_relative
                name = "ignored-runtime.md" if index == 0 else "runtime-custom.md"
                runtime_file = legacy / name
                runtime_file.write_text(f"runtime-created file {index}\n")
                runtime_file.chmod((0o600, 0o640, 0o644, 0o700, 0o600)[index])
                runtime_files.append((runtime_file, destination / target_relative, index))
                target = destination / target_relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.symlink_to(legacy, target_is_directory=True)

            env = dict(os.environ, HOME=str(destination), CI="true")
            env.pop("HERDR_ENV", None)
            cache = root / "cache"
            state = root / "state.boltdb"

            def apply():
                return subprocess.run(
                    [
                        CHEZMOI,
                        "--source", str(source),
                        "--destination", str(destination),
                        "--config", "/dev/null",
                        "--config-format", "toml",
                        "--cache", str(cache),
                        "--persistent-state", str(state),
                        "--refresh-externals=never",
                        "apply", "--no-tty", "--exclude=externals",
                    ],
                    env=env,
                    capture_output=True,
                    text=True,
                )

            blocked = apply()
            lost_files = [
                str(target.relative_to(destination))
                for source_file, target, index in runtime_files
                if not (target / source_file.name).exists()
                or (target / source_file.name).read_text() != f"runtime-created file {index}\n"
            ]
            self.assertEqual(lost_files, [], f"runtime files disappeared from {lost_files}")
            self.assertNotEqual(blocked.returncode, 0, blocked.stdout)
            blocked_output = blocked.stdout + blocked.stderr
            self.assertIn("Found 5 untracked file(s) across 5 directory(ies)", blocked_output)
            self.assertIn("migrate", blocked_output)
            for source_file, target, _ in runtime_files:
                self.assertIn("runtime-created file", source_file.read_text())
                self.assertTrue(target.is_symlink())

            migrated = subprocess.run(
                [
                    "bash", str(repo / "install" / "common" / helper),
                    "migrate", str(source), str(destination),
                ],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(migrated.returncode, 0, migrated.stderr)
            self.assertIn("Migrated 5 file(s) across 5 directory(ies)", migrated.stdout)
            backup_line = next(
                line for line in migrated.stdout.splitlines() if line.startswith("Backups retained at: ")
            )
            backup_directory = Path(backup_line[len("Backups retained at: ") :])
            for source_file, target, index in runtime_files:
                target_file = target / source_file.name
                self.assertFalse(source_file.exists())
                self.assertEqual(target_file.read_text(), f"runtime-created file {index}\n")
                self.assertEqual(stat.S_IMODE(target_file.stat().st_mode), (0o600, 0o640, 0o644, 0o700, 0o600)[index])
                backup_file = backup_directory / "files" / str(index) / source_file.name
                self.assertEqual(backup_file.read_text(), f"runtime-created file {index}\n")
                self.assertEqual(stat.S_IMODE(backup_file.stat().st_mode), (0o600, 0o640, 0o644, 0o700, 0o600)[index])
                self.assertFalse(target.is_symlink())

            applied = apply()
            self.assertEqual(applied.returncode, 0, applied.stderr)
            for source_file, target, index in runtime_files:
                target_file = target / source_file.name
                self.assertEqual(target_file.read_text(), f"runtime-created file {index}\n")
                self.assertEqual(stat.S_IMODE(target_file.stat().st_mode), (0o600, 0o640, 0o644, 0o700, 0o600)[index])

    @unittest.skipUnless(os.name == "posix", "requires POSIX shell tools")
    def test_migration_retains_writer_updates_before_and_after_comparison(self):
        for race_timing in ("during_staging", "after_comparison"):
            with self.subTest(race_timing=race_timing), tempfile.TemporaryDirectory(
                prefix="chezmoi-agent-race-test-"
            ) as temp:
                root = Path(temp)
                repo = root / "repo"
                source = repo / "home"
                legacy = source / "private_dot_config" / "claude" / "agents"
                legacy.mkdir(parents=True)
                (legacy / "managed.md").write_text("managed\n")
                subprocess.run(["git", "init", "-q"], cwd=repo, check=True)
                subprocess.run(["git", "add", "."], cwd=repo, check=True)

                helper = repo / "install" / "common" / "migrate_agent_directories.sh"
                helper.parent.mkdir(parents=True)
                shutil.copy2(REPO_ROOT / "install" / "common" / helper.name, helper)

                runtime_file = legacy / "runtime.md"
                runtime_file.write_text("before staging\n")
                runtime_file.chmod(0o600)
                destination = root / "destination"
                target_directory = destination / ".claude" / "agents"
                target_directory.parent.mkdir(parents=True)
                target_file = target_directory / runtime_file.name
                if race_timing == "during_staging":
                    target_directory.symlink_to(legacy, target_is_directory=True)
                else:
                    target_directory.mkdir()
                    target_file.write_text("before staging\n")
                    target_file.chmod(0o600)

                real_cp = shutil.which("cp")
                real_cmp = shutil.which("cmp")
                self.assertIsNotNone(real_cp)
                self.assertIsNotNone(real_cmp)
                fake_bin = root / "bin"
                fake_bin.mkdir()
                cp_wrapper = fake_bin / "cp"
                cp_wrapper.write_text(
                    "#!/bin/sh\n"
                    '"$MIGRATION_REAL_CP" "$@"\n'
                    "status=$?\n"
                    '[ "$status" -eq 0 ] || exit "$status"\n'
                    'if [ "$MIGRATION_RACE_TIMING" = "during_staging" ] && [ "${2-}" = "$MIGRATION_RACE_SOURCE" ]; then\n'
                    '    printf \'%s\\n\' "$MIGRATION_UPDATED_CONTENT" > "$2"\n'
                    "fi\n"
                )
                cmp_wrapper = fake_bin / "cmp"
                cmp_wrapper.write_text(
                    "#!/bin/sh\n"
                    '"$MIGRATION_REAL_CMP" "$@"\n'
                    "status=$?\n"
                    'if [ "$status" -eq 0 ] && [ "$MIGRATION_RACE_TIMING" = "after_comparison" ]; then\n'
                    '    case "${3-}" in */files/0/runtime.md) printf \'%s\\n\' "$MIGRATION_UPDATED_CONTENT" > "$3" ;; esac\n'
                    "fi\n"
                    'exit "$status"\n'
                )
                cp_wrapper.chmod(0o755)
                cmp_wrapper.chmod(0o755)
                updated_content = f"updated {race_timing}\n"
                env = dict(
                    os.environ,
                    PATH=f"{fake_bin}{os.pathsep}{os.environ['PATH']}",
                    MIGRATION_REAL_CP=real_cp,
                    MIGRATION_REAL_CMP=real_cmp,
                    MIGRATION_RACE_SOURCE=str(runtime_file.resolve()),
                    MIGRATION_RACE_TIMING=race_timing,
                    MIGRATION_UPDATED_CONTENT=updated_content.rstrip("\n"),
                )
                env.pop("HERDR_ENV", None)

                result = subprocess.run(
                    ["bash", str(helper), "migrate", str(source), str(destination)],
                    env=env,
                    capture_output=True,
                    text=True,
                )

                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertFalse(runtime_file.exists())
                backup_line = next(
                    line
                    for line in (result.stdout + result.stderr).splitlines()
                    if line.startswith("Retained migration backup: ")
                )
                backup_file = Path(backup_line.split(": ", 1)[1])
                self.assertEqual(backup_file.read_text(), updated_content)
                if race_timing == "during_staging":
                    self.assertFalse(target_file.exists())
                else:
                    self.assertEqual(target_file.read_text(), "before staging\n")

                blocked = subprocess.run(
                    ["bash", str(helper), "check", str(source), str(destination)],
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(blocked.returncode, 0, blocked.stdout)
                self.assertIn(str(backup_file), blocked.stdout)
                self.assertIn(str(target_file), blocked.stdout)
                self.assertIn("cp -pP", blocked.stdout)

                guard_template = HOME_SOURCE / ".chezmoiscripts" / "common" / "run_before_00-check-agent-directory-migration.sh.tmpl"
                guard_script = root / "run_before_migration_guard.sh"
                guard_script.write_text(
                    guard_template.read_text().replace("{{ .chezmoi.sourceDir }}", str(source))
                )
                guarded = subprocess.run(
                    ["bash", str(guard_script)],
                    env=dict(env, HOME=str(destination)),
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(guarded.returncode, 0)
                self.assertIn("Unresolved migration backup needs review", guarded.stdout)
                self.assertIn("Copy the backup's latest contents to the target", guarded.stderr)
                self.assertIn("then rerun", guarded.stderr)

                shutil.copy2(backup_file, target_file)
                recovered = subprocess.run(
                    ["bash", str(helper), "migrate", str(source), str(destination)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(recovered.returncode, 0, recovered.stderr)
                self.assertTrue(backup_file.exists())
                self.assertEqual(target_file.read_text(), updated_content)
                allowed = subprocess.run(
                    ["bash", str(helper), "check", str(source), str(destination)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(allowed.returncode, 0, allowed.stdout + allowed.stderr)


if __name__ == "__main__":
    unittest.main()
