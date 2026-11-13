"""Hand Herdr lifecycle events to the shared title updater."""

import os
from pathlib import Path


updater = Path.home() / ".local" / "bin" / "common" / "herdr-tab-title"
os.execv(updater, [str(updater), "--herdr-event"])
