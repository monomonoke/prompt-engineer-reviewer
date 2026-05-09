#!/bin/bash
#
# Copyright 2026 Susan Zhang
# SPDX-License-Identifier: Apache-2.0
#
# load_skill.sh — Discover and load all files of a skill for review.
#
# Usage:  bash scripts/load_skill.sh <skill-name>
# Output: Concatenated contents of SKILL.md + all supporting files,
#         with clear section headers, followed by an inventory summary.
#
# Covers: SKILL.md, references/, scripts/, assets/, docs/, examples/
# Excludes: __pycache__/, evals/, binary files (images, fonts, etc.)

set -e

SKILL_NAME="${1:-}"

if [ -z "$SKILL_NAME" ]; then
  echo "ERROR: skill name required"
  echo "Usage: bash scripts/load_skill.sh <skill-name>"
  exit 1
fi

# 1. Locate the skill — search all likely locations
# Order matters: /tmp first so post-fix working copies take priority over installed originals
# (otherwise Step 6 fresh-eye validation would load the pre-fix version from /mnt/skills)
SKILL_DIR=$(find /tmp /home/claude /mnt/skills -type d -name "$SKILL_NAME" 2>/dev/null \
  | grep -v "__pycache__" | head -1)

if [ -z "$SKILL_DIR" ]; then
  echo "ERROR: Skill '$SKILL_NAME' not found in /tmp, /home/claude, or /mnt/skills"
  echo ""
  echo "Available skills:"
  find /tmp /home/claude /mnt/skills -name "SKILL.md" 2>/dev/null \
    | grep -v "__pycache__" \
    | sed 's|/SKILL.md||' | xargs -I{} basename {} | sort -u
  exit 1
fi

echo "=== SKILL LOCATED: $SKILL_DIR ==="
echo ""

# 2. Load SKILL.md (always required)
if [ -f "$SKILL_DIR/SKILL.md" ]; then
  echo "=== SKILL.md ==="
  cat "$SKILL_DIR/SKILL.md"
  echo ""
fi

# 3. Load all text-based supporting files across all supported subdirs
# Subdirs covered: references, scripts, assets, docs, examples
# Extensions covered: .md, .py, .sh, .txt, .json, .yaml, .yml
# Excluded: __pycache__, evals/, binary files

for subdir in references scripts assets docs examples; do
  if [ -d "$SKILL_DIR/$subdir" ]; then
    find "$SKILL_DIR/$subdir" -type f \
      \( -name "*.md" -o -name "*.py" -o -name "*.sh" \
         -o -name "*.txt" -o -name "*.json" \
         -o -name "*.yaml" -o -name "*.yml" \) \
      2>/dev/null | grep -v "__pycache__" | sort | while read f; do
      REL=$(echo "$f" | sed "s|$SKILL_DIR/||")
      echo "=== $REL ==="
      cat "$f"
      echo ""
    done
  fi
done

# 4. Report inventory
echo "=== INVENTORY ==="
echo "Skill path: $SKILL_DIR"
echo "SKILL.md: $(wc -l < "$SKILL_DIR/SKILL.md" 2>/dev/null || echo 0) lines"

for subdir in references scripts assets docs examples; do
  if [ -d "$SKILL_DIR/$subdir" ]; then
    COUNT=$(find "$SKILL_DIR/$subdir" -type f 2>/dev/null | grep -v "__pycache__" | wc -l)
    echo "$subdir/: $COUNT files"
  fi
done

# Flag any binary or unsupported files the review won't cover
UNSUPPORTED=$(find "$SKILL_DIR" -type f \
  ! -name "*.md" ! -name "*.py" ! -name "*.sh" \
  ! -name "*.txt" ! -name "*.json" ! -name "*.yaml" ! -name "*.yml" \
  2>/dev/null | grep -v "__pycache__" | wc -l)

if [ "$UNSUPPORTED" -gt 0 ]; then
  echo ""
  echo "Note: $UNSUPPORTED binary/unsupported file(s) present (images, fonts, etc.)"
  echo "These are NOT loaded for text review but are part of the skill."
fi
