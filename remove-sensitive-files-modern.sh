#!/bin/bash
# Modern script to completely remove sensitive files from Git history
# Uses git-filter-repo (the recommended replacement for git-filter-branch)
# WARNING: This will rewrite Git history!

echo "WARNING: This will rewrite Git history and force push to origin."
echo "Make sure all collaborators are aware before proceeding."
echo ""
echo "Files to be removed from ALL history:"
echo "  - configurations.yaml"
echo "  - .claude/ folder"
echo "  - CLAUDE.md"
echo "  - SESSION_CONTEXT.md"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

# Check if git-filter-repo is available
if ! command -v git-filter-repo >/dev/null 2>&1 && [ ! -f /tmp/git-filter-repo ]; then
    echo "git-filter-repo not found. Downloading..."
    curl -s -o /tmp/git-filter-repo https://raw.githubusercontent.com/newren/git-filter-repo/main/git-filter-repo
    chmod +x /tmp/git-filter-repo
fi

# Use local copy if system-wide not available
if ! command -v git-filter-repo >/dev/null 2>&1; then
    FILTER_REPO="/tmp/git-filter-repo"
else
    FILTER_REPO="git-filter-repo"
fi

echo "Creating backup branch..."
git branch backup-before-cleanup-modern 2>/dev/null || echo "Backup branch already exists"

echo "Removing sensitive files from all history using git-filter-repo..."
$FILTER_REPO --path configurations.yaml --path .claude --path CLAUDE.md --path SESSION_CONTEXT.md --invert-paths --force

echo ""
echo "History has been rewritten locally using the modern git-filter-repo tool."
echo "The repository is now a fresh clone with sensitive files completely removed."
echo ""
echo "To push these changes to GitHub, run:"
echo "  git remote add origin https://github.com/machjesusmoto/k8s-homelab-migration.git"
echo "  git push origin --force --all"
echo "  git push origin --force --tags"
echo ""
echo "IMPORTANT: After doing this:"
echo "1. All collaborators must delete their local repos and clone fresh"
echo "2. Change your VPN credentials immediately"
echo "3. Consider rotating any other credentials that were in the files"
echo "4. The repository has been converted to a fresh clone - remotes may need to be re-added"