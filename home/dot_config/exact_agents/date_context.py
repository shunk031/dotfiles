import json
import sys
from datetime import datetime

sys.stdin.buffer.read()
context = (
    "Current local date/time for this UserPromptSubmit event only: "
    f"{datetime.now().astimezone().isoformat(timespec='seconds')}. "
    "Because this hook runs on every UserPromptSubmit, retain the task start from "
    "the initial request separately and never replace it with a continuation prompt timestamp. "
    "The shared AGENTS.md requires fresh `date` output in every progress report; "
    "calculate elapsed time from the original task start and never estimate it."
)
print(
    json.dumps(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": context,
            }
        }
    )
)
