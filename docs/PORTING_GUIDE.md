# Autonomous AI Porting Guide
## How an AI Agent Migrates the 24h Unattended Dual-Terminal Framework to Another Project

If you are an AI assistant tasked with adopting or migrating this 24-Hour Unattended Framework into a target repository, follow this deterministic, step-by-step procedure.

---

## 1. Architectural Overview
This framework provides:
- **Terminal A (Interactive Architect)**: Human + AI discuss features, write atomic English tasks to `tasks.txt`, and verify progress via `progress.log` (<=10 lines, zero context pollution).
- **Terminal B (Background Worker)**: `worker.sh` polls `tasks.txt`, runs `agy` with Flash models, enforces `.skills/universal-build-verify.md`, builds, tests, and auto-commits.
- **Linear Branch Strategy**: Work on `feature/<name>`, rebase onto `main`, fast-forward merge, and delete feature branch.

---

## 2. Porting Algorithm (Step-by-Step for Migration AI)

### Step 2.1: Inspect Target Project Stack
Analyze the target workspace:
1. **Language & Build System**:
   - C / C++: Check `CMakeLists.txt` -> Build command: `cmake -B build -S . -G Ninja && cmake --build build`, Test: `ctest --test-dir build`
   - Python: Check `pyproject.toml` / `requirements.txt` -> Test: `pytest`
   - Rust: Check `Cargo.toml` -> Build: `cargo build`, Test: `cargo test`
   - Node / TS: Check `package.json` -> Build: `npm run build`, Test: `npm test`
   - Go: Check `go.mod` -> Test: `go test ./...`
2. **Existing Rules**: Check for existing `AGENTS.md`, `GEMINI.md`, or `CLAUDE.md`.

### Step 2.2: Copy Core Assets
Ensure the following files are copied into the target project root:
- `worker.sh` (ensure `chmod +x worker.sh`)
- `.skills/universal-build-verify.md` (placed at `.skills/universal-build-verify.md`)
- `tasks.txt` (empty or initialized with schema comment)
- `tasks.done` (empty file)
- `progress.log` (empty file with header)

### Step 2.3: Adapt `.skills/universal-build-verify.md`
In the target project's `.skills/universal-build-verify.md`, adjust `Step 2.2` and `Step 2.3` to match the target project's build and test commands discovered in Step 2.1.

### Step 2.4: Non-Destructive Merge into `AGENTS.md`
If target project has `AGENTS.md` (or `GEMINI.md` / `CLAUDE.md`), **DO NOT overwrite**. Append the standard block:

```markdown
## 24h Unattended Dual-Terminal Workflow

This repository supports the 24-Hour Unattended Dual-Terminal AI Development Framework.

### 1. Dual-Terminal Architecture
- **Terminal A (Interactive Architect)**: Discuss with human in Chinese/English, groom requirements, write atomic English tasks to `tasks.txt`, and inspect `progress.log` for acceptance.
- **Terminal B (Background Worker)**: Runs `./worker.sh`. Stateless process per task, executes build, test, GUI smoke test, and auto-commits.

### 2. Strict Inter-AI English Protocol
- All tasks in `tasks.txt`, summaries in `progress.log`, status in `worker.status`, and git commits MUST be in **strictly English** to conserve tokens and maximize execution precision.

### 3. Atomic Task Format (tasks.txt)
Single-line format:
`TASK-XXX | TARGET: <files> | ACTION: <concrete logic> | VERIFY: <test command> | CONSTRAINTS: <bounds>`

### 4. Safe Git Log Rules for Acceptance AI
- Allowed: `git log -n 1 --stat`, `git show --stat <commit-hash>`, `git log --oneline -n 5`
- Prohibited: Bare `git log`, `git log -p`, full `git diff` (prevents context explosion).

### 5. Git Rebase Branch Integration
```bash
git checkout feature/<batch-name>
git rebase main
git checkout main
git merge --ff-only feature/<batch-name>
git branch -d feature/<batch-name>
```
```

### Step 2.5: Safe `.gitignore` Append
Append the following runtime artifacts to target `.gitignore` if not present:
```gitignore
# 24h Unattended Worker Artifacts
worker.status
.worker.log
PAUSE
.scratch/
```

### Step 2.6: Verification
Run `./worker.sh &` briefly or verify `bash -n worker.sh` syntax check.
Report completion to the user.
