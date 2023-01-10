#!/usr/bin/env bash

mkdir test-repo
cd test-repo || exit 1

git config --global init.defaultBranch master
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

git init
touch 1.txt && git add . && git commit -m "1_master.txt"
touch 2.txt && git add . && git commit -m "2_master.txt"
git tag 1.1.1

git checkout -b my-feature-branch
touch 3_feautre.txt && git add . && git commit -m "#minor 3_feature.txt" 
touch 4_feautre.txt && git add . && git commit -m "4_feature.txt" 
touch 5_feautre.txt && git add . && git commit -m "#minor 5_feature.txt" 
echo "LATEST_FEATURE_BRANCH_COMMIT_SHA=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"

git checkout master
touch 6.txt && git add . && git commit -m "#minor 6_master.txt" 
touch 7.txt && git add . && git commit -m "#minor 7_master.txt"
git tag 2.3.4 

git checkout my-feature-branch
git rebase master

git merge my-feature-branch --no-edit --ff-only

git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
