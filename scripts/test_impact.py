import os, sys, subprocess

BASE = sys.argv[1] if len(sys.argv) > 1 else "origin/main"
HEAD = sys.argv[2] if len(sys.argv) > 2 else "HEAD"

def run(cmd):
    return subprocess.check_output(cmd, text=True).strip()

changed = []
try:
    # Preferred: 3-dot diff BASE...HEAD (needs merge-base)
    changed = run(["git", "diff", "--name-only", f"{BASE}...{HEAD}"]).splitlines()
except subprocess.CalledProcessError:
    # Fallback: last-commit diff
    try:
        changed = run(["git", "diff", "--name-only", "HEAD~1..HEAD"]).splitlines()
    except subprocess.CalledProcessError:
        changed = []

selected = set()
for path in changed:
    if path.startswith("src/") and path.endswith(".py"):
        module = os.path.basename(path).replace(".py", "")
        candidate = f"tests/test_{module}.py"
        if os.path.exists(candidate):
            selected.add(candidate)
    if path.startswith("tests/") and path.endswith(".py"):
        selected.add(path)

for t in sorted(selected):
    print(t)
