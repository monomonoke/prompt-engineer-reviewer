# prompt-engineer-reviewer

A three-layer audit framework for Claude skills: **Linus Torvalds + Guido van Rossum + Claude meta-review**. Auto-loads every file in a target skill, surfaces functional bugs and interface flaws, then validates each finding against how prompts actually behave.

## Why three layers

Most skill reviewers are pattern-based: scan for known bad patterns, list findings, done. That breaks down for prompt engineering, because a pattern that's a bug in code can be a feature in a prompt — duplicate definition becomes emphasis architecture, role priming becomes register control, step repetition becomes attention re-anchoring.

Three lenses fix that asymmetry:

- **🔧 Torvalds** finds functional bugs the way a kernel maintainer would: unresolvable placeholders, claimed automation without mechanism, stale counts, hardcoded paths, flags that nothing checks.
- **🐍 Rossum** finds interface flaws the way Python's BDFL would: implicit handoffs, OR-logic without decision rules, ambiguous variable scoping, parallel sections that drift.
- **🧠 Claude meta-review** validates each finding against actual LLM behavior. T and R are software engineers — they sometimes misapply code logic to prompt context. Claude issues an `Execute / Adapt / Reject` verdict per finding, with reasoning.

Without the third layer, you over-correct prompts toward code-style cleanliness and degrade the skill.

## What a Reject verdict looks like

A real example from running this skill on a Chinese WeChat writing skill:

> **[T-5] 🟢 Character range "800–1,200" stated four times**
> Problem: Same constraint in four places. Low risk but violates single-source-of-truth.
> Evidence: Header, hard constraints, criterion #8, prohibitions section.
> Fix: Declare once at the top; reference rather than restate.
>
> **Claude Meta-Review → REJECT**
> Prompt engineering reality: Four mentions of the 800–1,200 character range is not a bug — it's emphasis architecture. The constraint is the skill's hardest rule, violated often in practice, and appears in contextually relevant places (header = orientation, when writing, when checking, final guardrail). Each mention reinforces attention at a different phase. Do not consolidate.

That's the framework earning its keep. T did its job (found a real DRY violation). The meta-review caught that the violation is intentional. Without the third layer, you'd consolidate — and the skill would degrade.

## Installation

**Claude Code** (one-liner — clone directly into your skills folder, then `git pull` to update later):

```bash
git clone https://github.com/monomonoke/prompt-engineer-reviewer.git ~/.claude/skills/prompt-engineer-reviewer
```

**Claude.ai** (clone, zip, rename, upload):

```bash
git clone https://github.com/monomonoke/prompt-engineer-reviewer.git
zip -r prompt-engineer-reviewer.skill prompt-engineer-reviewer/
# Then upload prompt-engineer-reviewer.skill via your Claude.ai skills settings
```

**Other environments**: Copy the entire `prompt-engineer-reviewer/` folder into whichever directory your Claude environment scans for skills.

## Usage

The skill activates on phrases like:

- `review [skill name] with Torvalds and Rossum`
- `audit [skill name] prompts`
- `engineering review of my skill`
- `fresh eye check on [skill name]`

Just provide the skill's name. The discovery script auto-locates the target skill (searching `/tmp`, `/home/claude`, and `/mnt/skills` — the standard locations in Anthropic's hosted environments) and loads `SKILL.md` plus all supporting files in `references/`, `scripts/`, `assets/`, `docs/`, and `examples/`.

## Workflow

Six steps run in sequence: discovery (auto-load all files) → Torvalds review → Rossum review → Claude meta-review → prioritized action table → optional fixes. Fix mode is either blanket (`fix all`) or targeted (`fix #1, #3`).

After fixes, the skill auto-suggests a **fresh-eye readthrough** — a separate integration test that simulates an LLM encountering the fixed skill for the first time. Fresh-eye deliberately doesn't consult T or R checklists; it catches what pattern-matching can't predict.

## Examples of issues caught

**Functional bugs (Torvalds-style):**

- Skill claims "six steps" but seven are listed → LLM forms wrong mental model
- Schema defines `scope_in/scope_out` but script reads `scope` → silent data loss
- Spec table promises conditional method (`use A or B`) but script implements neither

**Interface flaws (Rossum-style):**

- Step 2 calls a file `draft.md`, Step 3 calls it `working_copy.md` — same artifact, two names
- Three architectures listed with overlapping "best when" criteria, no tie-breaker rule
- Cross-step instruction lives in a reference file the relevant step never loads

**Caught only by Claude meta-review:**

- Structured repetition wrongly flagged as DRY violation (it's emphasis architecture)
- Role priming preamble wrongly flagged as cargo-cult (it has measurable effect on register)
- Step overlap wrongly flagged as redundancy (it's deliberate attention re-anchoring)

## What this skill does NOT do

- It does not rewrite the entire skill unprompted. It finds issues and recommends fixes.
- It does not evaluate domain logic correctness. Only instructional architecture.
- It does not run the skill against real test cases. Step 6 fresh-eye is a readthrough simulation, not execution. For quantitative test-case-based validation with pass rates and baselines, use the `skill-creator` skill's eval harness — it's complementary, not redundant.

## On the personas

Linus Torvalds and Guido van Rossum are used as reviewing archetypes for two well-known engineering philosophies — kernel-level functional rigor and "one obvious way" interface design. No endorsement or affiliation implied.

## License

Apache License 2.0 © 2026 Susan Zhang
