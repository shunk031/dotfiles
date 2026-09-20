from __future__ import annotations

import json
import plistlib
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
ITERM2_SOURCE = REPO_ROOT / "home" / "dot_config" / "iterm2"
DYNAMIC_PROFILE_PATH = ITERM2_SOURCE / "hotkey_window.json"
PREFERENCES_PATH = ITERM2_SOURCE / "com.googlecode.iterm2.plist"


def _dynamic_profiles() -> list[dict[str, object]]:
    dynamic_profile_data = json.loads(
        DYNAMIC_PROFILE_PATH.read_text(encoding="utf-8")
    )
    return dynamic_profile_data["Profiles"]


def _regular_profiles() -> list[dict[str, object]]:
    preferences_text = PREFERENCES_PATH.read_text(encoding="utf-8")
    # macOS accepts the raw control character used for the hotkey, but XML
    # parsers reject it. Remove it only while reading the test fixture.
    xml_safe_text = "".join(
        character
        for character in preferences_text
        if character in "\t\n\r" or ord(character) >= 32
    )
    preferences_data = plistlib.loads(xml_safe_text.encode("utf-8"))
    return preferences_data["New Bookmarks"]


class Iterm2ProfileGuidTest(unittest.TestCase):
    def test_dynamic_profiles_do_not_duplicate_regular_profile_guids(self) -> None:
        dynamic_guids = {
            profile["Guid"] for profile in _dynamic_profiles()
        }
        regular_guids = {
            profile["Guid"] for profile in _regular_profiles()
        }

        self.assertEqual(dynamic_guids & regular_guids, set())

    def test_hotkey_profile_keeps_dynamic_settings(self) -> None:
        profiles = _dynamic_profiles()
        hotkey_profile = next(
            profile for profile in profiles if profile["Name"] == "Hotkey Window"
        )

        self.assertTrue(hotkey_profile["Rewritable"])
        self.assertTrue(hotkey_profile["Has Hotkey"])
        self.assertEqual(hotkey_profile["HotKey Characters"], "\u0014")
        self.assertNotIn("Dynamic Profile Filename", hotkey_profile)


if __name__ == "__main__":
    unittest.main()
