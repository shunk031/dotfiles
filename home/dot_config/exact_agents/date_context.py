import json
import sys
from datetime import datetime

sys.stdin.buffer.read()
context = (
    "Current local date/time at prompt submission: "
    f"{datetime.now().astimezone().isoformat(timespec='seconds')}. "
    "The shared AGENTS.md requires fresh `date` output in every progress report; "
    "record this first-prompt timestamp as the task start, calculate elapsed time "
    "from it, and never estimate it."
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
