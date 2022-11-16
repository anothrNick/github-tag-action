#!/usr/bin/env bash

mkdir test-repo
cd test-repo || exit 1

git config --global init.defaultBranch master
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

git init
touch 1.txt && git add . && git commit -m "1.txt"
git tag 1.1.1
touch 2.txt && git add . && git commit -m "2.txt"
touch 3.txt && git add . && git commit -m "3.txt"
touch 4.txt && git add . && git commit -m "4.txt"
touch 5.txt && git add . && git commit -m "5.txt"
touch 6.txt && git add . && git commit -m "6.txt"
