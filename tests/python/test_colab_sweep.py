from __future__ import annotations

import argparse
import importlib.machinery
import importlib.util
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "home/dot_local/bin/exact_common/executable_colab-sweep"


def _load_script():
    # Bytecode next to the script would land in the exact_ source directory.
    sys.dont_write_bytecode = True
    loader = importlib.machinery.SourceFileLoader("colab_sweep", str(SCRIPT))
    spec = importlib.util.spec_from_loader("colab_sweep", loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


colab_sweep = _load_script()


class ColabSweepTest(unittest.TestCase):
    def test_parse_duration(self) -> None:
        self.assertEqual(colab_sweep.parse_duration("90m"), 5400)
        self.assertEqual(colab_sweep.parse_duration("2d"), 172800)
        with self.assertRaises(argparse.ArgumentTypeError):
            colab_sweep.parse_duration("1.5h")

    def test_due_orphans_waits_for_grace_and_skips_owned(self) -> None:
        due, seen = colab_sweep.due_orphans(
            ["owned", "old", "new"],
            {"owned"},
            {"old": 0.0, "gone": 0.0},
            now=1800.0,
            grace=1800,
        )

        self.assertEqual(due, ["old"])
        self.assertEqual(seen, {"old": 0.0, "new": 1800.0})

    def test_owned_sessions_include_registered_state_files(self) -> None:
        with TemporaryDirectory() as tmp:
            config = Path(tmp)
            (config / "states").mkdir()
            (config / "sessions.json").write_text('{"a": {"endpoint": "e1"}}')
            (config / "states" / "job.json").write_text('{"b": {"endpoint": "e2"}}')

            owned = {
                endpoint
                for path in colab_sweep.state_files(config)
                for endpoint in colab_sweep.read_sessions(path).values()
            }

        self.assertEqual(owned, {"e1", "e2"})

    def test_corrupt_state_file_raises_instead_of_reading_empty(self) -> None:
        with TemporaryDirectory() as tmp:
            path = Path(tmp) / "sessions.json"
            path.write_text("{not json")

            with self.assertRaises(ValueError):
                colab_sweep.read_sessions(path)


if __name__ == "__main__":
    unittest.main()
