#!/usr/bin/env bash

mkdir test-repo
cd test-repo || exit 1

git config --global init.defaultBranch master
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

git init
touch 1.txt && git add . && git commit -m "1.txt"
# touch 2.txt && git add . && git commit -m "2.txt"
# git tag SOME_TAG-1.1.1
# touch 3.txt && git add . && git commit -m "#major"