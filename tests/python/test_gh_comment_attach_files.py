from __future__ import annotations

import importlib.util
import io
import json
import sys
import tempfile
import unittest
from contextlib import redirect_stderr
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT_PATH = (
    REPO_ROOT
    / "home/dot_config/exact_agents/skills/gh-comment-attach-files/scripts/attach_comment_files.py"
)


def load_module():
    spec = importlib.util.spec_from_file_location("attach_comment_files", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Failed to load module from {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


attach_comment_files = load_module()


class ResumeManifestTest(unittest.TestCase):
    def test_load_resume_manifest_uses_latest_source_path_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest_path = Path(tmpdir) / "attachments.jsonl"
            manifest_path.write_text(
                "\n".join(
                    [
                        json.dumps(
                            {
                                "source_path": "/tmp/chart.png",
                                "attachment_url": "https://github.com/user-attachments/assets/old",
                            }
                        ),
                        "",
                        json.dumps(
                            {
                                "source_path": "/tmp/chart.png",
                                "attachment_url": "https://github.com/user-attachments/assets/new",
                            }
                        ),
                    ]
                ),
                encoding="utf-8",
            )

            completed = attach_comment_files.load_resume_manifest(manifest_path)

        self.assertEqual(
            completed,
            {"/tmp/chart.png": "https://github.com/user-attachments/assets/new"},
        )

    def test_append_resume_manifest_writes_backward_compatible_entry(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            manifest_path = Path(tmpdir) / "nested" / "attachments.jsonl"
            staged_file = attach_comment_files.StagedFile(
                source_path=Path("/tmp/source.png"),
                staged_path=Path("/tmp/uploads/source--abcd1234.png"),
                staged_name="source--abcd1234.png",
            )

            attach_comment_files.append_resume_manifest(
                manifest_path,
                "https://github.com/OWNER/REPO/pull/123",
                staged_file,
                "https://github.com/user-attachments/assets/abcd",
            )
            entry = json.loads(manifest_path.read_text(encoding="utf-8"))

        self.assertEqual(entry["source_path"], "/tmp/source.png")
        self.assertEqual(entry["staged_name"], "source--abcd1234.png")
        self.assertEqual(
            entry["attachment_url"], "https://github.com/user-attachments/assets/abcd"
        )
        self.assertEqual(entry["target_url"], "https://github.com/OWNER/REPO/pull/123")


class PendingSelectionTest(unittest.TestCase):
    def test_partition_staged_files_skips_resumed_and_limits_pending_files(
        self,
    ) -> None:
        staged_files = [
            attach_comment_files.StagedFile(
                Path("/tmp/a.png"), Path("/uploads/a.png"), "a.png"
            ),
            attach_comment_files.StagedFile(
                Path("/tmp/b.png"), Path("/uploads/b.png"), "b.png"
            ),
            attach_comment_files.StagedFile(
                Path("/tmp/c.png"), Path("/uploads/c.png"), "c.png"
            ),
            attach_comment_files.StagedFile(
                Path("/tmp/d.png"), Path("/uploads/d.png"), "d.png"
            ),
        ]

        with redirect_stderr(io.StringIO()):
            resumed, pending = attach_comment_files.partition_staged_files(
                staged_files,
                {"/tmp/b.png": "https://github.com/user-attachments/assets/b"},
                max_files_per_run=2,
            )

        self.assertEqual(
            [(item.staged_name, url) for item, url in resumed],
            [("b.png", resumed[0][1])],
        )
        self.assertEqual(resumed[0][1], "https://github.com/user-attachments/assets/b")
        self.assertEqual([item.staged_name for item in pending], ["a.png", "c.png"])

    def test_order_completed_attachments_preserves_input_order_and_omits_deferred_files(
        self,
    ) -> None:
        staged_files = [
            attach_comment_files.StagedFile(
                Path("/tmp/a.png"), Path("/uploads/a.png"), "a.png"
            ),
            attach_comment_files.StagedFile(
                Path("/tmp/b.png"), Path("/uploads/b.png"), "b.png"
            ),
            attach_comment_files.StagedFile(
                Path("/tmp/c.png"), Path("/uploads/c.png"), "c.png"
            ),
        ]
        completed = [
            (staged_files[1], "https://github.com/user-attachments/assets/b"),
            (staged_files[0], "https://github.com/user-attachments/assets/a"),
        ]

        ordered = attach_comment_files.order_completed_attachments(
            staged_files, completed
        )

        self.assertEqual(
            [
                (item.staged_name, url.rsplit("/", maxsplit=1)[-1])
                for item, url in ordered
            ],
            [("a.png", "a"), ("b.png", "b")],
        )


class AttachmentDetectionTest(unittest.TestCase):
    def test_count_attachment_url_hints_and_upload_placeholder_detection(self) -> None:
        text = (
            "![Uploading chart.png]()\n"
            "![chart](https://github.com/user-attachments/assets/123)\n"
            "[report](https://github.com/attachments/report.pdf)"
        )

        self.assertEqual(attach_comment_files.count_attachment_url_hints(text), 2)
        self.assertTrue(attach_comment_files.has_upload_placeholder(text, "chart.png"))
        self.assertFalse(attach_comment_files.has_upload_placeholder(text, "other.png"))


if __name__ == "__main__":
    unittest.main()
