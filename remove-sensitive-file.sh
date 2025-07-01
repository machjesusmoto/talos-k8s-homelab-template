#!/bin/bash
# Script to completely remove configurations.yaml from Git history
# WARNING: This will rewrite Git history!

echo "WARNING: This will rewrite Git history and force push to origin."
echo "Make sure all collaborators are aware before proceeding."
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo "Creating backup branch..."
git branch backup-before-cleanup

echo "Removing sensitive files from all history..."
git filter-branch --force --index-filter \
  "git rm -r --cached --ignore-unmatch configurations.yaml .claude CLAUDE.md SESSION_CONTEXT.md" \
  --prune-empty --tag-name-filter cat -- --all

echo "Cleaning up..."
rm -rf .git/refs/original/
git reflog expire --expire=now --all
git gc --prune=now --aggressive

echo ""
echo "History has been rewritten locally."
echo "To push these changes to GitHub, run:"
echo "  git push origin --force --all"
echo "  git push origin --force --tags"
echo ""
echo "IMPORTANT: After doing this:"
echo "1. All collaborators must delete their local repos and clone fresh"
echo "2. Change your VPN credentials immediately"
echo "3. Consider rotating any other credentials that were in the file"