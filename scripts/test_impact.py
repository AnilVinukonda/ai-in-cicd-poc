import os, sys, subprocess, json, re

BASE = sys.argv[1] if len(sys.argv) > 1 else "origin/main"
HEAD = sys.argv[2] if len(sys.argv) > 2 else "HEAD"

# Get changed files
diff_cmd = ["git", "diff", "--name-only", f"{BASE}...{HEAD}"]
changed = subprocess.check_output(diff_cmd, text=True).strip().splitlines()

# Simple heuristic mapping: tests mirror src paths (tests/test_<module>.py)
selected = set()
for path in changed:
    if path.startswith("src/") and path.endswith(".py"):
        module = os.path.basename(path).replace(".py", "")
        candidate = f"tests/test_{module}.py"
        if os.path.exists(candidate):
            selected.add(candidate)
    if path.startswith("tests/") and path.endswith(".py"):
        selected.add(path)

# Print paths for pytest
for t in sorted(selected):
    print(t)
