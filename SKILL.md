---
name: prompt-engineer-reviewer
description: >
  Systematically review any skill's prompts and instructions using a three-layer analysis: Linus Torvalds (engineering integrity), Guido van Rossum (interface coherence), and Claude itself (prompt engineering validation). Auto-loads all skill files — SKILL.md, references/, scripts/, assets/, docs/, and examples/ — so the user never has to paste anything.

  Trigger whenever the user says: "review [skill name] with Torvalds and Rossum", "run the prompt reviewer on [skill]", "audit [skill] prompts", "review prompts in this skill", "Linus and Guido review", "engineering review of my skill", "fresh eye check on [skill]", "readthrough on [skill]", or any variation asking for a structured critique of a skill's instructions. Also trigger when the user has just finished editing a skill and asks "is this good?" or "any issues?" — if a skill name is mentioned, default to running this review.
license: Apache-2.0
---

# Prompt Engineer Reviewer

A three-layer skill audit framework that systematically finds bugs, design flaws, and prompt-specific failure modes in any skill — by loading all skill files automatically.

---

## Severity Taxonomy (used across all Steps)

All findings — from any reviewer, at any step — use this shared severity scale:

- 🔴 **Critical** — Will cause functional failure, silent wrong output, or unresolvable ambiguity the LLM cannot navigate.
- 🟡 **Medium** — Degrades consistency, reliability, or interpretability across runs. The skill still works but produces variable results.
- 🟢 **Low** — Engineering cleanliness, documentation polish, or style issues. No direct functional impact.

Do not invent alternative severity labels. Do not redefine these in individual Steps.

---

## The Three Reviewers

### 🔧 Linus Torvalds — "Does it actually run, or is it theater?"
Torvalds finds **functional bugs**: things that will cause the skill to silently fail, produce wrong outputs, or behave inconsistently across LLMs. He has zero patience for documentation that describes behavior without specifying it.

His checklist:
- Unresolvable placeholders (`{SKILL_DIR}`, `{DATE}`, etc.) — dead code in prose
- Claimed automation without mechanism ("automatically records" → where is the data structure?)
- Stale counts ("six parameters" when there are now eight)
- Untestable assertions ("no obvious translation awkwardness" — obvious to whom?)
- Hardcoded paths or version strings that will rot
- Duplicate definitions that can fall out of sync
- Control flow expressed as prose, not explicit branching rules
- Scripts referenced but never verified to exist
- Flags set but never checked

### 🐍 Guido van Rossum — "One obvious way. Explicit. Consistent."
Rossum finds **interface design flaws**: ambiguity that forces the LLM to guess, inconsistencies that produce different behavior on different runs, and structural fragmentation that degrades coherence.

His checklist:
- Implicit handoffs between steps ("flag in Step 0, use in Step 2" — where is the bridge?)
- OR-logic without decision rules ("use A or B" — when A? when B?)
- Steps that break the structural pattern established by adjacent steps
- Parallel sections with inconsistent formatting or depth
- Fragmentation without justification (5 output files when 1 would do)
- Ambiguous variable scoping (terms named differently in different sections)
- Instructions that require the LLM to infer a convention instead of stating it

### 🧠 Claude — "Does this actually hold in prompt engineering context?"
Torvalds and Rossum are software engineers. They review prompts like code. Some of their critiques are valid and critical; some miss how LLMs actually work. Claude's meta-review layer does three things:
1. **Validate**: each T/R finding against actual LLM behavior — does the critique hold when the consumer is a language model rather than a compiler?
2. **Classify**: distinguish **functional bugs** (affects compliance → must fix) from **engineering elegance** (nice to have → optional).
3. **Audit coverage**: scan for checklist items T/R may have missed. If T's checklist includes "stale counts" but T raised none, explicitly confirm "No stale counts detected" rather than silently skipping. This prevents gaps from hiding behind silence.

Claude then issues a verdict per finding: **Execute** / **Adapt** / **Reject (with reason)**.

Blind spots to watch for — things that look wrong to coders but work in prompts:
- Role priming (setting persona) — measurable effect on output register
- Structured repetition for emphasis — re-anchors LLM attention at phase boundaries
- Step separation with some overlap — not redundancy, attention chunking

---

## Workflow

> **Global constraint**: The `Interaction Rules` section applies to every Step below. Read it before executing.

### Step 0 — Skill Discovery

**If the user's message already names a skill** (e.g. "review hq-editor", "audit seven-steps-solver"), extract the name and skip asking. **If no skill name is present**, ask: "Which skill should I review? Please provide the name or path."

Then run the discovery script — it handles location finding, file loading across all supported subdirs (`references/`, `scripts/`, `assets/`, `docs/`, `examples/`), and inventory reporting:

```bash
bash scripts/load_skill.sh <skill-name>
```

The script:
- Searches `/tmp`, `/home/claude`, and `/mnt/skills` for the skill directory — in that order, so post-fix working copies in `/tmp` take priority over installed originals in `/mnt/skills` (critical for Step 6 validation)
- Loads `SKILL.md` plus all supporting text files (`.md`, `.py`, `.sh`, `.txt`, `.json`, `.yaml`, `.yml`)
- Excludes `__pycache__/` and `evals/` (build artifacts and test data)
- Flags binary files (images, fonts) that aren't loaded for text review
- Fails loudly with a list of available skills if the name is wrong

After the script completes, report the inventory to the user before beginning review:
> "Loaded `<skill-name>`: SKILL.md (N lines) + M reference files + K scripts + L other files. Beginning review."

---

### Step 1 — Torvalds Review

Read all loaded content with Torvalds' lens. For each issue found:

```
**[T-N] 🔴/🟡/🟢 [Issue title]**
Location: [file + line range if possible]
Problem: [one sentence, concrete]
Evidence: [quote the exact problematic text]
Fix: [specific rewrite or code block — not vague advice]
```

Use the severity labels defined in the **Severity Taxonomy** section above. End with a count: "Torvalds found N issues (X critical, Y medium, Z low)."

---

### Step 2 — Rossum Review

Read all loaded content with Rossum's lens. Same format as Step 1, prefixed `[R-N]`.

End with a count: "Rossum found N issues (X critical, Y medium, Z low)."

---

### Step 3 — Claude Meta-Review

For every finding from Steps 1 and 2, issue a verdict:

```
**[T-N] / [R-N] → [EXECUTE / ADAPT / REJECT]**
Prompt engineering reality: [one sentence explaining why the verdict differs from or confirms T/R's view]
```

**EXECUTE** — The finding is valid and actionable as stated. Fix it.

**ADAPT** — The finding identifies a real problem, but the fix proposed doesn't fit prompt engineering. Provide the corrected fix.
- Example: T says "role priming preamble is cargo-cult." Claude says: "Role priming has measurable effect on output register. The problem isn't the preamble — it's that it uses adjectives ('world-class') instead of behavioral specifications. Rewrite as behavioral constraints, not flattery."

**REJECT** — The finding misapplies code engineering logic to prompt context. Explain why.
- Example: R says "step separation violates DRY — Steps 0 and 1 both require reading the document." Claude says: "Repetition of intent across steps is often deliberate in prompts — it re-anchors the LLM's attention at phase boundaries. This is not redundancy; it's emphasis architecture. Do not merge."

**Coverage audit** (required at end of Step 3): After all verdicts, scan T's and R's checklists one more time. For each checklist item that generated zero findings, explicitly confirm coverage — e.g., "No stale counts detected", "No unresolvable placeholders detected". This forces silence to be intentional, not accidental.

---

### Step 4 — Prioritized Action Table

Output a ranked table of all actionable findings (EXECUTE + ADAPT verdicts; REJECT items not included).

**Format example — replace with real findings from the current review:**

| # | Reviewer | Severity | Issue | Verdict | Fix Effort |
|---|----------|----------|-------|---------|------------|
| 1 | T-N | 🔴 | [placeholder: e.g. unresolved variable] | EXECUTE | Low |
| 2 | R-N | 🟡 | [placeholder: e.g. ambiguous branching] | ADAPT | Medium |

Sort by: Critical first, then by Fix Effort (quick wins before large refactors).

**Fix Effort scale:**
- **Low** = Touches < 5 lines, no structural changes, no new files
- **Medium** = Touches 5–20 lines across one section, OR adds/modifies one file
- **High** = Restructures a full Step, OR introduces multiple new files

End with a concrete recommendation, e.g.:
> "Start with T-1 and T-3 — both are 🔴 Critical and fixable in under 10 lines. Defer R-2 to a future pass."

**Edge case — clean skill**: If the review produces zero EXECUTE or ADAPT findings, skip the table and report: "Clean bill of health: N files reviewed, 0 actionable findings. Coverage audit passed." Do not invent issues to fill the table.

---

### Step 5 — Optional: Execute Fixes

First, copy the skill to a writable location: `/tmp/$SKILL_NAME/` (skills directories are read-only, so edits would fail there).

Then branch on user intent:

**Mode A — "fix all" (blanket confirmation):**
- Apply all EXECUTE + ADAPT findings in sequence
- Show the diff for each fix inline as you go (transparency)
- Do NOT pause between fixes for per-fix confirmation — "fix all" already authorized the batch
- **After each ADAPT fix, read the 2–3 adjacent bullets or sentences for semantic overlap with the new content.** ADAPT fixes reframe existing concepts, so the new text may sit alongside an older phrasing that says the same thing in different words. If overlap exists, trim the duplicate in the same fix. This is the one place batch-mode cannot skip scrutiny — EXECUTE fixes typically replace or insert cleanly, but ADAPT fixes layer new framing onto existing surroundings and introduce redundancy unless actively checked.
- Present a consolidated verification table at the end showing each fix's key marker so the user can spot-check that everything landed

**Mode B — "fix [specific numbers]" (targeted):**
- Apply only the fixes the user named (e.g. "fix #1 and #3")
- Show the diff for each, then confirm "ready for next?" before moving on
- This mode exists for when the user wants surgical control over which fixes land

**Both modes end with:**
- Package the updated skill using the official packager:
  ```bash
  cd /mnt/skills/examples/skill-creator && python -m scripts.package_skill /tmp/$SKILL_NAME /mnt/user-data/outputs
  ```
- Never auto-apply fixes the user did not request (findings marked REJECT, or findings outside the user's specified numbers in Mode B)

**After packaging (Mode A or Mode B), automatically prompt the user:**
> "Fixes applied and packaged. Run a fresh-eye readthrough to catch anything the T-R-Claude pass missed? (recommended, optional)"

If the user confirms, proceed to Step 6. If they decline, end the workflow.

---

### Step 6 — Fresh-Eye Validation (post-fix)

**Purpose**: This is an integration test, not another audit. T-R-Claude is pattern-based (checklist scanning for known bad patterns). Fresh-eye is execution-based: Claude re-reads the fixed skill end-to-end as if encountering it for the first time, simulating an LLM about to execute it, and notes where it would get stuck or confused.

**Trigger**:
- **Auto-suggested** after Step 5 completes (see prompt above)
- **Manually invoked** when the user says "fresh eye check on [skill]" or "readthrough on [skill]"

**Execution rules — critical**:
1. **Reload the fixed skill** via `scripts/load_skill.sh` (not the cached pre-fix version)
2. **Do NOT consult T or R checklists during this pass** — the whole point is to find what pattern-matching missed. If you catch yourself thinking "Rossum would flag this," stop and reread with execution intent instead.
3. **Read linearly, top to bottom**, the way an LLM processes context
4. **Record four kinds of observations** (not findings — observations):
   - 🔴 **Blocker**: A point where you genuinely cannot determine the next action. Hard stop.
   - 🟡 **Confusion**: You can continue but only by guessing. Different guesses would produce different behavior.
   - 🟡 **Integration gap**: Individual steps are clear but the handoff between them requires inferring information that isn't stated.
   - ✅ **Clarity win**: A place that a prior fix made notably smoother. Explicit positive confirmation matters — it validates the earlier work.

**Output format** (short prose, not tables):

```
Fresh-eye pass on <skill-name> (post-fix):

🔴 Blockers: [count]
  - [describe each blocker in one sentence + location]

🟡 Confusion / Integration gaps: [count]
  - [describe each briefly + location]

✅ Clarity wins from fixes:
  - [explicit confirmation of what now reads well]

Verdict: [Clean | Minor issues (optional fix) | Needs rework (loop back to Step 1)]
```

**Verdict scale**:
- **Clean** — Zero blockers, zero confusion. Ship it.
- **Minor issues** — No blockers, ≤ 2 confusion points. Optional fix; skill is usable as-is.
- **Needs rework** — Any blocker, OR ≥ 3 confusion/integration gaps. Recommend opening a new T-R-Claude review cycle on the specific problem areas.

**Important boundaries**:
- Fresh-eye does not produce an action table. It validates, it doesn't re-audit.
- If fresh-eye finds ≥ 3 problems, that's a signal to loop back to Step 1 (new review), not to extend Step 6 into a full review.
- **Fresh-eye is not a substitute for quantitative execution testing.** For test-case-based evaluation with pass rates and baselines, use the `skill-creator` skill's eval harness. Fresh-eye catches readthrough problems; skill-creator catches actual-execution problems. They are complementary.

---

## Complete Worked Example

Reference this when uncertain about format. Shows a full T → R → Claude → action table run on a hypothetical skill.

### Context
User runs: "review example-skill with Torvalds and Rossum"

Step 0 loads: SKILL.md (120 lines), 1 reference file, 0 scripts.

### Step 1 output (Torvalds)

**[T-1] 🔴 Unresolved placeholder in export command**
Location: SKILL.md line 87
Problem: Export command uses `{OUTPUT_DIR}` but no instruction sets its value. LLM will emit the literal string.
Evidence: `python export.py --output {OUTPUT_DIR}`
Fix: Replace with a concrete default: `python export.py --output /tmp/exports/`, and note that users can specify a different path in their request.

**[T-2] 🟡 "Automatically saves to history" claimed without mechanism**
Location: SKILL.md line 42
Problem: Instruction says the skill "automatically saves each query to history" but no file, schema, or write step is defined.
Evidence: "The skill automatically saves each query to history for later reference."
Fix: Either define the mechanism (e.g. `history stored at ~/.skill-history.jsonl as append-only JSONL`) or delete the claim.

Torvalds found 2 issues (1 critical, 1 medium, 0 low).

### Step 2 output (Rossum)

**[R-1] 🟡 Step 2 and Step 3 use different names for the same artifact**
Location: SKILL.md lines 56, 71
Problem: Step 2 calls the intermediate file `draft`; Step 3 calls it `working_copy`. No mapping given.
Evidence: Step 2: "Save to draft.md" / Step 3: "Read working_copy.md"
Fix: Pick one name and use it throughout. Recommend `draft.md` since Step 2 creates it.

Rossum found 1 issue (0 critical, 1 medium, 0 low).

### Step 3 output (Claude Meta-Review)

**[T-1] → EXECUTE**
Prompt engineering reality: Unresolved placeholders in executable commands are real bugs — the LLM will pass `{OUTPUT_DIR}` verbatim to the shell, which either fails or creates a literal directory of that name. Fix as stated.

**[T-2] → EXECUTE**
Prompt engineering reality: Valid. Claimed automation without mechanism is a classic prompt pathology — the LLM may either hallucinate an implementation or silently skip the step. Fix as stated.

**[R-1] → EXECUTE**
Prompt engineering reality: Valid. Naming inconsistency forces the LLM to infer equivalence, and different runs may resolve it differently. Pick one name.

**Coverage audit:**
- Stale counts: not detected
- Untestable assertions: not detected
- Hardcoded version strings: not detected
- Implicit handoffs: covered by R-1
- Parallel sections inconsistent formatting: not detected
- OR-logic without decision rules: not detected

### Step 4 output (Action Table)

| # | Reviewer | Severity | Issue | Verdict | Fix Effort |
|---|----------|----------|-------|---------|------------|
| 1 | T-1 | 🔴 | Unresolved `{OUTPUT_DIR}` placeholder | EXECUTE | Low |
| 2 | T-2 | 🟡 | "Automatic save" claimed without mechanism | EXECUTE | Low |
| 3 | R-1 | 🟡 | Inconsistent artifact naming (`draft` vs `working_copy`) | EXECUTE | Low |

> Start with T-1 — the only 🔴 Critical, fixable in 2 lines. T-2 and R-1 are both 🟡 Medium and independent; fix in either order.

---

## Interaction Rules

- **Never ask the user to paste skill content.** Always load it via `scripts/load_skill.sh`. Pasted content is error-prone (truncation, missing files) and defeats the skill's core design.
- **Always run all three layers** (T → R → Claude). Never skip the Claude meta-review — it's the most important layer for catching T/R overcorrection and missed coverage.
- **Always quote evidence.** Findings without the specific offending text are not actionable — the user can't verify them and the LLM can't fix them precisely.
- **One fix per finding.** Don't list "options" — pick the best fix and state it. Optionality shifts decision burden back to the user and slows iteration.
- **During Step 6 (fresh-eye), do not consult T or R checklists.** The whole point of fresh-eye is to catch what pattern-matching misses. Read with execution intent, not audit intent. If fresh-eye keeps surfacing T/R-style findings, that means it's being done wrong — re-read linearly asking "could I actually execute this?" instead of "does this match a bad-pattern I know?"
- If the skill has no scripts, references, or other subdirs, note it and proceed with SKILL.md only.
- If the skill is not found, the discovery script lists available skills. Ask the user to confirm the correct name.

---

## What This Skill Does NOT Do

- It does not rewrite the entire skill unprompted. It finds issues and recommends fixes.
- It does not evaluate whether the skill's *domain logic* is correct (e.g., whether the McKinsey framework steps are accurate). It only reviews the *instructional architecture*.
- It does not run the skill against real test cases. Step 6 (fresh-eye) is a readthrough simulation, not an execution test — it catches "would I know what to do here?" problems, not "does the output pass objective checks?" problems. For quantitative, test-case-based validation with pass rates and baseline comparisons, use the `skill-creator` skill's eval harness. The two are complementary: fresh-eye is cheap and fast (seconds, no test cases needed); skill-creator evals are rigorous and measurable (minutes, requires real prompts).
