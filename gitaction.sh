#!/bin/bash
current_branch=$(git rev-parse --abbrev-ref HEAD)
commit=$(git rev-parse HEAD)
commit=$(git rev-parse --short ${commit})
echo $commit

