#!/bin/bash

# Config
default_bump=$(DEFAULT_BUMP:-minor)

# get latest tag
tag=$(git describe --tags `git rev-list --tags --max-count=1`)
t_commit=$(git rev-list -n 1 $tagag)

# get current commit hash for tag
commit=$(git rev-parse HEAD)

if [ "$tag_commit" == "$commit" ]; then
    echo "No new commits since previous tag."
    exit 0
fi

# if there are none, start tags at 0.0.0
if [ -z "$tag" ]
then
    log=$(git log --pretty=oneline)
    t=0.0.0
else
    log=$(git log $tag..HEAD --pretty=oneline)
fi

# get commit logs and determine home to bump the version
# supports #major, #minor, #patch (anything else will be 'minor')
case "$log" in
    *#major* ) new=$(semver bump major $tag);;
    *#patch* ) new=$(semver bump patch $tag);;
    * ) new=$(semver bump minor $tag);;
esac

echo $new

dt=$(date '+%Y-%m-%dT%H:%M:%SZ')
remote=$(git config --get remote.origin.url)
repo=$(basename $remote .git)

echo "$dt: **pushing tag $new to repo $REPO_OWNER/$repo"

curl -s -X POST https://api.github.com/repos/$REPO_OWNER/$repo/git/refs \
-H "Authorization: token $GITHUB_TOKEN" \
-d @- << EOF

{
  "ref": "refs/tags/$new",
  "sha": "$commit"
}
EOF
