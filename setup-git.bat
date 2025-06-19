@echo off
echo Setting up Git repository...

cd /d "C:\Users\admin\GitHub\k8s-homelab-migration"

echo Initializing git repository...
git init -b main

echo Adding remote origin...
git remote add origin https://github.com/machjesusmoto/k8s-homelab-migration.git

echo Adding all files...
git add .

echo Creating initial commit...
git commit -m "Initial commit - K8s homelab migration project"

echo Pushing to GitHub...
git push -u origin main

echo Done! Repository is now on GitHub at:
echo https://github.com/machjesusmoto/k8s-homelab-migration

pause
