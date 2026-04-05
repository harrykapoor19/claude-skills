#!/bin/bash
# Sync skills from local ~/.claude/commands/ into the plugin, then commit + push
set -e

cd "$(dirname "$0")"

SKILLS_DIR="plugins/hk-skills/skills"
SOURCE="$HOME/.claude/commands"

for skill in deep-research creative-ideation; do
  cp -r "$SOURCE/$skill/." "$SKILLS_DIR/$skill/"
  echo "Synced $skill"
done

git add -A
if git diff --cached --quiet; then
  echo "No changes to push"
else
  git commit -m "Sync skills from local commands"
  git push
  echo "Pushed"
fi
